--[[----------------------------------------------------------------------------
AcceptHashes.lua

This file contains the functions to update image files with the new hashes 
returned from VerifyFiles.

Copyright 2013 Stephen Bay


This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
------------------------------------------------------------------------------]]

local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'
local LrBinding = import 'LrBinding'
local LrFunctionContext = import "LrFunctionContext"
local LrView = import "LrView"
local LrPrefs = import "LrPrefs"

local prefs = LrPrefs.prefsForPlugin()
local catalog = LrApplication.activeCatalog()

--
-- Iterate over selected photos and update hash values when lastHash is
-- different from the ArchiveHash.
-- Arguments:
--   progressScope
-- Returns:
--   stats.updated: the number of photos with updated hashes
--   stats.unchanged: the number of photos with no change
--   stats.skipped: the number of photos skipped because there is no 
--                  value for lastHash
--
function AcceptHashes( progressScope )
	local stats = {updated=0, unchanged=0, skipped=0}
	local catPhotos = catalog:getTargetPhotos()

	-- iterate over all photos
	for i, photo in ipairs (catPhotos ) do

		progressScope:setPortionComplete(i-1,#catPhotos)
		progressScope:setCaption(i .. '/' .. #catPhotos .. '          ' .. photo:getFormattedMetadata('fileName'))

		-- write hash to meta data
		catalog:withPrivateWriteAccessDo( function()

			local lastHash = photo:getPropertyForPlugin ( _PLUGIN,'lastHash')	
			local lastDate = photo:getPropertyForPlugin ( _PLUGIN,'lastDate')
			local archiveHash = photo:getPropertyForPlugin ( _PLUGIN,'archiveHash')
			
			-- only update the archive hash if the lastHash exists and is different
			if (lastHash ~= nil) and (lastHash ~= "") then

				if (archiveHash ~= lastHash) then
					photo:setPropertyForPlugin ( _PLUGIN,'archiveHash',lastHash)	
					photo:setPropertyForPlugin ( _PLUGIN,'archiveDate',lastDate)
					photo:setPropertyForPlugin ( _PLUGIN,'status','match')
					stats.updated = stats.updated + 1			
				else
					stats.unchanged = stats.unchanged + 1
				end
			-- there is no last hash			
			else
				stats.skipped = stats.skipped + 1
			end

		end, { timeout = _G.timeout_secs }	)
		
	end
	
	progressScope:done()

	return stats
end


--
-- Present a confirmation dialog box to the user before accepting the new hash 
-- values. 
--
function showAcceptHashesDialog()
	return LrFunctionContext.callWithContext( 'PreferenceExample', function ( context )
		local f = LrView.osFactory()

		local contents = f:column 
			{
				spacing = f:dialog_spacing(),
				f:row {
					f:static_text {
						title = "This command will update files with the last hash computed\n" ..
										"by VerifyFiles if it is different from the archived value.",
						alignment = "left",
						font = "<system/bold>",
					},
				},
				f:row {
					f:static_text {
						title = "Before running this command, you should confirm that changes\n" ..
										"in the files are as expected and not due to file corruption.",
						alignment = "left",
					}
				},
				f:row {
					spacing = f:dialog_spacing(),
					f:static_text {
						title = "Once the hashes have been updated, the original values\n" ..
										"will be lost. Are you sure you want to continue?",
						alignment = "left",	
					},
				},
			}

		local result = LrDialogs.presentModalDialog(
			{
				title = "Validator : Accept Changed Hashes",
				contents = contents,
			}
		)
		return result
	end )
end


--
-- Present a dialog box summarizing the results of running the AcceptHashes 
-- command. It basically displays a table of how many files were altered.
--
function showAcceptResultsDialog( accept_stats )

	return LrFunctionContext.callWithContext( 'showGenerateHashesResultsDialog', function ( context )
		local f = LrView.osFactory()

		local contents = f:column 
			{
				spacing = f:control_spacing(),
				f:group_box {
					title = "Summary",
					fill_horizontal = 1,
					font = "<system>",
					size = "regular",
					spacing = f:label_spacing(),
					
					f:row {
						f:static_text {
							title = "Total files processed: " .. (accept_stats.updated + accept_stats.unchanged + accept_stats.skipped),
							alignment = "left",
						},
					},
					f:row {
						f:static_text {
							title = "    Files updated with new hash values: " .. accept_stats.updated,
							alignment = "left",
						},
					},
					f:row {
						f:static_text {
							title = "    Files with no change in their hash values: " .. accept_stats.unchanged,
							alignment = "left",
						},
					},
					f:row {
						f:static_text {
							title = "    Files skipped (no verification hash): " .. accept_stats.skipped,
							alignment = "left",
						},
					},
				},
			}

		local result = LrDialogs.presentModalDialog(
			{
				title = "Validator : Accept Hash Results",
				contents = contents,
				cancelVerb = "< exclude >"
			}
		)

		return result
	end )
end

--
-- Menu Item: Accept Changed Hashes
--

-- Check to make sure there is a selection in grid view. If there are no images
-- display warning dialog and return control back to user.
local target = catalog:getTargetPhoto()
if target == nil then
	LrDialogs.message("No images selected","Please select the images whose hash values you wish to update.","info")
	return
end

-- show the dialog box for acceptHashes and run AsyncTask for this
local input = showAcceptHashesDialog()
if input == 'ok' then

	local LrFunctionContext = import 'LrFunctionContext'
	local LrProgressScope = import 'LrProgressScope'
	LrTasks.startAsyncTask(function ()
		LrFunctionContext.callWithContext('function', function(context)
	
			local progressScope = LrProgressScope( {
				title = 'Validator : accept changed hashes',
				functionContext = context,
			})
		
			progressScope:setPortionComplete(0.0,1.0)
			progressScope:setCancelable(true)
		
			local stats = AcceptHashes(progressScope)
		
			showAcceptResultsDialog(stats)
		end)
	end)
end

