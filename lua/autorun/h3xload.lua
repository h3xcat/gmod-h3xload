
MsgN( "[H3xLoad] Initializing..." )
if SERVER then
    AddCSLuaFile( "h3xload/libraries/bufferinterface.lua" )

    AddCSLuaFile( "h3xload/config.lua" )
    AddCSLuaFile( "h3xload/shared.lua" )
    AddCSLuaFile( "h3xload/cl_init.lua" )
    AddCSLuaFile( "h3xload/file_net.lua" )
    
    include( "h3xload/shared.lua" )
    include( "h3xload/init.lua" )
    include( "h3xload/gma_writer.lua" )
    include( "h3xload/file_net.lua" )
elseif CLIENT then
    include( "h3xload/shared.lua" )
    include( "h3xload/cl_init.lua" )
    include( "h3xload/file_net.lua" )
end