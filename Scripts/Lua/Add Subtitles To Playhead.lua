local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()
local mediaPool = project:GetMediaPool()
local timeline = project:GetCurrentTimeline()

local function ConvertTimecodeToFrame(timecode, fps) -- No Interlacing and No Dropped Frames Included
    local time_pieces = {}
    for str in string.gmatch(timecode, "(%d+)") do
        table.insert(time_pieces, str)
    end

    local rounded_fps = math.floor(fps + 0.5)

    local hours = tonumber(time_pieces[1])
    local minutes = tonumber(time_pieces[2])
    local seconds = tonumber(time_pieces[3])
    local frame = (hours * 60 * 60 + minutes * 60 + seconds) * rounded_fps
    local frame_count = tonumber(time_pieces[4])

    frame = frame + frame_count

    return frame
end

local function GetTimelineClipFromMediaPool(timeline_name, folder)
    local folder = folder or mediaPool:GetRootFolder()

    for i, clip in ipairs(folder:GetClipList()) do
        if clip:GetClipProperty("Type") == "Timeline" and
            clip:GetClipProperty("Clip Name") == timeline_name then
            return clip
        end
    end

    for _, subfolder in ipairs(folder:GetSubFolderList()) do
        local clip = GetTimelineClipFromMediaPool(timeline_name, subfolder)
        if clip ~= nil then
            return clip
        end
    end

    return nil
end

local function GetClipFromMediaPool(clip_name, folder)
    local folder = folder or mediaPool:GetRootFolder()

    for i, clip in ipairs(folder:GetClipList()) do
        if clip:GetClipProperty("Type") ~= "Timeline" and
            clip:GetClipProperty("Clip Name") == clip_name then
            return clip
        end
    end

    for _, subfolder in ipairs(folder:GetSubFolderList()) do
        local clip = GetClipFromMediaPool(clip_name, subfolder)
        if clip ~= nil then
            return clip
        end
    end

    return nil
end

local timeline_MP_Clip = GetTimelineClipFromMediaPool(timeline:GetName())
local fps = timeline_MP_Clip:GetClipProperty("FPS")

local currentFrame = ConvertTimecodeToFrame(timeline:GetCurrentTimecode(), fps)

local exampleClip = GetClipFromMediaPool("Subtitle 1")                                          -- Replace with your own Clip Name! You can also say the folder it is in with (Clipname, FolderName)
local exampleFPS = exampleClip:GetClipProperty("FPS")                                           -- Remove if not adding a Video Clip to timeline
local exampleDurr = ConvertTimecodeToFrame(exampleClip:GetClipProperty("Duration"), exampleFPS) -- Remove if not adding a Video Clip to timeline

local newClip = {}
newClip["mediaPoolItem"] = exampleClip
newClip["startFrame"] = 0                                              -- Start Frame within Clip
newClip["endFrame"] = exampleDurr - 1                                  -- End Frame within Clip
newClip["trackIndex"] = 3
newClip["recordFrame"] = currentFrame                                  -- Start Frame on timeline

local ExampleTimelineClip = mediaPool:AppendToTimeline({ newClip })[1] -- Add it to the timeline, and get the new timeline clip information

dump(ExampleTimelineClip)
