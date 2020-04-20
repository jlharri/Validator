--[[----------------------------------------------------------------------------
Info.lua

Defines the plug-in and menu items for Lightroom.

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

-- Note about version numbers
-- To update the version number, the source needs to be updated in three spots:
-- Info.lua, PluginInit.lua (global variable), and in version.txt on the
-- website.

return {
	LrSdkVersion = 4.0,
	LrSdkMinimumVersion = 4.0,

	LrToolkitIdentifier = 'net.bayimages.validator',
	LrPluginName = "Validator",
	
	LrInitPlugin = 'PluginInit.lua',

	LrMetadataProvider = 'MetadataDefinitionFile.lua',
	LrMetadataTagsetFactory = 'MetadataTagset.lua',
	

	LrExportMenuItems = {
		{
			--title = 'Generate Hashes',
			title = LOC "$$$/Info/Generate=Generate Hashes",
			file = 'GenerateHashes.lua',
			enabledWhen = 'photosAvailable',
		},
		{
			--title = 'Verify Files',
			title = LOC "$$$/Info/Verify=Verify Files",
			file = 'VerifyImages.lua',
			enabledWhen = 'photosAvailable',
		},
		{
			--title = 'Accept Changed Hashes',
			title = LOC "$$$/Info/Accept=Accept Changed Hashes",
			file = 'AcceptHashes.lua',
			enabledWhen = 'photosAvailable',
		},		
		{
			--title = 'Clear Hashes',
			title = LOC "$$$/Info/Clear=Clear Hashes",
			file = 'ClearHashes.lua',
			enabledWhen = 'photosAvailable',
		},
		{
			--title = 'Help',
			title = LOC "$$$/Info/Help=Help",
			file = 'Help.lua',
		},		
	},


	LrLibraryMenuItems = {
		{
			--title = 'Generate Hashes',
			title = LOC "$$$/Info/Generate=Generate Hashes",
			file = 'GenerateHashes.lua',
			enabledWhen = 'photosAvailable',
		},
		{
			--title = 'Verify Files',
			title = LOC "$$$/Info/Verify=Verify Files",
			file = 'VerifyImages.lua',
			enabledWhen = 'photosAvailable',
		},
		{
			--title = 'Accept Changed Hashes',
			title = LOC "$$$/Info/Accept=Accept Changed Hashes",
			file = 'AcceptHashes.lua',
			enabledWhen = 'photosAvailable',
		},		
		{
			--title = 'Clear Hashes',
			title = LOC "$$$/Info/Clear=Clear Hashes",
			file = 'ClearHashes.lua',
			enabledWhen = 'photosAvailable',
		},
		{
			--title = 'Help',
			title = LOC "$$$/Info/Help=Help",
			file = 'Help.lua',
		},		
	},

	LrHelpMenuItems = {
		{
			--title = 'Help',
			title = LOC "$$$/Info/Help=Help",
			file = 'Help.lua',
		},
	},


	-- Add the entry for the Plug-in Manager Dialog
	LrPluginInfoProvider = 'PluginInfoProvider.lua',

	-- extra information for status panel
	LrPluginInfoUrl = "http://bayimages.net/blog/lightroom/validator/",
	VERSION = { major=0, minor=961, revision=0, build=0},

}

