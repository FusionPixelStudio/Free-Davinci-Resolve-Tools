--[[
    Script File Creator V0.5
    Created by AsherRoland

    This tool quickly makes a Script File with your chosen name and file type. 
    Allowing you to then edit the file in Davinci Resolve.
]]

local ui = fu.UIManager;
local disp = bmd.UIDispatcher(ui); 

local win = disp:AddWindow(
	{
		ID = "OpenWin",
		WindowTitle = "Script Creator",
		Geometry = { 735,450,400,100 },

		ui:VGroup{
            ID = "root",
			ui:HGroup{
                ui:LineEdit{ ID = "FileName",
					PlaceholderText = "Please Enter the Script Name", 
					Weight = 1.5,
					MinimumSize = {200, 24} },
                ui:HGap(5),
                ui:ComboBox{
                    ID = "ext",
                    Text = "Extention" 
                },
                ui:HGap(5),
                ui:Button{ ID = "Create", Text = "Create" }, 
            },
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
        },
    }
)

local itm = win:GetItems()

--adds lables to the dropdown for folders
itm.Folder:AddItem('Color')
itm.Folder:AddItem('Comp')
itm.Folder:AddItem('Deliver')
itm.Folder:AddItem('Edit')
itm.Folder:AddItem('Tool')
itm.Folder:AddItem('Utility')
itm.Folder:AddItem('Views')
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

local folder = 1
local folders = {'Color','Comp','Deliver','Edit','Tool','Utility','Views'}

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
    Geometry = { 300,150,900,850 },

    ui:VGroup{
        ui.TextEdit{
            ID = 'editor',
            Text = fileContent,
            StyleSheet = [[color: rgb(255, 255, 255); background-color: rgb(26,26,26); ]]
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
		Geometry = { 785,475,300,100 },

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
		Geometry = { 785,475,300,100 },

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
		Geometry = { 785,475,300,100 },

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
    --[[
    if os_type == 'Windows_NT' then 
        print('Windows!')
        folder = itm.Folder.CurrentIndex + 1
        local appdata = os.getenv('APPDATA'); 
        file_path = appdata .. '\\Blackmagic Design\\DaVinci Resolve\\Support\\Fusion\\Scripts\\' .. folders[folder]; 
        fileContent = read_file(file_path .. (tostring(itm.FileName.Text)) .. txtext[ext])
    elseif os_type == 'Linux' then 
        print('Linux!')
        folder = itm.Folder.CurrentIndex + 1
        local home = os.getenv('HOME'); 
        file_path = home .. '/.local/share/DaVinciResolve/Fusion/Scrips/' .. folders[folder];
        fileContent = read_file(file_path ..'/'.. (tostring(itm.FileName.Text)) .. txtext[ext])
    else 
        print('Mac')
       folder = itm.Folder.CurrentIndex + 1
        local home = os.getenv('HOME'); 
        file_path = home .. '/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/'.. folders[folder];
        fileContent = read_file(file_path ..'/'.. (tostring(itm.FileName.Text)) .. txtext[ext])
    end
    ]]
    local ui = fu.UIManager
    app:NewScript("New Script")
    folder = itm.Folder.CurrentIndex + 1
    file_path = fusion:MapPath("Scripts:/" .. folders[folder])
    fileContent = read_file(file_path .. (tostring(itm.FileName.Text)) .. txtext[ext])
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