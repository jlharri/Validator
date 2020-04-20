--[[----------------------------------------------------------------------------
MetadataTagset.lua

This tagset definition file returns a table listing the fields that should
appear in the metadata panel in Lightroom.

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

return {

	title = "Validator",
	id = 'ValdiatorTagset',
	
	items = {
	  -- basic information about the image file
		'com.adobe.filename',
		'com.adobe.folder',
		
		'com.adobe.separator',
		
		-- fields for validator
		'net.bayimages.validator.archiveHash',
		'net.bayimages.validator.archiveDate',
		'net.bayimages.validator.lastHash',
		'net.bayimages.validator.lastDate',
		'net.bayimages.validator.status',
	},
}