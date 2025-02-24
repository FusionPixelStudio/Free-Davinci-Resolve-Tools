local fu = fu or Fusion()
local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)

local comp = fu:GetCurrentComp()

local AllMediaIns = comp:GetToolList(false, 'MediaIn')

if not AllMediaIns or #AllMediaIns == 0  then
    error("No MediaIns Found In Comp")
    return
end

local function isImg(extension)
    if extension then
        if  ( extension == ".png" ) or
            ( extension == ".bmp" ) or
            ( extension == ".exr" ) or
            ( extension == ".tiff" ) or
            ( extension == ".tif" ) or
            ( extension == ".dpx" ) or
            ( extension == ".jpeg" ) or
            ( extension == ".jpg" ) then
			return true
		end
	end
	return false
end

local function getFile(node)
    local filePath = node:GetAttrs().TOOLS_Clip_Path
    if not filePath then
        error("NO FILE FOUND IN "..node.Name)
        return nil
    else
        if bmd.fileexists(app:MapPath(filePath)) then
            return filePath
        end
    end
end

local function replaceMediaIn(filePath, node)
    local name = node.Name
    local flow = comp.CurrentFrame.FlowView
    x, y = flow:GetPos(node)
    local loader = comp:AddTool("Loader")
    loader.Clip = filePath
    flow:SetPos(loader, x, y)
    local inputs = node.Output:GetConnectedInputs()
    for i, input in ipairs(inputs) do
        input:ConnectTo(loader.Output)
    end
    node:Delete()
    if not string.find(name, "MediaIn") then
        loader:SetAttrs({ TOOLS_Name = name})
    end
end

------------------------------------------------------------------------------
-- parseFilename() from bmd.scriptlib | Also can be found in LoaderFromSaver Script by Alexey Bogomolov
--
-- this is a great function for ripping a filepath into little bits
-- returns a table with the following
--
-- FullPath	: The raw, original path sent to the function
-- Path		: The path, without filename
-- FullName	: The name of the clip w\ extension
-- Name     : The name without extension
-- CleanName: The name of the clip, without extension or sequence
-- SNum		: The original sequence string, or "" if no sequence
-- Number 	: The sequence as a numeric value, or nil if no sequence
-- Extension: The raw extension of the clip
-- Padding	: Amount of padding in the sequence, or nil if no sequence
-- UNC		: A true or false value indicating whether the path is a UNC path or not
------------------------------------------------------------------------------
local function parseFilename(filename)
	local seq = {}
	seq.FullPath = filename
	string.gsub(seq.FullPath, "^(.+[/\\])(.+)", function(path, name) seq.Path = path seq.FullName = name end)
	string.gsub(seq.FullName, "^(.+)(%..+)$", function(name, ext) seq.Name = name seq.Extension = ext end)

	if not seq.Name then -- no extension?
		seq.Name = seq.FullName
	end
	
	string.gsub(seq.Name,     "^(.-)(%d+)$", function(name, SNum) seq.CleanName = name seq.SNum = SNum end)
	
	if seq.SNum then
		seq.Number = tonumber( seq.SNum )
		seq.Padding = string.len( seq.SNum )
	else
		seq.SNum = ""
		seq.CleanName = seq.Name
	end
	
	if not seq.Extension then seq.Extension = "" end
	seq.UNC = ( string.sub(seq.Path, 1, 2) == [[\\]] )
	
	return seq
end

local function Go(MediaIns)
    for i, node in ipairs(MediaIns) do
        local filePath = parseFilename(getFile(node))
        if isImg(filePath.Extension) then
            replaceMediaIn(filePath.FullPath, node)
        end
    end
end

local function mainUI()
    local mainWin = disp:AddWindow({
        ID = 'MIntoLoader',
        TargetID = 'MIntoLoader',
        WindowTitle = 'MediaIns -> Loaders',
    
        Spacing = 0,
    
        ui:VGroup{
            ID = 'root',
            FixedSize = {225, 200},
            ui:VGroup{
                ui:Label{ Text = "Which Mode?", Alignment = { AlignCenter = true }, StyleSheet = [[color:'white'; font-size:15px]] },
                ui:Button{ ID = "ALL", Text = "All MediaIns" },
                ui:Button{ ID = "Selected", Text = "Selected MediaIns" }
            }
        }
    })

    function mainWin.On.ALL.Clicked(ev)
        comp:Lock()
        local AllMediaIns = comp:GetToolList(false, 'MediaIn')
        if not AllMediaIns or #AllMediaIns == 0  then
            error("No MediaIns Found In Comp")
            return
        end
        Go(AllMediaIns)
        comp:Unlock()
    end

    function mainWin.On.Selected.Clicked(ev)
        comp:Lock()
        local SelectedMediaIns = comp:GetToolList(true, 'MediaIn')
        if not SelectedMediaIns or #SelectedMediaIns == 0 then
            error("No MediaIns Selected")
            return
        end
        Go(SelectedMediaIns)
        comp:Unlock()
    end

    function mainWin.On.MIntoLoader.Close(ev)
        disp:ExitLoop()
    end

    mainWin:RecalcLayout()
    mainWin:Show()
    disp:RunLoop()
    mainWin:Hide()

end

mainUI()

collectgarbage()