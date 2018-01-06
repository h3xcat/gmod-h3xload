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
			local block_data = buffer_o:ReadData(filenet_chunk_size)

			local block_compressed = util.Compress( block_data )
			local block_compressed_size = #block_compressed
			buffer_c:WriteUInt16(block_compressed_size)
			buffer_c:WriteData(block_compressed, block_compressed_size)
		end

		local remaining =  o_size-buffer_o:Tell()
		local block_data = buffer_o:ReadData(remaining)
		local block_compressed = util.Compress( block_data )
		local block_compressed_size = #block_compressed
		buffer_c:WriteUInt16(block_compressed_size)
		buffer_c:WriteData(block_compressed, block_compressed_size)
		
		fl_o:Close()
		fl_c:Close()
		return true, compressed_file
	end

	function FileNet.OpenFile( filename )
		if FileNet.File then FileNet.CloseFile() end
		
		
		local fl = file.Open( filename ,"rb", "DATA")
		if not fl then 
			ErrorNoHalt("[H3xLoad] Unable to open ",filename,"\n")
			return false
		end

		FileNet.File = fl
		FileNet.FileBuffer = BufferInterface(fl)

		-- Generate block list
		local buffer = FileNet.FileBuffer
		local file_size = buffer:Size()
		local file_blocks = {}

		while buffer:Tell() < file_size do
			local block_start = buffer:Tell()
			local block_size = buffer:ReadUInt16()
			buffer:Seek(block_start+block_size+2)

			file_blocks[#file_blocks + 1] = block_start
		end

		FileNet.FileBlocks = file_blocks
		FileNet.TotalBlocks = #file_blocks

		MsgN("[H3xLoad] Prepared compressed file for networking, total blocks: ",#file_blocks)
	end

	function FileNet.CloseFile()
		if not FileNet.IsFileOpen then return end
		FileNet.File:Close()
		FileNet.File = nil
		FileNet.FileBuffer = nil
		FileNet.FileBlocks = nil
	end
	
	net.Receive( "H3xLoad_FileNet_RequestNextBlock", function( len, ply )
		if not FileNet.File then return end

		local buffer = BufferInterface("net")

		local block_num = buffer:ReadUInt16()
		local block_start = FileNet.FileBlocks[block_num]
		if not block_start then return end

		local fl_buffer = FileNet.FileBuffer
		fl_buffer:Seek(block_start)
		local block_size = fl_buffer:ReadUInt16()
		local block_data = fl_buffer:ReadData(block_size)

		net.Start("H3xLoad_FileNet_NextBlock")
		buffer:WriteUInt16(block_num)
		buffer:WriteUInt16(FileNet.TotalBlocks)
		
		buffer:WriteUInt16(block_size)
		buffer:WriteData(block_data,block_size)
		net.Send(ply)
	end )
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

		FileNet.CurrentBlock = 1
		FileNet.RequesBlock( 1 )
	end

	function FileNet.RequestNextBlock()
		FileNet.CurrentBlock = FileNet.CurrentBlock + 1
		FileNet.RequesBlock( FileNet.CurrentBlock )
	end

	function FileNet.RequesBlock( num )
		net.Start("H3xLoad_FileNet_RequestNextBlock")
		net.WriteUInt(num, 16)
		net.SendToServer()
	end
	
	function FileNet.NextBlock()
		local buffer = BufferInterface("net")

		local block_num = buffer:ReadUInt16()
		local block_total = buffer:ReadUInt16()
		local block_size = buffer:ReadUInt16()
		
		if FileNet.CurrentBlock ~= block_num then
			FileNet.RequesBlock( FileNet.CurrentBlock )
			MsgN("[H3xLoad] Invalid block (should:",FileNet.CurrentBlock," received:",block_num,")")
			return
		end
		MsgN("[H3xLoad] Received block ",block_num,"/",block_total)

		local block_compressed = buffer:ReadData(block_size)
		local block_data = util.Decompress(block_compressed)

		if not block_data then
			MsgN("[H3xLoad] Invalid block received")
			return
		end
		FileNet.FileBuffer:WriteData( block_data )

		if block_num < block_total  then
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