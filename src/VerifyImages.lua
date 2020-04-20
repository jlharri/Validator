--[[----------------------------------------------------------------------------
VerifyFiles.lua

The file contains functions for verify image files by computing a new hash and
comparing it to the value stored in Archive Hash.

Copyright 2013-2017 Stephen Bay

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

require 'HashFunctions.lua'
require 'Common.lua'

local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrDate = import 'LrDate'
local LrTasks = import 'LrTasks'
local LrColor = import 'LrColor'
local LrBinding = import 'LrBinding'
local LrFunctionContext = import "LrFunctionContext"
local LrView = import "LrView"

local LrFileUtils = import 'LrFileUtils'

local LrPrefs = import "LrPrefs"
local LrSystemInfo = import "LrSystemInfo"

local prefs = LrPrefs.prefsForPlugin()
local catalog = LrApplication.activeCatalog()

--
-- Iterate over all of the selected files and compute new hashes and compare to
-- the value stored in Archive Hash.
-- Arguments:
--   progressScope
-- Returns
--   stats.nohash: files with no archive hash
--   stats.match: files where the hash matches
--   stats.change: files where the hash has changed
--   stats.read_error: files with read errors
--   stats.time: total time taken in seconds
--
function VerifyFiles( progressScope )

	local catPhotos = catalog:getTargetPhotos()

	local stats = {nohash=0, match=0, change=0, read_error = 0, time=0}
	local start_time = LrDate.currentTime()

	-- create collection for storing results if it doesn't exist
	local mismatch_collection
	catalog:withWriteAccessDo("creating mismatch catalog", function()
		local collection_name = prefs.collection_name
		mismatch_collection = catalog:createCollection(collection_name,nil,true)
	end, { timeout = _G.timeout_secs })


	local logfile = nil
	if prefs.log_enabled then
		logfile = assert(io.open(LrFileUtils.chooseUniqueFileName(prefs.log_file),"w"))
	end

	logWrite(logfile,"Validator " .. _G.version .. "\n")
	logWrite(logfile,os.date("%c") .. "\n\n")

	logWrite(logfile,"*** System Information ***\n\n")
	logWrite(logfile,"OS Summary: " .. LrSystemInfo.summaryString() .. "\n")
	logWrite(logfile,"Memory: " .. LrSystemInfo.memSize() .. "\n")
	logWrite(logfile,"Num CPUs: " .. LrSystemInfo.numCPUs() .. "\n")


	logWrite(logfile,"\n")
	logWrite(logfile,"*** Executing Verify Files ***\n\n")

	-- iterate over all photos
	for i, photo in ipairs (catPhotos ) do

		progressScope:setPortionComplete(i-1,#catPhotos)
		progressScope:setCaption(i .. '/' .. #catPhotos .. '          ' .. photo:getFormattedMetadata('fileName'))

		-- read existing hash value
		local archiveHash = photo:getPropertyForPlugin( _PLUGIN,'archiveHash')

		-- skip photos that do not have an archive hash
		if archiveHash ~= nil then

			-- get file information
			local imageDetails = photo:getFormattedMetadata( 'fileName' )
			local filepath = photo:getRawMetadata('path')

			local hashValue = MD5hash( filepath )		
			local hashDate = LrDate.formatMediumDate(LrDate.currentTime())
		
			local status = 'match'

			-- check for error generating hash
			if hashValue ~= nil then

				if archiveHash == hashValue then
					stats.match = stats.match + 1
					logWrite(logfile,"Match: " .. photo:getRawMetadata('path') .. " | " .. hashValue .. "\n")
					status = 'match'
				else
					stats.change = stats.change + 1
					logWrite(logfile,"Change: " .. photo:getRawMetadata('path') .. " | archive: " .. archiveHash .. " last: " .. hashValue .. "\n")
					status = 'change'

					-- add photo to the collection for changed hashes
					catalog:withWriteAccessDo("adding to change collection", function()
						mismatch_collection:addPhotos({photo})
					end, { timeout = _G.timeout_secs })

				end
			
				-- write hash to meta data
				catalog:withPrivateWriteAccessDo( function()
					photo:setPropertyForPlugin ( _PLUGIN,'lastHash',hashValue)	
					photo:setPropertyForPlugin ( _PLUGIN,'lastDate',hashDate)
					photo:setPropertyForPlugin ( _PLUGIN,'status',status)
				
				end, { timeout = _G.timeout_secs }	)
			else
				-- these are files where the MD5hash function returned nil (error)
				stats.read_error = stats.read_error+1
				logWrite(logfile,"Read Error: " .. photo:getRawMetadata('path') .. "\n")

			end
		else
			-- these are photos without a hash so skip
			stats.nohash = stats.nohash+1
			logWrite(logfile,"Skip: " .. photo:getRawMetadata('path') .. "\n")

		end		
	end

	progressScope:done()

	stats.time = LrDate.currentTime() - start_time


	-- Close down log file
	logWrite(logfile,"\n")
	logWrite(logfile,"*** Execution complete ***\n\n")
	logWrite(logfile,"Total time taken: " .. string.format("%.2f",stats.time) .. " seconds")
	if logfile then
		logfile:close()
	end

	return mismatch_collection.localIdentifier, stats
end

--
-- Validate the collection name where files with changed hashes will be added.
--
function validateCollectionName(view, value)
  -- test collection name
	if value == nil or value == "" then
		return false, prefs.collection_name, "The collection name cannot be an empty string."
	end

	return true, value, nil
end

--
-- Display dialog box for the VerifyFiles command and present options.
--
function showVerifyFilesDialog ()
	return LrFunctionContext.callWithContext( 'showVerifyFilesDialog', function ( context )
		local f = LrView.osFactory()
		local properties = LrBinding.makePropertyTable ( context )

		properties.collection_name = prefs.collection_name
		properties.log_file = prefs.log_file
		properties.log_enabled = prefs.log_enabled


		local contents = f:column 
			{
				--spacing = f:control_spacing(),
				spacing = f:dialog_spacing(),
				f:row {
					f:static_text {
						title = "Verify files by computing new hashes and comparing\n" .. "to stored values.",
						alignment = "left",
						font = "<system/bold>",
					},
				},
				f:group_box {
					title = 'Files with changed hashes',
					font = "<system>",
					size = 'regular',
					fill_horizontal = 1,
					spacing = f:dialog_spacing(),

					f:row {
						spacing = f:label_spacing(),
						bind_to_object = properties,
						f:static_text {
							title = "Add to collection:",
							alignment = "left",
						},
						f:edit_field {
							width_in_chars = 15,
							value = LrView.bind('collection_name'),
							alignment = "left",
							validate = validateCollectionName
						},
					},
				},
				f:group_box {
					title = 'Logging',
					font = "<system>",
					size = 'regular',
					fill_horizontal = 1,
					spacing = f:dialog_spacing(),
					f:row {
						spacing = f:label_spacing(),
						bind_to_object = properties,
						f:checkbox {
							title = "Save log file as",
							value = LrView.bind('log_enabled'),
							checked_value = true,
							unchecked_value = false,
						},
					},
					f:row {
						bind_to_object = properties,
						f:edit_field {
							enabled = LrView.bind('log_enabled'),
							width_in_chars = 25,
							value = LrView.bind('log_file'),
							alignment = "left",
						},
						f:push_button {
							enabled = LrView.bind('log_enabled'),
							title = "choose",
							action = function (button)
								local log_file = LrDialogs.runSavePanel({title = 'Save Log File as',prompt = 'Select', requiredFileType = 'txt',canCreateDirectories = true})						
								if log_file then
									properties.log_file = log_file
								end
							end,
						},
					},
				},



			}

		local result = LrDialogs.presentModalDialog(
			{
				title = "Validator : Verify Files",
				contents = contents,
			}
		)

		if result == 'ok' then
			-- save results to preferences
			prefs.collection_name = properties.collection_name
			prefs.collection_name = prefs.collection_name -- why double assign?

			prefs.log_file = properties.log_file
			prefs.log_enabled = properties.log_enabled

		end
		return result
	end )

end


--
-- Display results of verifying hashes on the selected photos.
-- Arguments: 
--   stats: a table with various count statistics to display
-- 
-- Note this function sets the value of the global preference 
-- verify_display_mismatch depending on the number of changed hashes. 
-- 
function showVerifyFilesResultsDialog( stats )

	return LrFunctionContext.callWithContext( 'showVerifyFilesResultsDialog', function ( context )
		local f = LrView.osFactory()
		local properties = LrBinding.makePropertyTable ( context )

		properties.collection_name = prefs.collection_name
		properties.verify_display_mismatch = prefs.verify_display_mismatch

		-- display mismatch collection on dialog close if there are results
		if stats.change > 0 then
			properties.verify_display_mismatch = 'checked'
		else
			properties.verify_display_mismatch = 'unchecked'
		end

		local main_result = nil
		local main_text_color = LrColor(0,0,0)
		local enabled_status = false
		if stats.change > 0 then
			main_result = "Files with changed hashes were found!"
			main_text_color = LrColor(0.9,0,0)
			enabled_status = true
		else
			main_result = "No files with changed hashes were found."
		end

		local results_block = f:column{
				spacing = f:control_spacing(),
				f:spacer {
					height = 10
				},
				f:row {
					spacing = f:control_spacing(),
					f:static_text {
						title = "Files with changed hashes were added to collection: " .. prefs.collection_name,
						alignment = "left",
					},
				},
				f:row {
					spacing = f:control_spacing(),
					bind_to_object = properties,
					enabled = enabled_status,
					f:checkbox {
						title = 'Show images on dialog close.',
						value = LrView.bind('verify_display_mismatch'),
						checked_value = 'checked',
						unchecked_value = 'unchecked',
						enabled = enabled_status,
					},
				},
		}
		if stats.change == 0 then
			results_block = f:column{}
		end

		local contents = f:column 
			{
				spacing = f:control_spacing(),
				f:row {
					f:static_text {
						title = main_result,
						fill_horizontal = 1,
						alignment = "center",
						text_color = main_text_color,
						font = "<system/bold>",
					},
				},
				f:spacer {
					height = 10,
				},			
				f:group_box {
					title = "Summary",
					fill_horizontal = 1,
					font = "<system>",
					size = "regular",
					spacing = f:label_spacing(),
					
					f:row {
						f:static_text {
							title = "Total files examined: " .. (stats.nohash + stats.change + stats.match + stats.read_error),
							alignment = "left",
						},
					},
					f:row {
						f:static_text {
							title = "    Files with changed hashes: " .. stats.change,
							alignment = "left",
						},
					},
					f:row {
						f:static_text {
							title = "    Files with matching hashes: " .. stats.match,
							alignment = "left",
						},
					},
					f:row {
						f:static_text {
							title = "    Files without hashes (skipped): " .. stats.nohash,
							alignment = "left",
						},
					},
					f:row {
						f:static_text {
							title = "    Files that could not be read: " .. stats.read_error,
							alignment = "left",
						},
					},
					f:row {
						f:static_text {
							title = "Total time taken: " .. string.format("%.2f",stats.time) .. "s",
							alignment = "left",
						}
					}
				},
				results_block,
			}

		local result = LrDialogs.presentModalDialog(
			{
				title = "Validator : Verify Results",
				contents = contents,
				cancelVerb = "< exclude >"
			}
		)

		if result == 'ok' then
			-- save results to preferences
			prefs.verify_display_mismatch = properties.verify_display_mismatch

		end
		return result
	end )
end






--
-- Menu Item: Verify Files
--

local input = showVerifyFilesDialog()
local collection_identifer

if input == 'ok' then
	local LrFunctionContext = import 'LrFunctionContext'
	local LrProgressScope = import 'LrProgressScope'
	LrTasks.startAsyncTask(function ()
		LrFunctionContext.callWithContext('function', function(context)
	
			local progressScope = LrProgressScope( {
				title = 'Validator : verifying files',
				functionContext = context,
			})
		
			progressScope:setPortionComplete(0.0,1.0)
			progressScope:setCancelable(true)
			
			collection_identifier, stats = VerifyFiles(progressScope)
	
			showVerifyFilesResultsDialog(stats)
	
			-- Bring up the collection with changed hashes in Grid
			if prefs.verify_display_mismatch == 'checked' then
				local x = catalog:getCollectionByLocalIdentifier(collection_identifier)
				local result = catalog:setActiveSources(x)
			end
		end)
	end)
end






