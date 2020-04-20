--[[----------------------------------------------------------------------------
AutoUpdate.lua

The functions in this file check to see if the plug-in is the most recent
version.

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

local LrDialogs = import 'LrDialogs'
local LrHttp = import 'LrHttp'
local LrView = import 'LrView'

local LrPrefs = import "LrPrefs"
local prefs = LrPrefs.prefsForPlugin()

--
-- Connect to the server and read in the latest version number from a text file.
-- If there is an error, this function returns nil. The file should just contain
-- a single line with the version number (e.g., "0.9").
--
-- Returns the version number or nil if there was a problem connecting.
--
function getLatestVersionNumber()

    data, headers = LrHttp.get(_G.URL_version)

    -- check for errors in get call
    if not data or headers.status ~= 200 then
      return nil
    end

    return tonumber(data)
end


--
-- Check to see if there is an update to the plug-in. If so, the function brings
-- up the webpage where the user can download the lastest version. This function
-- only brings up a dialog box if the check is successful (server is reached) and
-- there is an update. If there is a failure to connect or there is no update 
-- available, there is no response.
-- 
-- Arguments:
--   delay: number of seconds that must have passed since the last check or
--          else the check is skipped.
-- 
function checkUpdatePluginSilent(delay)
  import "LrTasks".startAsyncTask( function()
  
    -- if it is less than delay second since last update skip the check
    local current_time = os.time();
    if (current_time - prefs.last_update_check < delay) then
      return
    end

    -- check for latest version number
    local latest = getLatestVersionNumber()

    -- if there is an error when checking do nothing
    if (not latest) then
      return
    end

    -- update the last check time
    prefs.last_update_check = current_time

    -- if a newer version exists show download dialog box
    if (latest > _G.version) then
      local result = showUpdateDialog()
      if result == 'ok' then
        LrHttp.openUrlInBrowser(_G.URL_download)
      end
      return
    end

  end)
end


--
-- Check to see if there is an update to the plug-in. If so, the function brings
-- up the webpage where the user can download the lastest version. If the function
-- fails to connect, it brings up an error message. If there is no update, the 
-- function brings up a dialog box stating that the plugin is the most recent
-- version.
--
function checkUpdatePluginExplicit()
  import "LrTasks".startAsyncTask( function()
  
    -- check for latest version number
    local latest = getLatestVersionNumber()

    -- if there is an error when user presses "check for updates now" 
    -- present dialog box
    if (not latest) then
      LrDialogs.message("Error connecting to server to check for new version","Please try again later.","info")
      return
    end

    -- if a newer version exists show download dialog box
    if (latest > _G.version) then
      local result = showUpdateDialog()
      if result == 'ok' then
        LrHttp.openUrlInBrowser(_G.URL_download)
      end
      return
    end

    -- if there is no newer version of the software
    LrDialogs.message("You have the latest version of the plugin. No updates are available at this time.")
  end)
end


--
-- Dialog box to confirm download of the new plug-in version
--
function showUpdateDialog()
  
  local f = LrView.osFactory()

  -- Create the contents for the dialog.
  local c = f:column {
    f:row {
      f:static_text {
        aligment = "left",
        title = "There is a newer version of Validator available.\n",
        font = "<system/bold>",
      },
    },
    f:row {
      f:static_text {
        alignment = "left",
        title = "Push the download button to get the latest version.",
      },
    },
  }

  local choice = LrDialogs.presentModalDialog {
    title = "Check for updates",
    contents = c,
    actionVerb = "Download", 
  }
  return choice
end
