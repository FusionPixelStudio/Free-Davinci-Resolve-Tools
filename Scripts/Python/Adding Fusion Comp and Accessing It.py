
#!/usr/bin/env python

import math     # Required for Converting Frames to Timecode for moving Play head

resolve = bmd.scriptapp('Resolve')
project_manager = resolve.GetProjectManager()
project = project_manager.GetCurrentProject()
timeline = project.GetCurrentTimeline()

exampleMarker = {
    1000: { # Frame that Marker is placed
        'color': 'Blue',
        'customData': '',
        'duration': 1,
        'name': 'Hero Kc Jh S.Blind',
        'note': ''
    }
}

def convert_frame_to_timecode(frame, fps, is_drop_frame=False, is_interlaced=False): # Found in Snap Captions, Converted to Python from Lua
    """
    Convert a frame number to a timecode string.

    Args:
        frame (int or float): The frame number.
        fps (int or float): Frames per second.
        is_drop_frame (bool, optional): Whether to use drop-frame timecode. Defaults to False.
        is_interlaced (bool, optional): Whether the source is interlaced. Defaults to False.

    Returns:
        str: The formatted timecode string.
    """
    # Round fps to the nearest integer.
    rounded_fps = math.floor(fps + 0.5)

    if is_drop_frame:
        # Calculate the number of dropped frames per minute and per ten minutes.
        dropped_frames = math.floor(fps / 15 + 0.5)
        frames_per_ten = math.floor(fps * 60 * 10 + 0.5)
        frames_per_minute = (rounded_fps * 60) - dropped_frames

        d = math.floor(frame / frames_per_ten)
        m = frame % frames_per_ten  # equivalent to math.fmod(frame, frames_per_ten)

        if m > dropped_frames:
            frame += (dropped_frames * 9 * d) + dropped_frames * math.floor((m - dropped_frames) / frames_per_minute)
        else:
            frame += dropped_frames * 9 * d

    # Calculate hours, minutes, seconds, and frame_count.
    frame_count = frame % rounded_fps
    total_seconds = math.floor(frame / rounded_fps)
    seconds = total_seconds % 60
    minutes = (total_seconds // 60) % 60
    hours = total_seconds // 3600

    # Determine how many digits to use for the frame part.
    frame_chars = len(str(rounded_fps - 1))

    # Set the default dividers.
    frame_divider = ":"
    interlace_divider = "."

    if is_drop_frame:
        frame_divider = ";"
        interlace_divider = ","

    # Build the format string.
    # Example format: "00:00:00:00" or "00:00:00;00" depending on the divider.
    format_string = f"{{:02d}}:{{:02d}}:{{:02d}}{frame_divider}{{:0{frame_chars}d}}"

    # Adjust for interlaced video: use a different divider if needed.
    if is_interlaced:
        frame_mod = frame_count % 2
        frame_count = frame_count // 2
        if frame_mod == 0:
            # Replace the first occurrence of frame_divider with the interlace_divider.
            format_string = format_string.replace(frame_divider, interlace_divider, 1)

    return format_string.format(hours, minutes, seconds, int(frame_count))


def movePlayhead(frame): # Not required if you append a clip from the media pool
    timecode = convert_frame_to_timecode(frame, 24) # Example 24 FPS
    timeline.SetCurrentTimecode(timecode) # Moves the playhead to the timecode given

if __name__ == "__main__":
    keys = list(exampleMarker.keys()) # May not work, just works for the example marker i have set up, but worth a try
    if keys:
        movePlayhead(keys[0]) 
        tmlComp = timeline.InsertFusionCompositionIntoTimeline() # Replace with Append To Timeline to avoid needing to move the playhead - you can also set how long that clip is when added. Currently, this will move everything to the right of the inserted clip to the right to make room, so it's not ideal
        comp = tmlComp.GetFusionCompByIndex(1) # If the Timeline Clip is a Fusion Effect(not an image or video) then you can get the comp automatically with this, with the comp being the first and only one that exists by default
        # Now we're in Fusion - No need to get the full Fusion API with `Fusion()` we start off in the Comp environment with out a need for anything else if we don't need it later on
        txtP = comp.AddTool('TextPlus')
        mediaOut = comp.FindTool("MediaOut1")
        mediaOut.ConnectInput('Input', txtP)
        txtP.StyledText = "My New Comp"


