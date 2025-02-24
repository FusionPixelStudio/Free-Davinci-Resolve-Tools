app:ShowConsole()
print("Testing Started")
print("Middle Click to End")
while true do
    Leftclicked = app:GetMouseButtons().LeftButton
    Rightclicked = app:GetMouseButtons().RightButton
    MiddleClick = app:GetMouseButtons().MiddleButton
    if Leftclicked then
        print("Left Clicked!")
    end
    if Rightclicked then
        print("Right Clicked!")
    end
    if MiddleClick then
        print("Middle Clicked!")
        print("Closing Script!")
        break
    end
    bmd.wait(0.075)
end
print("Testing Ended")