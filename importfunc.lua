local exportScriptString = nil
function import()
    if not sourceResource or sourceResource == resource then
        return error("This function can only be called from another resource.")
    end
    if not exportScriptString then
        local f = fileOpen("class.lua", true)
        if not f then
            return error("Failed to open file.")
        end
        exportScriptString = fileGetContents(f, true) -- verifies checksum
        fileClose(f)
        if not exportScriptString or exportScriptString == "" then
            return error("Failed to read file.")
        end
    end
    return exportScriptString
end