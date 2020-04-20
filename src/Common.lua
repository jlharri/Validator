--[[----------------------------------------------------------------------------
Common.lua

This file contains commonly used helper functions. 

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

--
-- This function writes a text string to a file if the
-- input file points to a open file handle. Otherwise
-- this function does nothing.
--
function logWrite (file, text)
  if file then
    file:write(text)
    file:flush()
  end
end

