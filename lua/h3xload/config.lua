local CONFIG = {}
--------------------------------------------------------------------------------
-- Resources that have been added with resource.AddFile or resource.AddSingleFile
CONFIG.RuntimeLoadLegacy = true
-- Resources that have been added with resource.AddWorkshop
CONFIG.RuntimeLoadWorkshop = true
--------------------------------------------------------------------------------
-- File URL, if this is set to anything, it will not attempt to send the GMA through net library. The only drawback of this is that whole file
-- must be loaded into Lua string, and if the file is really large, crashes(out of memory) are more prone.
CONFIG.FileNet_URL = ""
-- The size of single block size, which are compressed individually. Max 65527 bytes if sent through net library, aka, if URL is not set.
CONFIG.FileNet_BlockSize = 65500
-- If GMA sent through net. The number of blocks to send at once, per interval.
CONFIG.FileNet_BurstCount = 2
-- If GMA sent through net. Transmission interval in seconds.
CONFIG.FileNet_Interval = 2
--------------------------------------------------------------------------------
 -- Limit of how many resources client should load at single time, mainly applies to workshop addons
CONFIG.ClientLoadLimit = 10
--------------------------------------------------------------------------------
return CONFIG