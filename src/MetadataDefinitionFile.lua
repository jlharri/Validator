--[[----------------------------------------------------------------------------
MetadataDefinitionFile.lua

Defines the additional metadata fields Lightroom adds for the plug-in.

There are five fields added
  archiveHash: the "official" hash for the file (i.e. computed when the file was 
               known to be good)
  archiveDate: date the archiveHash was computed
  lastHash:    the most recent hash computed for verification
  lastDate:    date  the lastHash was computed
  status:      an enum that can be new, change, match, or N/A
                 new -- a new file which only has an archiveHash
                 change -- a file where the archiveHash != lastHash
                 match -- a file where the archiveHash == lastHash
                 N/A -- a file without an archiveHash

Copyright Stephen Bay 2013

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

	metadataFieldsForPhotos = {
		{
			id = 'archiveHash',
			title = "Archive Hash",
			dataType = 'string',
			readOnly = true,
		},
		{
			id = 'archiveDate',
			title = 'Archive Date',
			dataType = 'string',
			readOnly = true,
		},
		{
			id = 'lastHash',
			title = 'Last Hash',
			dataType = 'string',
			readOnly = true,
		},
		{
			id = 'lastDate',
			title = "Last Date",
			dataType = 'string',
			readOnly = true,
		},
		{
			id = 'status',
			title = 'Status',
			dataType = 'enum',
			values = { 
				{
					value = 'new',
					title = 'new',
				},
				{	
					value = 'change',
					title = 'change',
				},
				{ 
					value = 'match',
					title = 'match',
				},
				{	
					value = 'N/A',
					title = 'N/A',
				},
			},
			readOnly = true,
			searchable = true,
			browsable = true,
		},
	},	
	schemaVersion = 1,
}


