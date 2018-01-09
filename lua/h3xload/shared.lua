
H3xLoad = {}
H3xLoad.Libs = {}
H3xLoad.Libs.BufferInterface = include( "libraries/bufferinterface.lua" )
H3xLoad.Config = include( "config.lua" )

file.CreateDir( "h3xload" )
file.CreateDir( "h3xload/cache/" )

local function new_random_id()
	math.randomseed( os.time() )
	local valid_chars = "0123456789abcdefghijklmnopqrstuvwxyz"
	local random_id = {}
	for i=1, 8 do
		random_id[i] = valid_chars[math.random(1,36)] -- I'd be surprised if collision happens ( 1 / 2,821,109,907,456 )
	end
	return table.concat(random_id)
end

function H3xLoad.GetServerID()
	if H3xLoad.ServerID then return H3xLoad.ServerID end

	if SERVER then
		if file.Exists( "h3xload/server_id.txt", "DATA" ) then
			H3xLoad.ServerID = file.Read( "h3xload/server_id.txt", "DATA" )
		else
			H3xLoad.ServerID = new_random_id()
			file.Write( "h3xload/server_id.txt", H3xLoad.ServerID )
		end
		SetGlobalString( "H3xLoad_ServerID", H3xLoad.ServerID )
		return H3xLoad.ServerID
	elseif CLIENT then
		return GetGlobalString("H3xLoad_ServerID")
	end
end

function H3xLoad.GetCacheID()
	if SERVER then
		if H3xLoad.CacheID then return H3xLoad.CacheID end
		if file.Exists( "h3xload/cache_id.txt", "DATA" ) then
			H3xLoad.CacheID = file.Read( "h3xload/cache_id.txt", "DATA" )
			SetGlobalString( "H3xLoad_CacheID", H3xLoad.CacheID )
		end
		return H3xLoad.CacheID
	end
	
	return GetGlobalString("H3xLoad_CacheID")
end


function H3xLoad.CacheFileName()
	return "h3xload/cache/"..H3xLoad.GetServerID().."_"..H3xLoad.GetCacheID()..".gma.dat"
end

function H3xLoad.CompressedCacheFileName()
	return "h3xload/cache/"..H3xLoad.GetServerID().."_"..H3xLoad.GetCacheID()..".compressed.dat"
end