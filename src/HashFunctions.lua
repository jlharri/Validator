--[[----------------------------------------------------------------------------
HashFunctions.lua

This file contains the functions for computing hashes on image files.

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

local LrTasks = import 'LrTasks'
local LrMD5 = import 'LrMD5'
local LrDialogs = import 'LrDialogs'
local LrFileUtils = import 'LrFileUtils'
local LrDigest = import 'LrDigest'

--
-- Compute MD5 hash for image file using the Lightroom SDK functions. This 
-- function should work on both Mac / Win.
-- Arguments:
--   filepath: the path to the image file as returned by getRawMetadata('path') 
--             for example /Users/sbay/lightroom-dev/images/test/bay031129.tif
-- Returns:
--   The md5 hash as string or nil if there was an error
--

function MD5hash (filepath)
	-- use LrFileUtils instead of Lua io functions
	-- this is MUCH faster for large files

	-- check if file can be read otherwise readFile will throw an error and
	-- stop processing
	if LrFileUtils.isReadable(filepath) == false then
		return nil
	end

	local f = LrFileUtils.fileAttributes(filepath)

	-- load entire file into memory
	-- this is faster than incremenal approach below
	if f.fileSize < _G.incremental_threshold then
		--LrDialogs.message("LrFileUtils","file size is " .. f.fileSize)
		local data = LrFileUtils.readFile(filepath)
		return LrMD5.digest(data)
	end

	-- incremental load of file and computation of MD5 hash
	-- this is slower than using the approach above
	local x = LrDigest.MD5.init()

	local file = io.open(filepath,'rb')
	--LrDialogs.message("Incremental Load","file size is " .. f.fileSize .. " block size is " .. _G.block_size)

	while true do
		local data = file:read(_G.block_size)
		if not data then break end
		x:update(data)
	end
	io.close(file)
	
	local hashvalue = x:digest()
	return hashvalue

end


--[[
-- This version of MD5hash is based on Lua io functions
-- It is much slower than using LrFileUtils
function MD5hash2( filepath )
	local inp = io.open(filepath,"rb")

	-- error reading file
	if inp == nil then
		return nil
	end

	local data = inp:read("*all")
	inp:close()
	return LrMD5.digest(data)
end
]]



--[[
-- This version of MD5hash will throw an assert error if it fails
function MD5hash( filepath )
	local inp = assert(io.open(filepath,"rb"))
	local data = inp:read("*all")
	return LrMD5.digest(data)
end
]]


--[[
--
-- Compute MD5 hash for an image using the md5 system command on Max OS X.
-- This version is about 10x faster than the lightroom LrMD5.digest approach.
--
-- A different function will need to be called for Windows
--
function MD5hash_mac_system_call( filepath )
	-- run hash on file using external commands
	-- note io.popen doesn't work on Mac		
	tmpfile = 'Users/sbay/lightroom-dev/test.txt'
	LrTasks.execute( 'md5 -q ' .. filepath .. '> ' .. tmpfile) -- WARNING check execution status
	local f = io.open(tmpfile) -- WARNING check that file opened successfully
	local hashValue = f:read("*all")
	f:close()
		
	-- process hash value to strip unnecessary characters
	hashValue = string.gsub(hashValue,"\n","")

	return hashValue
end
]]





