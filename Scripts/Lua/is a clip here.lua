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

-- NEW STUFF

local function getTimelineClips(trackType)
    local trackCount = timeline:GetTrackCount(trackType)
    local clips = {}

    for i = 1, trackCount do
        local trackClips = timeline:GetItemListInTrack(trackType, i)
        if trackClips and #trackClips > 0 then
            table.insert(clips, trackClips)
        else
            timeline:DeleteTrack(trackType, i)
            clips = {}
            clips = getTimelineClips(trackType)
            if clips and #clips > 0 then
                return clips
            end
        end
    end
    return clips
end

local function isPlayheadOnClip(currentFrame, trackType)
    local trackCount = timeline:GetTrackCount(trackType)

    local clips = getTimelineClips(trackType)

    for trackIndex, track in ipairs(clips) do
        for _, clip in ipairs(track) do
            if currentFrame > clip:GetStart() and currentFrame < clip:GetEnd() then
                clipFound = true
                clipIndex = trackIndex
                break
            end
        end
    end
    if clipFound then
        return clipFound, clipIndex
    end
    return false , trackCount
end

local function isClippingClip(currentFrame, clip, trackNum, trackType)

    local clipStart = currentFrame
    local clipEnd = ConvertTimecodeToFrame(clip:GetClipProperty("Duration"), clip:GetClipProperty("FPS")) + currentFrame

    local trackClips = timeline:GetItemListInTrack(trackType, trackNum)

    for _, clip in ipairs(trackClips) do
        if clip:GetStart() > clipStart and clip:GetStart() < clipEnd then
            return true
        end
    end
    return false

end

local isPlayheadOnVideoClip, videoClipTrackIndex = isPlayheadOnClip(currentFrame, "video")
local isPlayheadOnAudioClip, auidoClipTrackIndex = isPlayheadOnClip(currentFrame, "audio")

local exampleClip = GetClipFromMediaPool("2024-10-04 20-45-14.mp4") -- Replace with your own Clip Name! You can also say the folder it is in with (Clipname, FolderName)
if exampleClip then
    
    local exampleFPS = exampleClip:GetClipProperty("FPS")
    local exampleDurr = ConvertTimecodeToFrame(exampleClip:GetClipProperty("Duration"), exampleFPS)

    local videoTrackCount = timeline:GetTrackCount("video")
    local auioTrackCount = timeline:GetTrackCount("audio")
    
    if videoClipTrackIndex < videoTrackCount then
        videoClipTrackIndex = videoClipTrackIndex + 1
    end

    if isPlayheadOnVideoClip and (videoClipTrackIndex == videoTrackCount) then
        timeline:AddTrack('video')
        videoClipTrackIndex = videoClipTrackIndex + 1
    else
        local isClippingVideoClip = isClippingClip(currentFrame, exampleClip, videoClipTrackIndex, "video")
        if isClippingVideoClip then
            timeline:AddTrack('video')
            videoClipTrackIndex = videoClipTrackIndex + 1
        end
    end
    
    if isPlayheadOnAudioClip and (auidoClipTrackIndex == auioTrackCount) then
        timeline:AddTrack('audio')
    else
        local isClippingAudioClip = isClippingClip(currentFrame, exampleClip, auidoClipTrackIndex, "audio")
        if isClippingAudioClip then
            timeline:AddTrack('audio')
        end
    end

    local trackNumber = videoClipTrackIndex

    local newClip = {}
    newClip["mediaPoolItem"] = exampleClip
    newClip["startFrame"] = 0
    newClip["endFrame"] = exampleDurr - 1
    newClip["trackIndex"] = trackNumber
    newClip["recordFrame"] = currentFrame

    local ExampleTimelineClip = mediaPool:AppendToTimeline({newClip})[1]

    dump(ExampleTimelineClip)

end