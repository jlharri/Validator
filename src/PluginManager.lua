--[[----------------------------------------------------------------------------
PluginManager.lua

Responsible for creating the dialog entry in the Plugin Manager dialog window 
which manages the individual plug-ins installed in the Lightroom application.

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



local LrView = import "LrView"
local LrHttp = import "LrHttp"
local LrDialogs = import "LrDialogs"
local LrBinding = import "LrBinding"
local LrPrefs = import "LrPrefs"
local LrColor = import "LrColor"
prefs = LrPrefs.prefsForPlugin()

PluginManager = {}

require 'AutoUpdate'


--
-- Initialize properties at start
--
function PluginManager.startDialog(p)
	p.auto_check_for_update = prefs.auto_check_for_update
end

--
-- Save preferences when done
--
function PluginManager.endDialog(p, why)
	prefs.auto_check_for_update = p.auto_check_for_update
end


--
-- Defines the view factory for the dialog box in the the plugin manager
--
function PluginManager.sectionsForTopOfDialog(f,properties)
	return {
		-- section for the top of the dialog
		{
			title = "Validator",
			f:row {
				f:column {
					f:static_text{
						title = "Stephen Bay's Image Validator Plug-in",
						alignment = 'left',
						font = '<system/bold>',
					},
					f:static_text{
						title = 'Version ' .. _G.version,
						aligntment = 'left',
						font = '<system/small/bold>',
					},
				},
			},
			f:row {
				f:static_text {
					title = 'Validates images and checks for file corruption by computing a hash value and comparing\n' ..
					        'it with previously stored values.',
					alignment = 'left',
				},
			},	
			f:row {
				spacing = f:label_spacing(),
				margin = 0,
				f:static_text {
					title = 'More information:',
					alignment = 'left',
				},
				f:static_text {
					title = "Stephen's Website",
					alignment = 'left',
					text_color = LrColor(0,0,1),
					mouse_down = function()
						LrHttp.openUrlInBrowser(_G.URL_bayimages)
					end,
				},
				f:static_text {
					title = "•",
					alignment = 'left',
				},
				f:static_text {
					title = "Validator Plugin Home Page",
					alignment = 'left',
					text_color = LrColor(0,0,1),
					mouse_down = function()
						LrHttp.openUrlInBrowser(_G.URL_validator)
					end,
				},
			},
		},
		{
			title = "Check for Updates",
			spacing = f:dialog_spacing(),
			f:row {
				bind_to_object = properties,
				f:checkbox {
					title = 'Check for updates to this plugin when Lightroom starts.',
					value = LrView.bind('auto_check_for_update'),
					checked_value = 'checked',
					unchecked_value = 'unchecked',
				},
			},
			f:row {
				f:push_button {
					place_horizontal = 0.5,
					width = 150,
					alignment = "center",
					title = 'Check for updates now',
					enabled = LrView.bind('buttonEnabled'),
					action = function()
						checkUpdatePluginExplicit()
					end,
				},
			}
		}
	}
end



	