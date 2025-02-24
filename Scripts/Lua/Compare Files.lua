local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)

local mainFolder = app:MapPath(app:RequestDir(
    "",
    {
        FReqS_Title = 'Choose Your First Folder',
    }
))

local proxyFolder = app:MapPath(app:RequestDir(
    "",
    {
        FReqS_Title = 'Choose Your Second Folder',
    }
))

if not bmd.direxists(mainFolder) then
    error("MAIN FOLDER NOT FOUND")
    return
else
    print(mainFolder)
end

if not bmd.direxists(proxyFolder) then
    error("COULD NOT FIND 2nd FOLDER")
    return
else
    print(proxyFolder)
end

local platform = (FuPLATFORM_WINDOWS and "Windows") or
                 (FuPLATFORM_MAC and "Mac") or
                 (FuPLATFORM_LINUX and "Linux")

-- Function to list all files in a folder
local function listFiles(folder)
    local files = {}

    -- Determine the command based on the platform
    local command = platform == 'Windows' and ('dir "' .. folder .. '" /b /a-d') or ('ls -p "' .. folder .. '" | grep -v /')

    -- Execute the command silently and capture the output
    local handle = io.popen(command)
    if handle then
        for file in handle:lines() do
            table.insert(files, folder .. "/" .. file)
        end
        handle:close()
    end
    if not files[1] then
        error("NO FILE FOUND IN "..folder) 
        return nil
    end
    return files
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
function parseFilename(filename)
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

local mainVideos = listFiles(mainFolder)
local proxyVideos = listFiles(proxyFolder)

local win = disp:AddWindow({
    ID = "dupeFolderCheck",
    WindowTitle = "Check for Duplicates?",

    ui:VGroup{
        ID = "root",
        FixedSize = { 600, 100 },
        ui:HGroup{
            ID = "Buttons",
            ui:Button{ ID = "Yes", Text = "Yes", Weight = 0.5 },
            ui:Button{ ID = "No", Text = "No", Weight = 0.5 },
        },
        ui:VGroup{
            ID = "Hidden",
            Hidden = true,
            ui:ComboBox{ ID = "Folder", Text = "Which Folder?" },
            ui:Button{ ID = "Run", Text = "Run" },
        }
    }
})

win:Find('Folder'):AddItem(mainFolder)
win:Find('Folder'):AddItem(proxyFolder)

function win.On.No.Clicked(ev)
    disp:ExitLoop()
end

function win.On.Yes.Clicked(ev)
    win:Find("Hidden").Hidden = false
    win:Find("Buttons").Hidden = true
    win:RecalcLayout()
end

local dupCheck = nil
local dupCheckName = nil

function win.On.Run.Clicked(ev)
    if win:Find('Folder').CurrentIndex == 0 then        
        dupCheck = mainVideos
        dupCheckName = mainFolder
    elseif win:Find('Folder').CurrentIndex == 1 then
        dupCheck = proxyVideos
        dupCheckName = proxyFolder
    end
    disp:ExitLoop()
end

function win.On.dupeFolderCheck.Close(ev)
    disp:ExitLoop()
end

win:RecalcLayout()
win:Show()
disp:RunLoop()
win:Hide()

function findDuplicates(tbl, folderName)
    print("--------------------------------------------------")
    print("Files With Duplicate Names in '"..folderName.."'")
    local itemCount = {}
    local duplicates = {}

    -- Count occurrences of each item
    for _, item in ipairs(tbl) do
        itemCount[parseFilename(item).Name] = (itemCount[parseFilename(item).Name] or 0) + 1
    end

    -- Collect items that occur more than once
    local i = 1
    for item, count in pairs(itemCount) do
        if count > 1 then
            print("- "..i)
            print("- "..item)
            print("- Duplicates: "..count)
            table.insert(duplicates, item)
            i = i + 1
            print("-------------------")
        end
    end

    return duplicates
end

function getNonMatchingItems(table1, table2)
    local itemsInTable2 = {}
    local nonMatchingItems = {}

    print("--------------------------------------------------")
    print("Files in Second Folder")
    print("Count: "..#table2)
    -- Create a set of items from table2 for quick lookup
    for _, item in ipairs(table2) do
        print(parseFilename(item).FullName)
        itemsInTable2[parseFilename(item).Name] = true
    end

    print("--------------------------------------------------")
    print("Files in First Folder")
    print("Count: "..#table1)
    -- Check each item in table1 to see if it's not in table2
    for _, item in ipairs(table1) do
        print(parseFilename(item).FullName)
        if not itemsInTable2[parseFilename(item).Name] then
            table.insert(nonMatchingItems, parseFilename(item).FullName)
        end
    end

    return nonMatchingItems
end

local missingProxies = getNonMatchingItems(mainVideos, proxyVideos)

if dupCheckName then
    findDuplicates(dupCheck, dupCheckName)
end

print("--------------------------------------------------")
if #missingProxies ~= 0 then
    print("Files From Folder 1 Without Duplicate Names in Folder 2")
    for i, file in ipairs(missingProxies) do
        print(i..": "..file)
    end
else
    print("NO FILES MISSING")
end

