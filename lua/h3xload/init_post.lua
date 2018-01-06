if not SERVER then return end
--------------------------------------------------------------------------------
local file_Find = file.Find
local string_match = string.match
local pairs = pairs
local ipairs = ipairs
local file_Exists = file.Exists
local file_IsDir = file.IsDir
--------------------------------------------------------------------------------
resource.OldAddSingleFile = resource.AddSingleFile
resource.OldAddFile = resource.AddFile
resource.OldAddWorkshop = resource.AddWorkshop

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
local resources_l = {}
local resources_ws = {}

function resource.GetList( )
	local copy = {}
	for k, v in ipairs(resources_l) do
		copy[k] = v
	end
	return copy
end

function resource.GetWSList( )
	local copy = {}
	for k, v in ipairs(resources_ws) do
		copy[k] = v
	end
	return copy
end

function resource.AddFile( path )
	if not file_Exists(path, "GAME") or file_IsDir(path, "GAME") then
		ErrorNoHalt("resource.AddFile: Attempt to add invalid file "..path)
		return
	end

	resource.AddSingleFile( path )

	local stripped_ext_path = string_match(path, "^(.+%.)%w+$") or path
	if not stripped_ext_path then return end

	local dir = string_match( path, "^(.*[/\\])[^/\\]-$" ) or ""
	for k, fl in pairs( file_Find( stripped_ext_path.."*", "GAME" ) ) do
		resource.AddSingleFile( dir..fl )
	end
end

function resource.AddSingleFile( path )
	if not file_Exists(path, "GAME") or file_IsDir(path, "GAME") then
		ErrorNoHalt("resource.AddFile: Attempt to add invalid file "..path)
		return
	end
	local ext = path:match( "%.([^%.]+)$" ) or ""
	if resource_whitelist[ext] then
		resources_l[#resources_l + 1] = path
	else
		resource.OldAddFile( path )
	end
end

function resource.AddWorkshop( workshopid )
	resources_ws[#resources_ws + 1] = workshopid
end