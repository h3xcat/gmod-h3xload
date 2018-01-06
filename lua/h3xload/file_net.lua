-- This is not finished, or cleanup up. I know it looks ugly.

local BufferInterface = H3xLoad.Libs.BufferInterface
--------------------------------------------------------------------------------
H3xLoad.FileNet = {}
local FileNet = H3xLoad.FileNet

FileNet.UserData = {}

if SERVER then
	util.AddNetworkString( "H3xLoad_FileNet_RequestNextBlock" )
	util.AddNetworkString( "H3xLoad_FileNet_NextBlock" )
end

local filenet_chunk_size = 32000

if SERVER then
	function FileNet.Compress( original_file, target_filename )
		-- Open original file
		local fl_o = file.Open( original_file, "rb", "DATA")
		if not fl_o then
			ErrorNoHalt("[H3xLoad] Unable to open ",original_file,"\n")
			return false
		end
		local buffer_o = BufferInterface(fl_o)

		-- Open compressed file
		local fl_c = file.Open( target_filename, "wb", "DATA" )
		if not fl_c then
			ErrorNoHalt("[H3xLoad] Unable to open ",target_filename,"\n")
			fl_o:Close()
			return false
		end
		local buffer_c = BufferInterface(fl_c)


		local o_size = buffer_o:Size()
		while ( o_size-buffer_o:Tell() >= filenet_chunk_size ) do
			local compressed = util.Compress( buffer_o:ReadData(filenet_chunk_size) )
			local compressed_size = #compressed
			buffer_c:WriteUInt16(compressed_size)
			buffer_c:WriteData(compressed, compressed_size)
		end

		local remaining =  o_size-buffer_o:Tell()
		local compressed = util.Compress( buffer_o:ReadData(remaining) )
		local compressed_size = #compressed
		buffer_c:WriteUInt16(compressed_size)
		buffer_c:WriteData(compressed, compressed_size)
		
		fl_o:Close()
		fl_c:Close()
		return true, compressed_file
	end

	function FileNet.OpenFile( filename )
		if FileNet.IsFileOpen then FileNet.CloseFile() end
		
		
		local fl = file.Open( filename ,"rb", "DATA")
		if not fl then 
			ErrorNoHalt("[H3xLoad] Unable to open ",filename,"\n")
			return false
		end

		FileNet.IsFileOpen = true
		FileNet.File = fl
		FileNet.FileBuffer = BufferInterface(fl)

		-- Generate block list
		local buffer = FileNet.FileBuffer
		local file_size = buffer:Size()
		local file_blocks = {}

		while buffer:Tell() < file_size do
			local block_start = buffer:Tell()
			local block_size = buffer:ReadUInt16()
			file_blocks[#file_blocks + 1] = block_start
			buffer:Seek(block_start+block_size+2)
		end

		FileNet.FileBlocks = file_blocks

		MsgN("[H3xLoad] Prepared compressed file for networking, total blocks: ",#file_blocks)
	end

	function FileNet.CloseFile()
		if not FileNet.IsFileOpen then return end
		FileNet.IsFileOpen = false
		FileNet.File:Close()
		FileNet.File = nil
		FileNet.FileBuffer = nil
		FileNet.FileBlocks = nil
	end

	function FileNet.SendFile( ply, filename )

	end

	function FileNet.RequestNextBlock( len, ply )
		if not FileNet.IsFileOpen then return end

		local buffer = BufferInterface("net")
		local block_num = buffer:ReadUInt16()
		local block_start = FileNet.FileBlocks[block_num]
		if not block_start then return end

		local fl_buffer = FileNet.FileBuffer
		fl_buffer:Seek(block_start)
		local block_size = buffer:ReadUInt16()

		net.Start("H3xLoad_FileNet_NextBlock", true)
		buffer:WriteBool(#FileNet.FileBlocks == next_block) -- Is final block?
		buffer:WriteUInt16(block_size)
		buffer:WriteData(fl_buffer:ReadData(block_size),block_size)
		net.Send(ply)
	end
	net.Receive( "H3xLoad_FileNet_RequestNextBlock", FileNet.RequestNextBlock )
end

if CLIENT then
	function FileNet.RequestCacheFile()
		local cache_file = H3xLoad.CacheFileName()
		local fl = file.Open(cache_file,"wb","DATA")
		if not fl then
			ErrorNoHalt("[H3xLoad] Unable to open ",cache_file,"\n")
			return
		end
		FileNet.File = fl
		FileNet.FileBuffer = BufferInterface(fl)

		FileNet.CurrentBlock = 0
		FileNet.RequestNextBlock()
	end

	function FileNet.RequestNextBlock()
		FileNet.CurrentBlock = FileNet.CurrentBlock + 1
		net.Start("H3xLoad_FileNet_RequestNextBlock")
		net.WriteUInt(FileNet.CurrentBlock, 16)
		net.SendToServer()
	end
	
	function FileNet.NextBlock()
		local buffer = BufferInterface("net")
		local is_final = buffer:ReadBool()

		local block_size = buffer:ReadUInt16()
		local block_compressed = buffer:ReadData(block_size)

		FileNet.FileBuffer:WriteData( util.Decompress(block_compressed) )

		if not is_final then
			FileNet.RequestNextBlock()
		else
			MsgN("[H3xLoad] Completed receiving file")
			FileNet.File:Close()

			local load_queue = H3xLoad.LoadQueue
			load_queue[#load_queue + 1] = { type="gma_resources" }
		end

	end

	net.Receive( "H3xLoad_FileNet_NextBlock", FileNet.NextBlock)
end