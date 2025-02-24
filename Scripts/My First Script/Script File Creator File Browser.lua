--[[
    Script File Creator V0.5
    Created by AsherRoland

    This tool quickly makes a Script File with your chosen name and file type. 
    Allowing you to then edit the file in Davinci Resolve.
]]

--local pathmaps = comp:GetCompPathMap(false,true)

local folder_list={}
local path = comp:MapPath("Scripts:/*.*")
local dir = readdir(path)

local ffi = require("ffi")
local table = require("table")
require("string")

local ui = fu.UIManager;
local disp = bmd.UIDispatcher(ui); 

local width, height = 400,100
local hPos, vPos = 735,450

local win = disp:AddWindow(
	{
		ID = "OpenWin",
		WindowTitle = "Script Creator",
		Geometry = { hPos,vPos,width+50,height+200 },
        MinimumSize = {200, 24},

		ui:VGroup{
            ID = "root",
            ui:HGroup{
            Weight = 0.98,
            ui:Tree{ID = 'Paths', SortingEnabled=true, Events = { ItemClicked=true }, Weight = 0.25},
			ui:Tree{ID = 'Files', SortingEnabled=true, Events = { ItemDoubleClicked=true }, Weight = 0.50},
            },
			ui:HGroup{
                Weight = 0.15,
                ui:LineEdit{ ID = "FileName",
					PlaceholderText = "Enter New Script Name", 
					Weight = .15, 
                    --[[
                    StyleSheet = [[
                        min-height: 5px,
                        max-height: 10px,
                        max-width: 95px,
                    ]]
                    --]]
                },
                ui:HGap(5),
                ui:ComboBox{
                    ID = "ext",
                    Text = "Extention" ,
                    Weight = 0.05
                },
                ui:HGap(5),
                ui:Button{ ID = "Create", Text = "Create", Weight = 0.05 }, 
            },
            --[[
            ui:HGroup{
                ui:Label{
                    ID = 'L',
                    Text = 'Where To Send It?' 
                },
            },
            ui:HGroup{
                ui:ComboBox{
                    ID = "Folder",
                    Text = "Select Script Type" 
                },
            }
            ]]
        },
    }
)

local itm = win:GetItems()

local File

local function iterateDirFiles(pathto)
	local fi = bmd.readdir(pathto.. "*")
    itm = win:GetItems()
    --print(fi)

	for k, v in pairs(fi) do
        if type(v) ~= "table" then
            goto continue
        end

        for _, File in pairs(v) do
            if type(File) ~= "string" then
               goto continue
            end
            --print(File)
            local it = itm.Files:NewItem()
            it.Text[0] = File
            itm.Files:AddTopLevelItem(it)

            ::continue::
        end

        ::continue::
	end	
end 

local filepath

function win.On.Paths.ItemClicked(ev)
	-- If the Paths are clicked then we should populate Files with every
	-- file we can iterate under that folder directory
    SelectedFolder = string.sub(ev.item.Text[0], 0, string.find(ev.item.Text[0], " ") - 1)

	itm = win:GetItems()
	itm.Files:Clear()
	filepath = fusion:MapPath("Scripts:/")
	filepath = string.gsub(filepath, "\\", "/")

	iterateDirFiles(filepath.. '/'.. SelectedFolder.. "/")
end

local files = {}

--[[
--adds lables to the dropdown for folders
itm.Folder:AddItem('Color')
itm.Folder:AddItem('Comp')
itm.Folder:AddItem('Deliver')
itm.Folder:AddItem('Edit')
itm.Folder:AddItem('Tool')
itm.Folder:AddItem('Utility')
itm.Folder:AddItem('Views')
]]

hdr = itm.Paths:NewItem()
hdr.Text[0] = 'Folders'
itm.Paths:SetHeaderItem(hdr)
itm.Paths.ColumnCount = 1

hdr2 = itm.Files:NewItem()
hdr2.Text[0] = 'Name'
itm.Files:SetHeaderItem(hdr2)
itm.Files.ColumnCount = 1
itm.Files.ColumnWidth[0] = 150

num = table.getn(dir)  
 for i = 1,num do 
    if dir[i].IsDir == 1 then
         str = "[DIR]"
         else
             str = dir[i].Size 
              end   
             table.insert(folder_list,(string.format("%-40s %10s", dir[i].Name, str)))
             end
             --dump(folder_list)
             
for k, v in pairs(folder_list) do
	it = itm.Paths:NewItem()
	it.Text[0] = v
	itm.Paths:AddTopLevelItem(it)
end

--adds lables to the dropdown for file types
itm.ext:AddItem('.lua')
itm.ext:AddItem('.py')

local fileContent = "This is a placeholder"

local function read_file(path)
    local file

    local Success= pcall(function() -- boolean 
        file = assert(io.open(path,"rb"))
    end)

    if not Success then
        return ""
    end

    if not file then
        return ""
    end

    local content = file:read('*all')
    file:close()

    return content
end

local ext = 1
local txtext = {'.lua','.py'}

function win.On.ext.CurrentIndexChanged(ev)
    ext = itm.ext.CurrentIndex + 1
end

local os_type = os.getenv('OS');

local appdata = os.getenv('APPDATA');
local file_path = appdata .. '\\Desktop'
--[[
function win.On.Folder.CurrentIndexChanged(ev)
    folder = itm.Folder.CurrentIndex + 1
    file_path = appdata .. '\\Blackmagic Design\\DaVinci Resolve\\Support\\Fusion\\Scripts\\' .. folders[folder]
    fileContent = read_file(file_path .. (tostring(itm.FileName.Text)) .. txtext[ext])
end
]]

local function file_exists(path) 
    local f = io.open(path, 'r'); 
    
    if f then 
        f:close(); 
        return true; 
    else 
        return false; 
    end 
end; 

local edit = disp:AddWindow({
    ID = "EditWin",
    WindowTitle = "Script Creator | File Editing",
    Geometry = { hPos-185,vPos-300,width+500,height+750 }, 

    ui:VGroup{
        ui.TextEdit{
            ID = 'editor',
            Text = fileContent,
            StyleSheet = [[color: rgb(255, 255, 255); background-color: rgb(26,26,26); ]],
            Lexer = 'fusion',
        },
        ui:HGroup{
            ui:Button{
                ID = 'Save',
                Text = 'Save',
                StyleSheet = [[
                    max-height: 28px;
                    min-height: 28px;
                    font-size: 13px;
                ]]
                },
                ui:Button{
                    ID = 'Test',
                    Text = 'Save and Test',
                    StyleSheet = [[
                        max-height: 28px;
                        min-height: 28px;
                        font-size: 13px;
                    ]]
                    },
            ui:Button{
                ID = 'SaveNClose',
                Text = 'Save and Close',
                StyleSheet = [[
                    max-height: 28px;
                    min-height: 28px;
                    font-size: 13px;
                ]]
                },
        },
    }})
    
EditContent = edit:GetItems()

local suc = disp:AddWindow(
	{
		ID = "SuccessWin",
		WindowTitle = "Script Creator | Success",
		Geometry = { hPos+50,vPos+25,width-100,height }, 

		ui:VGroup{
            ID = "root_success",
                ui:Label{
                    ID = 'S',
                    Text = 'Successfully Created Your File',
                    WordWrap = true,
                    Alignment = { AlignCenter = true},
                    StyleSheet = [[
                    QLabel {
                        color: rgb(255, 255, 255);
                        font-size: 40;
                        font-weight: bold;
                    }
                ]]
                },
                ui:VGap(0, 1),
                ui:HGroup{
                ui:Button{
                    ID = 'OK',
                    Text = 'OK',
                    },
                ui:HGroup{
                ui:Button{
                    ID = 'Edit',
                    Text = 'Edit File',
                    },
                }
                }
            },
        }
)

function suc.On.SuccessWin.Close(ev) disp:ExitLoop() end
function suc.On.OK.Clicked(ev) disp:ExitLoop() end

local warn = disp:AddWindow(
	{
		ID = "WarningWin",
		WindowTitle = "Script Creator | Duplicate",
		Geometry = { hPos+50,vPos+25,width-100,height },

		ui:VGroup{
            ID = "root_warning",
                ui:Label{
                    ID = 'W',
                    Text = 'FILE ALREADY EXISTS',
                    WordWrap = true,
                    Alignment = { AlignCenter = true},
                    StyleSheet = [[
                    QLabel {
                        color: rgb(255, 255, 255);
                        font-size: 40;
                        font-weight: bold;
                    }
                ]]
                },
                ui:Label{
                    ID = 'Q',
                    Text = 'What do you want to do?',
                    WordWrap = true,
                    Alignment = { AlignCenter = true},
                    StyleSheet = [[
                    QLabel {
                        color: rgb(255, 255, 255);
                        font-size: 40;
                    }
                ]]
                },
                ui:VGap(0, 1),
                ui:HGroup{
                ui:Button{
                    ID = 'update',
                    Text = 'Update File',
                    },
                ui:Button{
                    ID = 'rename',
                    Text = 'Rename File',
                     },
                }
            },
        }
)

function warn.On.WarningWin.Close(ev) disp:ExitLoop() end
function warn.On.rename.Clicked(ev) disp:ExitLoop() end

local nofile = disp:AddWindow(
	{
		ID = "NilWin",
		WindowTitle = "Script Creator | No File",
		Geometry = { hPos+50,vPos+25,width-100,height },

		ui:VGroup{
            ID = "root_warning",
                ui:Label{
                    ID = 'W',
                    Text = 'NO FILE BY THAT NAME',
                    WordWrap = true,
                    Alignment = { AlignCenter = true},
                    StyleSheet = [[
                    QLabel {
                        color: rgb(255, 255, 255);
                        font-size: 40;
                        font-weight: bold;
                    }
                ]]
                },
                ui:VGap(0, 1),
                ui:HGroup{
                ui:Button{
                    ID = 'OK',
                    Text = 'OK',
                    },
                }
            },
        }
)

function nofile.On.NilWin.Close(ev) disp:ExitLoop() end
function nofile.On.OK.Clicked(ev) disp:ExitLoop() end

function win.On.Create.Clicked(ev)
    if filepath == nil then
        print("No Filepath Selected!")
    end
    file_path = (filepath.. '/'.. SelectedFolder.. "/")
    if file_exists(file_path .. (tostring(itm.FileName.Text)) .. txtext[ext]) then
        warn:Show()
        disp:RunLoop()
        warn:Hide()
    else 
        local file_name = (tostring(itm.FileName.Text)) .. txtext[ext]
        local filepath = (tostring(file_path .. file_name))
        local file = io.open(filepath, "w")

        if not file then
            print("File is nil!")
            return
        end

        file:write('')
        file:close()
        print(filepath..' was created!')
        suc:Show()
    
        disp:RunLoop()
    
        suc:Hide()
        fileContent = read_file(file_path .. (tostring(itm.FileName.Text)) .. txtext[ext])
    end; 
end

function win.On.FileName.TextChanged(ev)
    fileContent = read_file(file_path .. (tostring(itm.FileName.Text)) .. txtext[ext])
end

function win.On.Files.ItemDoubleClicked(ev) 
    --print(ev.item.Text[0])
    SelectedFile = (ev.item.Text[0])
    fileContent = read_file(filepath.. '/'.. SelectedFolder.. "/"..SelectedFile)
    --fileContent = read_file()
    EditContent.editor.PlainText = fileContent

    --disp:ExitLoop() -- Exit last loop (warning window)
    edit:Show()
end

function warn.On.update.Clicked(ev)
    if not fileContent then
        nofile:Show()
    
        disp:RunLoop()
    
        nofile:Hide()
    else
        fileContent = read_file(file_path .. (tostring(itm.FileName.Text)) .. txtext[ext])
        EditContent.editor.PlainText = fileContent

        disp:ExitLoop() -- Exit last loop (warning window)
        edit:Show()
    end
end
function edit.On.Save.Clicked(ev)
    local document = io.open((file_path .. (tostring(itm.FileName.Text)) .. txtext[ext]),'w')

    if not document then
        return
    end
    document:write(EditContent.editor.PlainText)
    document:close()
            
end

function edit.On.Test.Clicked(ev)
    local document = io.open((file_path .. (tostring(itm.FileName.Text)) .. txtext[ext]),'w')

    if not document then
        return
    end

    document:write(EditContent.editor.PlainText)
    document:close()
    comp:Execute(tostring(EditContent.editor.PlainText))
end

function edit.On.SaveNClose.Clicked(ev)
    local document = io.open((file_path .. (tostring(itm.FileName.Text)) .. txtext[ext]),'w')

    if not document then
        return
    end

    document:write(EditContent.editor.PlainText)
    document:close()
    disp:ExitLoop() -- Exit last loop (Edit and the main window)
end

function edit.On.EditWin.Close(ev)
    fileContent = ''
    disp:ExitLoop() -- Exit last loop (Edit and the main window)
end

function suc.On.Edit.Clicked(ev)
    fileContent = read_file(file_path .. (tostring(itm.FileName.Text)) .. txtext[ext])
    EditContent.editor.PlainText = fileContent
    disp:ExitLoop() -- Exit last loop (Success Window)
    
    edit:Show()    
    
end

function win.On.OpenWin.Close(ev)
	disp:ExitLoop() -- Exit last loop (Edit and the main window)
end

win:Show()
disp:RunLoop()
win:Hide()

collectgarbage()