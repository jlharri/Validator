--[[----------------------------------------------------------------------------
ClearHashes.lua

This file contains functions for clearing all of the hash values and Validator
specific metadata fields.

Note that the command ClearHashes requires that the user actively select
photos. If no photos are selected, the menu command will not operate on the
default set of all photos in the grid.

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
local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local LrView = import 'LrView'

local catalog = LrApplication.activeCatalog()


--
-- Clear hash values and all related metadata fields from the selected images. 
-- Arguments: 
--   progressScope
-- Returns: 
--   stats.new: the number of files without an archive hash
--   stats.existing: the number of files with an archive hash
--
function ClearHashes( progressScope )
  local stats = {new=0, existing=0}

	local catPhotos = catalog:getTargetPhotos()

	-- iterate over all photos
	for i, photo in ipairs (catPhotos ) do

		progressScope:setPortionComplete(i-1,#catPhotos)
		progressScope:setCaption(i .. '/' .. #catPhotos .. '          ' .. photo:getFormattedMetadata('fileName'))


		local status = photo:getPropertyForPlugin ( _PLUGIN,'archiveHash' )

		if status == nil then
			stats.new = stats.new + 1
		elseif status ~= nil then
			stats.existing = stats.existing + 1
		else
			error("invalid operation")
		end

		-- clear metadata fields
		catalog:withPrivateWriteAccessDo( function()
			photo:setPropertyForPlugin ( _PLUGIN,'archiveHash',nil)	
			photo:setPropertyForPlugin ( _PLUGIN,'archiveDate',nil)
			photo:setPropertyForPlugin ( _PLUGIN,'lastHash',nil)	
			photo:setPropertyForPlugin ( _PLUGIN,'lastDate',nil)
			photo:setPropertyForPlugin ( _PLUGIN,'status','N/A')		
		end, { timeout = _G.timeout_secs }	)
		
	end
	progressScope:done()

  return stats
end

--
-- Display dialog with warning and confirmation before clearing hashes from
-- selected images.
--
function showClearHashesDialog()
	return LrFunctionContext.callWithContext( 'PreferenceExample', function ( context )	
    local f = LrView.osFactory()

    -- the checkbox to confirm user choice is always left unchecked
		local properties = LrBinding.makePropertyTable ( context )
		properties.confirm = 'unchecked'

    -- Create the contents for the dialog.
    local c = f:column {
      spacing = f:dialog_spacing(),
   	 	f:row {
    	  f:static_text {
    		  aligment = "left",
    			title = "This command will erase existing hash values.",
    			font = "<system/bold>",
    		},
    	},
    	f:row {
    	  f:static_text {
    		  alignment = "left",
    			title = "Once hashes have been erased, they will not be recoverable.\nAre you absolutely sure you want to continue?",
    		},
    	},
    	f:row {
    	  f:checkbox {
    		  bind_to_object = properties,
    			title = "Yes, I want to clear hashes from selected files.",
    			value = LrView.bind('confirm'),
    			checked_value = 'checked',
    			unchecked_value = 'unchecked',
	    	}

   		}
    }

		local choice = LrDialogs.presentModalDialog {
		  title = "Validator : Clear Hashes",
			contents = c,
		}

		return choice, properties.confirm
	end)
end


--
-- Menu Item: Clear Hashes
--

-- Check to make sure at least some photos are selected. If no photos are selected, 
-- display a warning message 
local target = catalog:getTargetPhoto()
if target == nil then
	LrDialogs.message("No images selected","Please select the images whose hash values you wish to clear.","info")
	return
end

-- show dialog box
local input, confirm = showClearHashesDialog()

-- Confirm that the user wants to clear hashes with a checkbox
if input == 'ok' and confirm == 'unchecked' then
	LrDialogs.message("Confirm checkbox not selected","Please confirm your intent to clear hashes by selecting the checkbox.","info")
	return
end

-- If both checks above pass, then start clearing hashes with AsyncTask
if input == 'ok' then

	local LrFunctionContext = import 'LrFunctionContext'
	local LrProgressScope = import 'LrProgressScope'
	LrTasks.startAsyncTask(function ()
		LrFunctionContext.callWithContext('function', function(context)
	
			local progressScope = LrProgressScope( {
				title = 'Validator : clearing hashes',
				functionContext = context,
			})
		
			progressScope:setPortionComplete(0.0,1.0)
			progressScope:setCancelable(true)
		
			ClearHashes(progressScope)
		end)
	end)
end

