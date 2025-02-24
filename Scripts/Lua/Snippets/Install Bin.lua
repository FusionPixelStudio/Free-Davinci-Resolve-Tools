
-- Path to the file (change this to your file)
local filePath = "C:\\Users\\Asher Roland\\Documents\\DAVINCI PRESETS\\Bins\\Snap Ultimate.drb"

-- Function to execute a file with its associated application
local function openFile(filePath)
    -- Determine the operating system
    local isWindows = package.config:sub(1,1) == '\\'
    
    -- Prepare the command based on the OS
    local command
    if isWindows then
        -- For Windows
        command = 'cmd.exe /c start "" "' .. filePath .. '"'
    else
        -- For Unix/Linux/Mac
        command = 'open "' .. filePath .. '"'
    end

    -- Execute the command
    local result = os.execute(command)

    -- Check the result
    if result then
        print("File executed successfully.")
    else
        print("File execution failed.")
    end
end

-- Call the function to open the file
openFile(filePath)
