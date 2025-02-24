local DefFolder = app:MapPath('Scripts:/Utility/')

local fuPath = app:MapPath('Scripts:/')

-- Finds Script's Current File Path
local function script_path()
    return arg[0]
end

-- Checks if Script is in the Scripts folder, if not then return false
local function ScriptIsInstalled()
    local script_path = script_path()
    local match = script_path:find(fuPath)
    return match ~= nil
end

local SCRIPT_INSTALLED = ScriptIsInstalled()

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 300, 140

win = disp:AddWindow({
	ID = 'MyWin',
	TargetID = 'MyWin',
	WindowTitle = 'Flow To-Chapter',
    Geometry = {950, 500, width, height},

	Spacing = 0,

	ui:VGroup{
		ID = 'root',
		ui:VGroup {
		Weight = 0,
		ID = "main",
            ui:HGroup{
                ui:ComboBox { Weight = 0.75, ID = "TimelineCheck",StyleSheet = [[color:rgb(255,255,255)]]},
                ui:CheckBox { Weight = 0.25, ID = "IncludeHours", Text = "Include Hours", Tristate = false, StyleSheet = [[color:rgb(255,255,255)]]},
            },
            ui:VGap(3),
            ui:HGroup{
                ui:LineEdit { Weight = 0.75, ID = "FileLocation", ReadOnly = true, PlaceholderText = 'FilePath', StyleSheet = [[color:rgb(255,255,255)]]},
                ui:Button { Weight = 0.25, ID = "Browse", Text = "Browse", StyleSheet = [[color:rgb(255,255,255)]]}
            },
            ui:HGroup{
                ui:Label { Weight = 1, ID = "And/Or", Text = "And■/Or✔", Alignment = { AlignHCenter = true, AlignVCenter = true}, StyleSheet = [[color:rgb(255,255,255)]]},
                ui:CheckBox { Weight = 1, ID = "PrinttoConsole", Text = "Print to Console", Tristate = true, StyleSheet = [[color:rgb(255,255,255)]]},
            },
            ui:HGroup{
				ui:Button   { Weight = 1, ID = "Go", Text = "Go!", StyleSheet = [[color:rgb(255,255,255)]]}, 
			}, 
        }
    }
})

local winitm = win:GetItems()

local style = win:GetItems().TimelineCheck
style:AddItem("Use Timeline Markers")
style:AddItem("Use Clip Markers")

local function ConvertFrameToTimecode(frame, fps)
    local rounded_fps = math.floor(fps + 0.5)

    local seconds = math.fmod(math.floor(frame / rounded_fps), 60)
    local minutes = math.fmod(math.floor(math.floor(frame / rounded_fps) / 60), 60)
    local hours = math.floor(math.floor(math.floor(frame / rounded_fps) / 60) / 60)

    local frame_chars = string.len(tostring(rounded_fps - 1))
    local frame_divider = ":"

    if winitm.IncludeHours.CheckState == "Checked" then
        local format_string = "%02d:%02d" .. frame_divider .. "%0" .. frame_chars .. "d"
        return string.format(format_string, hours, minutes, seconds)
    else
        local format_string = "%02d" .. frame_divider .. "%0" .. frame_chars .. "d"
        return string.format(format_string, minutes, seconds)
    end
end

function GetAllMarkers(Index)
    local resolve = app:GetResolve()
    local projectManager = resolve:GetProjectManager()
    local project = projectManager:GetCurrentProject()
    local timeline = project:GetCurrentTimeline()

    local currentItems = timeline:GetItemListInTrack("video", 1)

    local OrderedKeys = {}
    
    local names = {}
    local frames = {}

    if Index == 0 then
        local TLMarkers = timeline:GetMarkers()
        local TLStringMarkers = bmd.writestring(TLMarkers) or ""

        for key in TLStringMarkers:gmatch("%s*%[%s*(%d+)%s*%]%s*=%s*{") do
            table.insert(OrderedKeys, tonumber(key))
        end
        for _, key in ipairs(OrderedKeys) do
            local value = TLMarkers[key]
            if value then
                for subKey, subValue in pairs(value) do
                    if subKey == "name" then
                        name = subValue
                    end
                end
                table.insert(names, name)
                table.insert(frames, key)
            else
                print("WARNING FOR "..key)
            end
        end
    elseif Index == 1 then
        local Markers = {}
        local OrderedKeys = {}

        -- Collect markers from items
        for _, item in ipairs(currentItems) do
            local markers = item:GetMarkers()
            for key, marker in pairs(markers) do
                if next(marker) ~= nil then  -- Check if the marker table is not empty
                    Markers[key] = marker
                end
            end
        end

        -- Convert markers to string
        local StringMarkers = bmd.writestring(Markers) or ""

        -- Extract and order keys
        for key in StringMarkers:gmatch("%s*%[%s*(%d+)%s*%]%s*=%s*{") do
            table.insert(OrderedKeys, tonumber(key))
        end
        table.sort(OrderedKeys)  -- Ensure keys are sorted

        -- Process markers based on ordered keys
        for _, key in ipairs(OrderedKeys) do
            local value = Markers[key]
            if value then
                if value.name then
                    name = value.name
                else
                    print("No name found for marker with key: " .. key)
                end
                table.insert(names, name)
                table.insert(frames, key)
            else
                print("WARNING FOR " .. key)
            end
        end
    end
    return names, frames
end

function ConverttoTimecode(Frames, fps)
    local timecodes = {}
    for v, i in ipairs(Frames) do
        local timecode = ConvertFrameToTimecode(i, fps)
        table.insert(timecodes, timecode)
    end
    return timecodes
end

function win.On.Browse.Clicked(ev)
    local timelineName = timeline:GetName()
    local path = fusion:RequestFile(
    '',
    timelineName..".txt",
    {
        FReqB_Saving = true,
        FReqB_SeqGather = false,
        FReqS_Filter = 'TXT File (*.txt)|*.txt',
        FReqS_Title = 'Open Image',
    }
    )

    winitm.FileLocation.Text = path
end

function SaveControls()
    fusion:SetData("ToChapter_Tml", winitm.TimelineCheck.CurrentIndex)
    fusion:SetData("ToChapter_Hrs", winitm.IncludeHours.CheckState)
    fusion:SetData("ToChapter_File", winitm.FileLocation.Text)
    fusion:SetData("ToChapter_Print", winitm.PrinttoConsole.CheckState)
end

function win.On.Go.Clicked(ev)
    SaveControls()
    local resolve = app:GetResolve()
    local projectManager = resolve:GetProjectManager()
    local project = projectManager:GetCurrentProject()
    local timeline = project:GetCurrentTimeline()
    local Framerate = timeline:GetSetting("timelineFrameRate")
    -- print(winitm.PrinttoConsole.CheckState)
    local Names, Frames = GetAllMarkers(winitm.TimelineCheck.CurrentIndex)
    local Timecodes = ConverttoTimecode(Frames, Framerate)

    local FilePath = winitm.FileLocation.Text or ""

    if winitm.PrinttoConsole.CheckState == "PartiallyChecked" then
        local file = io.open(FilePath, 'a')
        for v, _ in ipairs(Names) do
            file:write(Timecodes[v].. " " .. Names[v].."\n")
        end
        file:close()
        for v, _ in ipairs(Names) do 
            print(Timecodes[v].. " " .. Names[v])
        end
        print(FilePath)
    elseif winitm.PrinttoConsole.CheckState == "Checked" then
        for v, _ in ipairs(Names) do
            print(Timecodes[v].. " " .. Names[v])
        end
    elseif winitm.PrinttoConsole.CheckState == "Unchecked" then
        local file = io.open(FilePath, 'a')
        for v, _ in ipairs(Names) do
            file:write(Timecodes[v].. " " .. Names[v].."\n")
        end
        file:close()
        print(FilePath)
    end
    disp:ExitLoop()
end

function win.On.MyWin.Close(ev)
    SaveControls()
	disp:ExitLoop()
end

local InstallWindow = disp:AddWindow(
    {
        ID = "installwin",
        WindowTitle = "Install",
        Geometry = { 950,400,250,50 },
        ui:VGroup{
            ID = "root",
            ui:VGroup{
                ui:Label{ID = 'Title1', Text = 'Script Not Installed', Weight = 0.15, MinimumSize = { 250, 20 }, FixedY = 20, WordWrap = true, Alignment = {AlignHCenter = true, AlignTop = true}, StyleSheet = [[font-size: 12px;color:rgb(200,200,200);font-weight: light;]]},
                    ui:Button{ID = 'Install', Text = 'Install', Weight = 0.15, MinimumSize = { 50, 25 },  FixedY = 25, StyleSheet = [[color:rgb(255,255,255);font-weight: light;]]},
                },
            },  
        }
)

local function InstallScript() 
    local source_path = script_path()

    local scriptstring = io.open(source_path, "r"):read("*all")
    local success = io.open(DefFolder.."Flow To-Chapter.lua", "w"):write(scriptstring)

    if not success then
        print("Failed to Install","Failed to install\nPlease manually move to the %APPDATA%/Blackmagic Design/Davinci Resolve/Fusion/Scripts/Utility")
        return false
    end
    return true
end

local function SetsControls()
    local tml = fusion:GetData("ToChapter_Tml")
    local hrs = fusion:GetData("ToChapter_Hrs")
    local file = fusion:GetData("ToChapter_File")
    local prnt = fusion:GetData("ToChapter_Print")

    winitm.TimelineCheck.CurrentIndex = tml or 0
    winitm.IncludeHours.CheckState = hrs or "Unchecked"
    winitm.FileLocation.Text = file or ""
    winitm.PrinttoConsole.CheckState = prnt or "PartiallyChecked"
end

if SCRIPT_INSTALLED == false then
    local itm = InstallWindow:GetItems()

    function InstallWindow.On.installwin.Close(ev)
        disp:ExitLoop()
    end

    function InstallWindow.On.Install.Clicked(ev)
        InstallScript()
        disp:ExitLoop()
    end

    InstallWindow:RecalcLayout()
    InstallWindow:Show()
    disp:RunLoop()
    InstallWindow:Hide()
    print("INSTALLED")
else
    SetsControls()
    win:Show()
    disp:RunLoop()
    win:Hide()
end