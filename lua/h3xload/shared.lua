
H3xLoad = {}
H3xLoad.Libs = {}
H3xLoad.Libs.BufferInterface = include( "libraries/bufferinterface.lua" )

file.CreateDir( "h3xload" )
file.CreateDir( "h3xload/cache/" )

function H3xLoad.GetServerID()
	if H3xLoad.ServerID then return H3xLoad.ServerID end

	if SERVER then
		if file.Exists( "h3xload/server_id.txt", "DATA" ) then
			H3xLoad.ServerID = file.Read( "h3xload/server_id.txt", "DATA" )
		else
			math.randomseed( os.time() )
			local valid_chars = "0123456789abcdefghijklmnopqrstuvwxyz"
			local new_serverid = {}
			for i=1, 8 do
				new_serverid[i] = valid_chars[math.random(1,36)] -- I'd be surprised if collision happens ( 1 / 2,821,109,907,456 )
			end
			H3xLoad.ServerID = table.concat(new_serverid)
			file.Write( "h3xload/server_id.txt", H3xLoad.ServerID )
		end
		SetGlobalString( "H3xLoad_ServerID", H3xLoad.ServerID )
	elseif CLIENT then
		return GetGlobalString("H3xLoad_ServerID")
	end
	return H3xLoad.ServerID
end

function H3xLoad.CacheFileName()
	return "h3xload/cache/"..H3xLoad.GetServerID()..".gma.dat"
end
function H3xLoad.CompressedCacheFileName()
	return "h3xload/cache/"..H3xLoad.GetServerID()..".compressed.dat"
end


function H3xLoad.GetServerCacheTimestamp( reload )
	if CLIENT then 
		return GetGlobalInt("H3xLoad_ServerCacheTimestamp")
	elseif SERVER then
		if not reload and H3xLoad.ServerCacheTimestamp then return H3xLoad.ServerCacheTimestamp end
		
		local fl = file.Open( H3xLoad.CacheFileName(), "rb", "DATA" )
		if not fl then return nil end

		fl:Seek(13)
		local timestamp = fl:ReadLong()
		fl:Close()

		H3xLoad.ServerCacheTimestamp = timestamp >= 0 and timestamp or timestamp + 0x100000000
		SetGlobalString( "H3xLoad_ServerCacheTimestamp", H3xLoad.ServerCacheTimestamp )

		return H3xLoad.ServerCacheTimestamp
	end

end