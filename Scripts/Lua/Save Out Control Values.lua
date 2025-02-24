local fu = fu or Fusion()
local comp = comp or fu.CurrentComp

local control = comp:AskUser("Choose Control",
    { { "Node Name", "Text", Default = "XYPath1" }, { "Control ID", "Text", Default = "X" } })

local tool = comp:FindTool(control["Node Name"])

local controlID = tool[control["Control ID"]]

local compAttrs = comp:GetAttrs()

local allFrameValues = {}

for i = compAttrs.COMPN_RenderStart, compAttrs.COMPN_RenderEnd do
    table.insert(allFrameValues, controlID[i])
end

local function saveValues(path)
    local file = io.open(path, 'w')
    if file then
        for f, value in ipairs(allFrameValues) do
            if type(value) ~= "table" then
                local success = file:write(value .. "\n")
                if not success then
                    return false, f
                end
            else
                for i, v in ipairs(value) do
                    if i ~= #value then
                        local success = file:write(v .. ", ")
                        if not success then
                            return false, f
                        end
                    else
                        local success = file:write(v)
                        if not success then
                            return false, f
                        end
                    end
                end
                local success = file:write("\n")
                if not success then
                    return false, f
                end
            end
        end
        file:close()
    else
        return false, "permissions issue"
    end
    return true
end

if #allFrameValues > 0 then
    local path = app:MapPath(app:RequestFile(
        '',
        control["Node Name"] .. '_' .. control["Control ID"] .. " Values",
        {
            FReqB_Saving = true,
            FReqB_SeqGather = false,
            FReqS_Filter = 'TXT File (*.txt)|*.txt',
            FReqS_Title = 'Choose Where to Save Control\'s Values',
        }
    ))
    if path then
        local success, fail = saveValues(path)
        if success then
            print("Saved Control Values to " .. path)
        else
            print("Could Not Save Controls... Failed at: " .. fail)
        end
    end
end
