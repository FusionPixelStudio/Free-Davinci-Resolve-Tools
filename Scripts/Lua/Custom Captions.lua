local resolve = app:GetResolve()

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)

local Width = 350

local XSize = 25

local CancelCSS = [[
    QPushButton
    {
        border: 1px solid rgb(100,100,100);
        max-height: 26px;
        border-radius: 14px;
        color: rgb(150, 150, 150);
        min-height: 26px;
        font-size: 13px;
    }
    QPushButton:hover
    {
        border: 1px solid rgb(255,255,255);
        border-radius: 14px;
        color: rgb(255, 255, 255);
    }
]]

local CreateCSS = [[
    QPushButton
    {
        border: 1px solid rgb(255,80,80);
        max-height: 26px;
        border-radius: 14px;
        color: rgb(150, 150, 150);
        min-height: 26px;
        font-size: 13px;
    }
    QPushButton:hover
    {
        color: rgb(255, 255, 255);
    }
]]

local InputCSS = [[
    color: rgb(255, 255, 255);
]]

local RowCSS = [[
    margin: 2px;
]]

local generator = disp:AddWindow({
    ID = "CaptionsGenerator",
    WindowTitle = "Generate Captions",
    Margin = 15,
    ui:VGroup{
        ID = "root",
        Spacing = 4,
        FrameStyle = 2,
        ui:HGroup{
            StyleSheet = RowCSS,
            ui:Label{ Text = "Language", Alignment = {AlignVCenter = true, AlignRight = true}, FixedSize = { Width/2.5, XSize } },
            ui:ComboBox{ ID = "lang", FixedSize = { Width/1.75, XSize }, StyleSheet = InputCSS }
        },
        ui:HGroup{
            StyleSheet = RowCSS,
            ui:Label{ Text = "Caption Preset", Alignment = {AlignVCenter = true, AlignRight = true}, FixedSize = { Width/2.5, XSize } },                        
            ui:ComboBox{ ID = "preset", FixedSize = { Width/1.75, XSize }, StyleSheet = InputCSS }
        },
        ui:HGroup{
            StyleSheet = RowCSS,
            ui:Label{ Text = "Maximum Characters", Alignment = {AlignVCenter = true, AlignRight = true}, FixedSize = { Width/2.5, XSize } },       
            ui:SpinBox{ ID = "char_per_line", Suffix = " Per Line", Value = 42, FixedSize = { Width/3, XSize }, StyleSheet = InputCSS }
        },
        ui:HGroup{
            StyleSheet = RowCSS,
            ui:Label{ Text = "Lines", Alignment = {AlignVCenter = true, AlignRight = true}, FixedSize = { Width/2.5, XSize } }, 
            ui:ComboBox{ ID = "lines", FixedSize = { Width/1.75, XSize }, StyleSheet = InputCSS }
        },
        ui:HGroup{
            StyleSheet = RowCSS,
            ui:Label{ Text = "Gap Between Subtitles", Alignment = {AlignVCenter = true, AlignRight = true}, FixedSize = { Width/2.5, XSize } },
            ui:SpinBox{ ID = "gap_frames", Suffix = " Frames", FixedSize = { Width/3, XSize }, StyleSheet = InputCSS }
        },
        ui:Label{FixedY = 0},
        ui:HGroup{
            ui:Label{FixedX = Width/3},
            ui:Button{ ID = "Cancel", Text = "Cancel", FixedSize = { Width/3.25, XSize }, StyleSheet = CancelCSS },
            ui:Button{ ID = "Generate", Text = "Create", FixedSize = { Width/3.25, XSize }, StyleSheet = CreateCSS },
        },
    }
})

generator:Find('lang'):AddItems({"Auto", "Danish", "Dutch", "English", "French", "German", "Italian", "Japanese", "Korean", "Mandarin Simplified", "Mandarin Traditional", "Norwegian", "Portuguese", "Russian", "Spanish", "Swedish"})
generator:Find('preset'):AddItems({"Subtitle Default", "Teletext", "Netflix"})
generator:Find('lines'):AddItems({"Single", "Double"})

local languages = {
    resolve.AUTO_CAPTION_AUTO,
    resolve.AUTO_CAPTION_DANISH,
    resolve.AUTO_CAPTION_DUTCH,
    resolve.AUTO_CAPTION_ENGLISH,
    resolve.AUTO_CAPTION_FRENCH,
    resolve.AUTO_CAPTION_GERMAN,
    resolve.AUTO_CAPTION_ITALIAN,
    resolve.AUTO_CAPTION_JAPANESE,
    resolve.AUTO_CAPTION_KOREAN,
    resolve.AUTO_CAPTION_MANDARIN_SIMPLIFIED,
    resolve.AUTO_CAPTION_MANDARIN_TRADITIONAL,
    resolve.AUTO_CAPTION_NORWEGIAN,
    resolve.AUTO_CAPTION_PORTUGUESE,
    resolve.AUTO_CAPTION_RUSSIAN,
    resolve.AUTO_CAPTION_SPANISH,
    resolve.AUTO_CAPTION_SWEDISH
}

local presets = {
    resolve.AUTO_CAPTION_SUBTITLE_DEFAULT,
    resolve.AUTO_CAPTION_TELETEXT,
    resolve.AUTO_CAPTION_NETFLIX
}

local lines = {
    resolve.AUTO_CAPTION_LINE_SINGLE,
    resolve.AUTO_CAPTION_LINE_DOUBLE
}

function generator.On.Generate.Clicked(ev)
    generator:Find('CaptionsGenerator'):SetEnabled(false)
    local projectManager = resolve:GetProjectManager()
    local project = projectManager:GetCurrentProject()
    local timeline = project:GetCurrentTimeline()

    local lang = tonumber(generator:Find('lang').CurrentIndex) + 1
    local preset = tonumber(generator:Find('preset').CurrentIndex) + 1
    local char_per_line = tonumber(generator:Find('char_per_line').Value)
    local line = tonumber(generator:Find('lines').CurrentIndex) + 1
    local gap_frames = tonumber(generator:Find('gap_frames').Value)

    local startTime = os.clock()

    local captionSettings = { 
        [resolve.SUBTITLE_LANGUAGE] = languages[lang], 
        [resolve.SUBTITLE_CAPTION_PRESET] = presets[preset],
        [resolve.SUBTITLE_CHARS_PER_LINE] = char_per_line, 
        [resolve.SUBTITLE_LINE_BREAK] = lines[line], 
        [resolve.SUBTITLE_GAP] = gap_frames 
     }
     
     local captioned = timeline:CreateSubtitlesFromAudio(captionSettings)
    
    if captioned then
        local endTime = os.clock()
        print(string.format("Captions took %.2f seconds", endTime - startTime))
    else
        print("Failed To Generate")
    end
    generator:Find('CaptionsGenerator'):SetEnabled(true)
    disp:ExitLoop()
end

function generator.On.Cancel.Clicked(ev)
    disp:ExitLoop()
end

function generator.On.CaptionsGenerator.Close(ev)
    disp:ExitLoop()
end

generator:RecalcLayout()
generator:Show()
disp:RunLoop()
generator:Hide()