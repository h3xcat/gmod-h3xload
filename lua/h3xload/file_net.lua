local BufferInterface = H3xLoad.Libs.BufferInterface
--------------------------------------------------------------------------------
local Config = H3xLoad.Config

H3xLoad.FileNet = {}
local FileNet = H3xLoad.FileNet

FileNet.UserData = {}

if SERVER then
	util.AddNetworkString( "H3xLoad_FileNet_FileBlock" )
	util.AddNetworkString( "H3xLoad_FileNet_ClientState" )
end

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
		while ( o_size-buffer_o:Tell() >= Config.FileNet_BlockSize ) do
			local block_data = buffer_o:ReadData(Config.FileNet_BlockSize)

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

			file_blocks[#file_blocks + 1] = {
				start=block_start,
				requests={}
			}
		end

		FileNet.FileBlocks = file_blocks
		FileNet.TotalBlocks = #file_blocks
		FileNet.SenderNextBlock = 1
		SetGlobalString( "H3xLoad_FileNet_TotalBlocks", tostring(FileNet.TotalBlocks) )
		MsgN("[H3xLoad] Prepared compressed file for networking, total blocks: ",#file_blocks)
	end

	function FileNet.CloseFile()
		if not FileNet.IsFileOpen then return end
		FileNet.File:Close()
		FileNet.File = nil
		FileNet.FileBuffer = nil
		FileNet.FileBlocks = nil

	end

	net.Receive( "H3xLoad_FileNet_ClientState", function( len, ply )
		if not FileNet.File then return end
		MsgN("[H3xLoad] Received client state update from ",ply)

		local buffer = BufferInterface("net")

		local file_blocks = FileNet.FileBlocks
		local count = math.min(buffer:ReadUInt16(), FileNet.TotalBlocks)
		for i = 1, count do
			local block_id = buffer:ReadUInt16()
			if not file_blocks[block_id] then return end
			file_blocks[block_id].requests[ply] = true
			file_blocks[block_id].send = true
		end
		
		timer.UnPause( "H3xLoad_FileNet_Sender" )
	end )

	timer.Create( "H3xLoad_FileNet_Sender", Config.FileNet_Interval or 1, 0, function()
		if not FileNet.File then return end

		local fl_buffer = FileNet.FileBuffer
		local net_buffer = BufferInterface("net")

		local file_blocks = FileNet.FileBlocks

		local offset = FileNet.SenderNextBlock-1
		local burst_left = Config.FileNet_BurstCount
		local total_blocks = FileNet.TotalBlocks
		for i = 1, total_blocks do
			local block_num = ((i-1+offset)%total_blocks) + 1

			local block = file_blocks[block_num]
			if block and block.send then
				FileNet.SenderNextBlock = block_num + 1
				local receivers = {}
				for ply, _ in pairs(block.requests) do
					receivers[#receivers+1] = ply
				end
				local block_start = block.start
				fl_buffer:Seek(block_start)
				local block_size = fl_buffer:ReadUInt16()
				local block_data = fl_buffer:ReadData(block_size)

				net.Start("H3xLoad_FileNet_FileBlock", true)
				net_buffer:WriteUInt16(block_num)
				net_buffer:WriteUInt32(block_start)
				net_buffer:WriteUInt16(block_size)
				net_buffer:WriteData(block_data,block_size)
				net.Send(receivers)

				block.send = false
				block.requests = {}
				
				burst_left = burst_left - 1
				if burst_left <= 0 then
					return
				end
				
			end
		end

		timer.Pause( "H3xLoad_FileNet_Sender" )
	end )
end

if CLIENT then
	function FileNet.SendClientState()
		local uncompleted_blocks = {}
		for i=1, FileNet.TotalBlocks do
			if not FileNet.CompletedBlocks[i] then
				uncompleted_blocks[#uncompleted_blocks+1] = i
			end
		end

		local net_buffer = BufferInterface("net")
		net.Start("H3xLoad_FileNet_ClientState")
		net_buffer:WriteUInt16(#uncompleted_blocks)
		for k, v in pairs(uncompleted_blocks) do
			net_buffer:WriteUInt16(v)
		end
		net.SendToServer()
	end

	function FileNet.DownloadThroughNet()
		local cache_file = H3xLoad.CacheFileName()
		local fl = file.Open(cache_file,"wb","DATA")
		if not fl then
			ErrorNoHalt("[H3xLoad] Unable to open ",cache_file,"\n")
			return
		end
		FileNet.Start = os.time()
		FileNet.File = fl
		FileNet.FileBuffer = BufferInterface(fl)
		FileNet.CompletedBlocks = {}
		FileNet.TotalBlocks = tonumber(GetGlobalString("H3xLoad_FileNet_TotalBlocks"))
		FileNet.BlockCounter = 0

		timer.Create("H3xLoad_FileNet_TimeoutCheck", 10, 0, function()
			MsgN("[H3xLoad] Incomplete download, server stopped transmiting. Requesting for more files...")
			FileNet.SendClientState()
		end)

		FileNet.SendClientState()
	end
	
	function FileNet.DownloadThroughHTTP()

	end

	function FileNet.RequestCacheFile()
		if isstring(Config.FileNet_URL) and Config.FileNet_URL ~= "" then
			FileNet.DownloadThroughHTTP()
		else
			FileNet.DownloadThroughNet()
		end
	end

	net.Receive( "H3xLoad_FileNet_FileBlock", function(len)
		if not FileNet.File then return end
		timer.Start("H3xLoad_FileNet_TimeoutCheck")

		local buffer = BufferInterface("net")

		local block_num = buffer:ReadUInt16()
		
		if FileNet.CompletedBlocks[block_num] then return end
		FileNet.BlockCounter = FileNet.BlockCounter + 1
		FileNet.CompletedBlocks[block_num] = true
		MsgN("[H3xLoad] Received block ",block_num)

		local block_start = buffer:ReadUInt32()
		local block_size = buffer:ReadUInt16()
		local block_compressed = buffer:ReadData(block_size)
		local block_data = util.Decompress(block_compressed)

		if not block_data then
			MsgN("[H3xLoad] Received corrupted block, something went horribly wrong!")
			return
		end
		FileNet.FileBuffer:Seek( block_start )
		FileNet.FileBuffer:WriteData( block_data )

		if FileNet.BlockCounter == FileNet.TotalBlocks then
			timer.Stop("H3xLoad_FileNet_TimeoutCheck")
			MsgN("[H3xLoad] Finished downloading resource files (",(os.time()-FileNet.Start),"s)")
			FileNet.File:Close()

			local load_queue = H3xLoad.LoadQueue
			load_queue[#load_queue + 1] = { type="gma_resources" }
		end
	end)

end