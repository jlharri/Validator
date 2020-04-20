--[[----------------------------------------------------------------------------
GenerateHashes.lua

This file contains functions for iterating through the photo selection and
generating hashes.

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
require 'AutoUpdate.lua'

local LrApplication = import 'LrApplication'
local LrBinding = import 'LrBinding'

local LrDialogs = import 'LrDialogs'
local LrDate = import 'LrDate'
local LrTasks = import 'LrTasks'
local LrFunctionContext = import "LrFunctionContext"
local LrView = import "LrView"

local LrFileUtils = import 'LrFileUtils'

local catalog = LrApplication.activeCatalog()
local LrPrefs = import "LrPrefs"
local LrSystemInfo = import "LrSystemInfo"


local prefs = LrPrefs.prefsForPlugin()

--
-- Compare the file type of the photo against the options in the dialog box.
--
function photoIsValidType(photo)

	if photo:getRawMetadata('isVirtualCopy') and prefs.ignore_virtual_copies == 'checked' then
		return false
	end

	local filetype = photo:getRawMetadata('fileFormat')
	--LrDialogs.message("file format: " .. filetype)

	if filetype == "RAW" and prefs.raw_checkbox == 'checked' then
		return true
	elseif filetype == "DNG" and prefs.dng_checkbox == 'checked' then
		return true
	elseif filetype == "TIFF" and prefs.tif_checkbox == 'checked' then
		return true
	elseif filetype == "JPG" and prefs.jpeg_checkbox == 'checked' then
		return true
	elseif filetype == "PSD" and prefs.psd_checkbox == 'checked' then
		return true
	elseif filetype == "PNG" and prefs.png_checkbox == 'checked' then
		return true
	elseif filetype == "VIDEO" and prefs.video_checkbox == 'checked' then
		return true
	end

	return false

end

--
-- Generate hashes for selected photos and store in the metadata fields for
-- ArchiveHash and ArchiveDate.
-- Arguments:
--   progressScope
-- Returns:
--   stats.existinghash: number of files with existing hashes (new hash not generated)
--   stats.newhash: number of files for which a new hash was created
--   stats.skipped: number of files skipped
--   stats.read_error: files that cannot be read
--   stats.time: total time taken in seconds
--
function GenerateHashes( progressScope )

	local stats = {existinghash=0, newhash=0, skipped=0, read_error=0, time=0}
	local start_time = LrDate.currentTime()

	local catPhotos = catalog:getTargetPhotos()

	-- Setup logfile				
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
	logWrite(logfile,"*** Executing Generate Hashes ***\n\n")

	-- iterate over all photos
	for i, photo in ipairs (catPhotos ) do
	
		progressScope:setPortionComplete(i-1,#catPhotos)
		progressScope:setCaption(i .. '/' .. #catPhotos .. '          ' .. photo:getFormattedMetadata('fileName'))
	
		-- check if valid filetype according to preferences
		local valid_type = photoIsValidType(photo)
		if valid_type == false then
			stats.skipped = stats.skipped + 1
			logWrite(logfile,"Skipped: " .. photo:getRawMetadata('path') .. "\n")

		end

		-- if the hash already exists skip it
		local hash = photo:getPropertyForPlugin( _PLUGIN, 'archiveHash')
		if hash ~= nil and valid_type then
			stats.existinghash = stats.existinghash + 1
			logWrite(logfile,"Existing Hash: " .. photo:getRawMetadata('path') .. "\n")
	
		end
		
		-- Only generate hashes for images that do not have a hash value
		-- and are of a type selected in dialog box
		if (hash == nil) and valid_type then

			-- get file information
			local imageDetails = photo:getFormattedMetadata( 'fileName' )
			local filepath = photo:getRawMetadata('path')

			-- compute hashes
			local hashValue = MD5hash(filepath)	
			local hashDate = LrDate.formatMediumDate(LrDate.currentTime())

			if hashValue ~= nil then
				-- write hash to meta data
				catalog:withPrivateWriteAccessDo( function()		
					photo:setPropertyForPlugin ( _PLUGIN,'archiveHash',hashValue)	
					photo:setPropertyForPlugin ( _PLUGIN,'archiveDate',hashDate)
					photo:setPropertyForPlugin ( _PLUGIN,'status','new')
				end, { timeout = _G.timeout_secs }	)
				stats.newhash = stats.newhash + 1
				logWrite(logfile,"New Hash Generated: " .. photo:getRawMetadata('path') .. " | " .. hashValue .. "\n")

			else
				stats.read_error = stats.read_error + 1
				logWrite(logfile,"Read Error: " .. photo:getRawMetadata('path') .. "\n")

			end
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

	return stats
end

--
-- Present dialog box for generating hashes. The dialog box presents options for
-- the type of file (e.g., RAW, TIFF, JPEG, etc) and whether to run on virtual
-- copies.
-- Returns:
--   result: 'ok' or 'cancel' from dialog box
--
function showGenerateHashesDialog()
	return LrFunctionContext.callWithContext( 'PreferenceExample', function ( context )
		local f = LrView.osFactory()
		local properties = LrBinding.makePropertyTable ( context )

		-- load preferences
		properties.raw_checkbox = prefs.raw_checkbox
		properties.dng_checkbox = prefs.dng_checkbox
		properties.tif_checkbox = prefs.tif_checkbox
		properties.jpeg_checkbox = prefs.jpeg_checkbox
		properties.psd_checkbox = prefs.psd_checkbox
		properties.png_checkbox = prefs.png_checkbox
		properties.video_checkbox = prefs.video_checkbox
		properties.ignore_virtual_copies = prefs.ignore_virtual_copies

		properties.log_file = prefs.log_file
		properties.log_enabled = prefs.log_enabled


		local contents = f:column 
			{
				spacing = f:dialog_spacing(),
				f:row {
					f:static_text {
						title = "Generate hashes and save to metadata.",
						alignment = "left",
						font = "<system/bold>",
					},
				},
				f:row {
					f:static_text {
						title = "Note: files with existing hash values will be ignored\n"..
										"and left unchanged.",
						alignment = "left",
						font = "<system>",
					},
				},
				f:group_box {
					title = 'File types',
					font = "<system>",
					size = 'regular',
					fill_horizontal = 1,
					bind_to_object = properties,
					spacing = f:dialog_spacing(),
					f:row {
						spacing = f:dialog_spacing(),
						f:checkbox {
							title = 'RAW',
							value = LrView.bind('raw_checkbox'),
							checked_value = 'checked',
							unchecked_value = 'unchecked',
						},
						f:checkbox {
							title = 'DNG',
							value = LrView.bind('dng_checkbox'),
							checked_value = 'checked',
							unchecked_value = 'unchecked',
						},
						f:checkbox {
							title = 'TIF',
							value = LrView.bind('tif_checkbox'),
							checked_value = 'checked',
							unchecked_value = 'unchecked',
						},
					},
					f:row {
						spacing = f:dialog_spacing(),

						f:checkbox {
							title = 'JPEG',
							value = LrView.bind('jpeg_checkbox'),
							checked_value = 'checked',
							unchecked_value = 'unchecked',
						},						
						f:checkbox {
							title = 'PSD',
							value = LrView.bind('psd_checkbox'),
							checked_value = 'checked',
							unchecked_value = 'unchecked',
						},
						f:checkbox {
							title = 'PNG',
							value = LrView.bind('png_checkbox'),
							checked_value = 'checked',
							unchecked_value = 'unchecked',
						},						
						f:checkbox {
							title = 'Video',
							value = LrView.bind('video_checkbox'),
							checked_value = 'checked',
							unchecked_value = 'unchecked',
						},
					},
					f:row {
						spacing = f:dialog_spacing(),
						f:static_text {
							title = "Unchecked file types will be ignored.",
							alignment = "left",
							font = "<system/small>",
							size = "small",
						}
					}

				},
				f:group_box {
					title = 'Virtual Copies',
					font = "<system>",
					size = 'regular',
					fill_horizontal = 1,
					bind_to_object = properties,
					spacing = f:dialog_spacing(),
					f:row{
						spacing = f:dialog_spacing(),
						f:checkbox {
							title = "Ignore virtual copies",
							value = LrView.bind('ignore_virtual_copies'),
							checked_value = 'checked',
							unchecked_value = 'unchecked',
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
				title = "Validator : Generate Hashes",
				contents = contents,
			}
		)

		if result == 'ok' then
			-- save results to preferences
			prefs.raw_checkbox = properties.raw_checkbox
			prefs.dng_checkbox = properties.dng_checkbox
			prefs.tif_checkbox = properties.tif_checkbox
			prefs.jpeg_checkbox = properties.jpeg_checkbox
			prefs.psd_checkbox = properties.psd_checkbox
			prefs.png_checkbox = properties.png_checkbox
			prefs.video_checkbox = properties.video_checkbox
			prefs.ignore_virtual_copies = properties.ignore_virtual_copies

			prefs.log_file = properties.log_file
			prefs.log_enabled = properties.log_enabled
		end

		return result
	end )
end




--
-- Show summary stats after running Generate Hashes. Note that even if the
-- photo selection contains 100 photos, hashes may be generated for far 
-- fewer images because:
--   * they already have an Archive Hash
--   * they are excluded due to file type
--   * they are excluded because they are virtual copies
--   * there was an error accessing the file
--
function showGenerateHashesResultsDialog( stats )
	return LrFunctionContext.callWithContext( 'showGenerateHashesResultsDialog', function ( context )
		local f = LrView.osFactory()
		local properties = LrBinding.makePropertyTable ( context )

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
							title = "Total files examined: " .. (stats.existinghash + stats.newhash + stats.skipped + stats.read_error),
							alignment = "left",
						},
					},
					f:row {
						f:static_text {
							title = "    New hashes generated: " .. stats.newhash,
							alignment = "left",
						},
					},
					f:row {
						f:static_text {
							title = "    Files with an existing hash: " .. stats.existinghash,
							alignment = "left",
						},
					},
					f:row {
						f:static_text {
							title = "    Files excluded due to type: " .. stats.skipped,
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
				title = "Validator : Generate Hash Results",
				contents = contents,
				cancelVerb = "< exclude >"
			}
		)
		return result
	end )
end






--
-- Menu Item: Generate Hashes
--

-- check for updates before starting GenerateHashes
--checkUpdatePluginSilent(10)

local input = showGenerateHashesDialog()

if input == 'ok' then
	local LrFunctionContext = import 'LrFunctionContext'
	local LrProgressScope = import 'LrProgressScope'
	LrTasks.startAsyncTask(function ()
		LrFunctionContext.callWithContext('function', function(context)
	
			local progressScope = LrProgressScope( {
				title = 'Validator : generating hashes',
				functionContext = context,
			})
		
			progressScope:setPortionComplete(0.0,1.0)
			progressScope:setCancelable(true)
		
			local stats = GenerateHashes(progressScope)

			showGenerateHashesResultsDialog(stats)
		end)
	end)
end	
		
		
		




