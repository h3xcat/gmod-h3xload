if not SERVER then return end
--------------------------------------------------------------------------------
local file_Find = file.Find
local string_match = string.match
local pairs = pairs
local ipairs = ipairs
local file_Exists = file.Exists
local file_IsDir = file.IsDir
--------------------------------------------------------------------------------
local resource_whitelist = {
	["ain"] = true,
	["ani"] = true,
	["bsp"] = true,
	["ico"] = true,
	["jpg"] = true,
	["mdl"] = true,
	["mp3"] = true,
	["pcf"] = true,
	["phy"] = true,
	["png"] = true,
	["res"] = true,
	["ttc"] = true,
	["ttf"] = true,
	["txt"] = true,
	["vmt"] = true,
	["vtf"] = true,
	["vtx"] = true,
	["vvd"] = true,
	["vvd"] = true,
	["wav"] = true,
	["ztmp"] = true,
}
--------------------------------------------------------------------------------
local Config = include("config.lua")
--------------------------------------------------------------------------------
resource.OldAddSingleFile = resource.AddSingleFile
resource.OldAddFile = resource.AddFile

local resources_l = {}

function resource.GetList( )
	local copy = {}
	for k, v in ipairs(resources_l) do
		copy[k] = v
	end
	return copy
end

if Config.RuntimeLoadLegacy then
	function resource.AddFile( path )
		if not file_Exists(path, "GAME") or file_IsDir(path, "GAME") then
			resource.OldAddFile( path )
			return
		end

		resource.AddSingleFile( path )

		-- Lookup for other files, that are named the same, but with different extensions
		local stripped_ext_path = string_match(path, "^(.+%.)%w+$") or path
		if not stripped_ext_path then return end

		local dir = string_match( path, "^(.*[/\\])[^/\\]-$" ) or ""
		for k, fl in pairs( file_Find( stripped_ext_path.."*", "GAME" ) ) do
			resource.AddSingleFile( dir..fl )
		end
	end

	function resource.AddSingleFile( path )
		if not file_Exists(path, "GAME") or file_IsDir(path, "GAME") then
			resource.OldAddSingleFile( path )
			return
		end

		local ext = path:match( "%.([^%.]+)$" ) or ""
		if resource_whitelist[ext] then
			resources_l[#resources_l + 1] = path
		else
			resource.OldAddSingleFile( path )
		end
	end
end
--------------------------------------------------------------------------------
resource.OldAddWorkshop = resource.AddWorkshop
local resources_ws = {}

function resource.GetWSList( )
	local copy = {}
	for k, v in ipairs(resources_ws) do
		copy[k] = v
	end
	return copy
end

if Config.RuntimeLoadWorkshop then
	function resource.AddWorkshop( workshopid )
		resources_ws[#resources_ws + 1] = workshopid
	end
end