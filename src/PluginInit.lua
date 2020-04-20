--[[----------------------------------------------------------------------------
PluginInit.lua

This file initializes global variables and user preferences for the plug-in.

Copyright 2013-2015 Stephen Bay

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

-- Global values
_G.pluginID = "net.bayimages.validator"
_G.URL_bayimages = "http://bayimages.net/"
_G.URL_validator = "http://bayimages.net/blog/lightroom/validator/"
_G.URL_download = "http://bayimages.net/blog/lightroom/download/"

-- This points to a file with a single number in it stating the most
-- recent version of the validator plugin. The file version_test.txt
-- has an arbitrarily high version number to force update.
_G.URL_version = "http://bayimages.net/lightroom/validator/version.txt"
_G.URL_version_test = "http://bayimages.net/lightroom/validator/version_test.txt"

-- Timeout is used in case an image file is already accessed in Lightroom by
-- another process
_G.timeout_secs = 5

-- Version number. This number needs to be the same as returned in 
-- table from Info.lua and on the website.
_G.version = 0.961

-- Block size for incremental loading of files during hash computation
_G.block_size = 10000

-- Load files incrementally when they are larger than this threshold
_G.incremental_threshold = 300000000


require 'AutoUpdate'

local LrPathUtils = import 'LrPathUtils'

--
-- Initialize preferences to default values
--

-- collection name for changed files
local prefs = import 'LrPrefs'.prefsForPlugin()
if prefs.collection_name == nil then
	prefs.collection_name = "validator_changed"
	prefs.collection_name = prefs.collection_name
end

-- valid file types
if prefs.raw_checkbox == nil then
	prefs.raw_checkbox = 'checked'
end

if prefs.dng_checkbox == nil then
	prefs.dng_checkbox = 'checked'
end

if prefs.tif_checkbox == nil then
	prefs.tif_checkbox = 'checked'
end

if prefs.jpeg_checkbox == nil then
	prefs.jpeg_checkbox = 'checked'
end

if prefs.psd_checkbox == nil then
	prefs.psd_checkbox = 'checked'
end

if prefs.png_checkbox == nil then
	prefs.png_checkbox = 'checked'
end

if prefs.video_checkbox == nil then
	prefs.video_checkbox = 'checked'
end

if prefs.ignore_virtual_copies == nil then
	prefs.ignore_virtual_copies = 'checked'
end

if prefs.verify_display_mismatch == nil then
	prefs.verify_display_mismatch = 'checked'
end

-- set auto update
if prefs.auto_check_for_update == nil then
	prefs.auto_check_for_update = 'checked'
end

-- execute check for update
-- this will run the first time the plug-in is installed
if prefs.auto_check_for_update == 'checked' then
	checkUpdatePluginSilent(0)
end

-- log file for hash checks
prefs.log_enabled = true

-- set default logfile (system safe)
local home = LrPathUtils.getStandardFilePath("home")
prefs.log_file = LrPathUtils.child(home,"validator_log.txt")


-- set the time variable for the last update check
if prefs.last_update_check == nil then
	prefs.last_update_check = os.time()
end




		




