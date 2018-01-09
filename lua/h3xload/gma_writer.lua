local string_lower = string.lower 
local os_time = os.time 
--------------------------------------------------------------------------------
local BufferInterface = H3xLoad.Libs.BufferInterface
--------------------------------------------------------------------------------

local function FileCRC( filename, path )
	-- Appearantly, gmod doesn't do any CRC checks...
	return 0, file.Size(filename, path or "GAME" )
	
	--[[
	local fl = file.Open( filename, "rb", path or "GAME" )
	if not fl then
		ErrorNoHalt("Could not open ",filename,"\n")
		return 0, 0 
	end
	local file_crc = 0
	local file_size = fl:Size()
	
	while fl:Tell() < file_size do
		file_crc = crc32_byte( fl:ReadByte(), file_crc )
	end
	fl:Close()
	return file_crc, file_size
	]]
end

local function FileWriteBuffer( path, buffer )
	local fl = file.Open( path, "rb", "GAME" )
	if not fl then 
		ErrorNoHalt("[H3xLoad] Could not open ",path,"\n")
		return
	end
	local fl_buffer = BufferInterface(fl)
	local fl_size = fl:Size()
	while ( fl_size-fl:Tell() >= 1000 ) do
		buffer:WriteData(fl_buffer:ReadData(1000),1000)
	end
	local remaining =  fl_size-fl:Tell()
	buffer:WriteData( fl_buffer:ReadData(remaining), remaining )
	fl:Close()
end

local gma_ident = "GMAD"
local gma_version = 3
function H3xLoad.WriteGMA( path, files )
	local fl = file.Open( path, "wb", "DATA" )
	if not fl then
		ErrorNoHalt("[H3xLoad] Could not open "..path)
		return false
	end
	local buffer = BufferInterface( fl )

	-- Header (5)
	buffer:WriteData( gma_ident, 4 )
	buffer:WriteUInt8( gma_version )

	-- SteamID (8) [unused]
	buffer:WriteUInt32(0)
	buffer:WriteUInt32(0)
	
	-- TimeStamp (8)
	buffer:WriteUInt32(os_time())
	buffer:WriteUInt32(0)

	-- Required content (a list of strings)
	buffer:WriteUInt8(0) -- signifies nothing

	-- Addon Name (n)
	buffer:WriteString( "Client Files" )
	
	-- Addon Description (n)
	buffer:WriteString( "" );

	-- Addon Author (n) [unused]
	buffer:WriteString( "Author Name" )
	
	-- Addon Version (4) [unused]
	buffer:WriteInt32( 1 )

	-- File list
	local file_num = 0;
	for k, resource_file in pairs( files ) do
		local file_crc, file_size = FileCRC( resource_file )
		if file_size ~= 0 then 
			file_num = file_num + 1
			--print(file_num, resource_file, file_crc, file_size)
			buffer:WriteUInt32( file_num ) -- File number (4)
			buffer:WriteString( string_lower(resource_file) ) -- File name (all lower case!) (n)
			buffer:WriteUInt32( 0 )      -- File size (8)
			buffer:WriteUInt32( file_size )
			buffer:WriteUInt32( file_crc )   -- File CRC (4)
		end
	end

	-- Zero to signify end of files
	file_num = 0
	buffer:WriteUInt32( file_num );
	
	-- The files
	for k, resource_file in pairs( files ) do
		FileWriteBuffer( resource_file, buffer )
	end

	-- CRC what we've written (to verify that the download isn't shitted) (4)
	buffer:WriteUInt32( 0 )
	fl:Close()

	--[[
	local gma_crc = FileCRC( path, "DATA" )


	local fl = file.Open( path, "ab", "DATA" )
	local buffer = BufferInterface( fl )
	buffer:WriteUInt32( gma_crc )
	fl:Close()
	]]
	return true
end