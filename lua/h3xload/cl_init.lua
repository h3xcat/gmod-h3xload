
H3xLoad.LoadQueue = {}
H3xLoad.LoadCounter = 0
local load_limit = 10

local function DownloadWorkshopAddon( workshopid )
	MsgN("[H3xLoad] Loading workshop item "..workshopid)
	H3xLoad.LoadCounter = H3xLoad.LoadCounter + 1
	steamworks.FileInfo( workshopid, function(result)
		if not result then
			MsgN("[H3xLoad] Unable to retrieve workshop file info (",workshopid,")")
			H3xLoad.LoadCounter = H3xLoad.LoadCounter - 1
			H3xLoad.ProcessLoadQueue()
			return
		end
		steamworks.Download( result.fileid, true, function(path) 
			local succ = game.MountGMA( path )
			if succ then
				MsgN("[H3xLoad] Mounted workshop item (",workshopid,")")
			else
				MsgN("[H3xLoad] Unable to mount workshop item (",workshopid,")")
			end

			H3xLoad.LoadCounter = H3xLoad.LoadCounter - 1
			H3xLoad.ProcessLoadQueue()
		end)
	end )
end

local function LoadGMA( filename )

end

function H3xLoad.ProcessLoadQueue()
	local load_queue = H3xLoad.LoadQueue
	while #load_queue > 0 and H3xLoad.LoadCounter < load_limit do
		local addon = load_queue[#load_queue]
		load_queue[#load_queue] = nil

		if addon.type == "workshop" then
			DownloadWorkshopAddon( addon.workshopid )
		elseif addon.type == "gma_resources" then
			H3xLoad.LoadResources()
		end
	end
end

--------------------------------------------------------------------------------

function H3xLoad.RequestResources()
	MsgN("[H3xLoad] Requesting resource files from server...")
	H3xLoad.FileNet.RequestCacheFile()
end

function H3xLoad.LoadResources()
	local cache_file = H3xLoad.CacheFileName()

	-- Check if cached version exist
	if file.Exists( cache_file, "DATA" ) then
		local cache_time = H3xLoad.GetCacheTimestamp()
		local server_cache_time = GetGlobalString("H3xLoad_CacheTimestamp")
		if cache_time ~= server_cache_time then
			MsgN("[H3xLoad Outdated resource files")
			file.Delete( cache_file )
			H3xLoad.RequestResources()
			return 
		end

		local succ, mounted_files = game.MountGMA( cache_file )
		if succ then
			MsgN("[H3xLoad] Successfully mounted ", #mounted_files, " resource files")
		else
			MsgN("[H3xLoad] Failed to load resource files (",cache_file,")")
			file.Delete( cache_file )
			H3xLoad.RequestResources()
		end
	else
		H3xLoad.RequestResources()
	end
end

function H3xLoad.Initialize()
	timer.Create( "H3xLoad_Loader", 1, 0, H3xLoad.ProcessLoadQueue )
	H3xLoad.LoadResources()
end
hook.Add("Initialize", "H3xLoad", H3xLoad.Initialize)


net.Receive( "H3xLoad_WorkshopAddons", function( len ) 
	local load_queue = H3xLoad.LoadQueue
	local num = net.ReadUInt( 16 )
	for i=1, num do
		local workshopid = net.ReadString()
		load_queue[#load_queue + 1] = {
			type="workshop",
			workshopid = workshopid,
		}
	end
end)