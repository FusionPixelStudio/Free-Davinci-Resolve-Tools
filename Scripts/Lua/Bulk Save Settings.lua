local fu = fu or Fusion()
local comp = fu.CurrentComp

if not fu or not comp then
    error("Please be in Fusion with an open composition")
    return
end

local allNodes = comp:GetToolList(true)

if #allNodes == 0 then
    error("Please select your nodes/macros before activating the script")
    return
end

local saveFolder = app:MapPath(app:RequestDir(
    '',
    {
        FReqS_Title = 'Choose Save Folder',
    }
))

if not saveFolder then
    print("No Save Folder Selected... Shutting Down")
    return
end

local failed = {}

function checkTool(tool)
    if tool.ID ~= "MediaOut" then
        return true
    else
        return false
    end
end

function saveTool(tool)
    local name = tool.Name
    local settings = comp:CopySettings(tool)
    if settings then
        local save = saveFolder .. name .. ".setting"
        print(save)
        local file = io.open(save, "w")
        if file then
            local success = file:write(bmd.writestring(settings))
            if not success then
                table.insert(failed, name)
            end
            file:close()
        end
    end
end

if #allNodes > 0 then
    for _, tool in ipairs(allNodes) do
        node = checkTool(tool)
        if node then
            saveTool(tool)
        end
    end
end

if #failed > 0 then
    print("Some nodes could not be saved: ")
    for _, node in ipairs(failed) do
        print(node)
    end
else
    print("All Nodes/Macros should be saved to " .. saveFolder)
end
