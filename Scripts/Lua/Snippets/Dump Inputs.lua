print("****************************************************************************************************\n")

print("  Script:\t\t\tCreate D.A.M.N Circles")
print("  Version:\t\t\t1.0")
print("  Written:\t\t\tBrian Sinasac")
print("  Date:\t\t\tDecember 20, 2006")
print("  Requested by:\t\tKonstantin Hristozov, DAMNfx\n")

print("\t\t\tCreates circles in the paint tool from parameters supplied in a file.\n")
print("\t\t\tVersion 1 of this script expects that the user has manually added a\n")
print("\t\t\tpaint tool that will contain the circles.\n")
--			This script is run from within Fusion.

--  Required Actions (Version 1):

--  1.  Identify the selected tool 
--  2.  Verify that only one paint tool has been selected
--  3.  Open file and read information  
--  4.  Create circle at specified frame, with radius, at location x, y
--  5.  Repeat until end of file


print("****************************************************************************************************\n")
--						TOOLBOX

--theTool = a tool
function showInputs(theTool)
	inputList=theTool:GetInputList()
	count=table.getn(inputList)
	for i=1, count do
		print(i.."  "..inputList[i]:GetAttrs().INPS_Name.."  "..inputList[i]:GetAttrs().INPS_ID)
	end
end


function showAttributes(theTool)
	table.foreach(theTool:GetAttrs(),print)
end


function showAttributesFull(theTool)  -- shows all attributes of the tool
	theAttrs=theTool:GetAttrs()
	for iterator, key in pairs(theAttrs) do
		if(type(key)=="table") then
			print(iterator)
			print("****************************")
			dump(key)
			print("****************************")
		else
			print(iterator.."\t"..tostring(key))
		end
	end
end


function showAttributeValue(theTool, attrName)  -- shows the value of a specific attribute
	consoleString = attrName.." does not exist."
	attrList = theTool:GetAttrs()
	print(theTool:GetAttrs()[6])
	print(theTool:GetAttrs().TOOLI_ImageWidth)
	dump(attrList)
	count = table.getn(attrList)
	print (count)
	for i = 1, count do
	print(attrList[i])
		if attrList[i] == attrName then
			consoleString = tostring(attrName) .." is "..attrList[i]
		end
	end
	print(consoleString)
end


-- verify file exists
function validateFile(aFile)
	if fileexists(aFile) then
		return(true)
	else
		return(false)
	end
end


-- populate list box (fresh populate)
function populateListBox(theListBox, theDataTable)
	for i=1, table.getn(theDataTable) do
		theListBox[tostring(i)]=theDataTable[i]
	end
end


-- populate list box (fresh populate)
function clearListBox(theListBox)
	counter = 1
	while theListBox[counter]~=nil do
		theListBox[counter]=nil
		counter=counter+1
	end
	iup.Flush()
end


-- File and Date Selection GUI
function fileSelector()
	iup.SetLanguage("ENGLISH")
	f, err = iup.GetFile("*.log")

	if err == 0 then 
		return (f)	    
	elseif err == -1 then 
		return(false)
	end
end


-- returns all characters before or after specified delimitor
function stripPath(thePath, theDelimitor, path) -- path is a boolean if true return all before
-- find the last \ in the path
	for i=string.len(thePath), 1, -1 do
		if string.byte(thePath, i) == string.byte(theDelimitor,1) then
			if path then
				return(string.sub(thePath,1,i)) --return the path
			else
				return(string.sub(thePath,i+1))  --return the file
			end
		end
	end
	return(false)
end


--						TOOLBOX
--****************************************************************************************************
--						SCRIPT DISTINCT FUNCTIONS

function defineCircle(defString)
	startFrame = 6
	endFrame = string.find(defString, ",", tonumber(startFrame))
	aFrame = tonumber(string.sub(defString, tonumber(startFrame), tonumber(endFrame)-1))
	startRadius = string.find(defString, "radius ", tonumber(endFrame))+7
	endRadius = string.find(defString, ",", tonumber(startRadius))
	aRadius = tonumber(string.sub(defString, tonumber(startRadius),tonumber(endRadius)-1))
	startU = string.find(defString, " U ", tonumber(endRadius))+3
	endU = string.find(defString, ",", tonumber(startU))
	aU = tonumber(string.sub(defString, tonumber(startU),tonumber(endU)-1))
	startV = string.find(defString, " V ", tonumber(endU))+3
	aV = tonumber(string.sub(defString, tonumber(startV)))
	return ({frame = aFrame, radius = aRadius, U = aU, V = aV})
end

--						SCRIPT DISTINCT FUNCTIONS
--****************************************************************************************************


-- global variables
foundTool = false
scriptFailure = false
selectedTool = 0
firstCircle = false
completeToolList = composition:GetToolList()  --list of all tools in comp
--dump(completeToolList)
-- 1.  Find selected tool
-- 2.  Verify that only one paint tool has been selected


for i=1, table.getn(completeToolList) do
	if completeToolList[i]:GetAttrs().TOOLB_Selected then
		if completeToolList[i]:GetAttrs().TOOLS_RegID ~= "BezierSpline" then
			if foundTool then
				print("You have selected more than one tool.  Please rerun the script with only a single tool selected.")
				scriptFailure = true
				break
			end
		end
		if completeToolList[i]:GetAttrs().TOOLS_RegID == "Paint" then
			thePaintTool = i
			foundTool = true
		elseif completeToolList[i]:GetAttrs().TOOLS_RegID == "BezierSpline" then
			--catch the all selected BezierSplines
		else
			print("The selected tool is not a paint tool.  Please rerun the script with a paint tool selected.")
			scriptFailure = true
			break
		end
	end
end

if not scriptFailure then
--  3.  Open file and read information  
	theFile=fileSelector()
	sourceFile = io.open(theFile,"r")
	if sourceFile==nil then
		print("Failed to open file "..theFile)
	else
		io.input(sourceFile)
		readString=io.read("*l")  -- read the first line of the file
		while (readString) do
			-- verify that read line is in proper format.  Look for date at beginning
			if(readString==nil) then
				break
			end
			--break up the string into usable components
			aCircle = defineCircle(readString)
			--add the circle to the paint tool at frame
			currentCircle = PaintCircle{} -- create the circle
			opacityBezier = BezierSpline{} -- create the bezier to animate the opacity
			
			if not firstCircle then  -- connecting into the paint tool
				table.insert(completeToolList, currentCircle)
				firstCircle = true
				completeToolList[thePaintTool]:GetInputList()[16]:ConnectTo(currentCircle)  -- 16 is the location of the Paint input for Paint tools
			else  -- connecting into the last circle
				table.insert(completeToolList, currentCircle)
				completeToolList[thePaintTool]:GetInputList()[27]:ConnectTo(currentCircle)  -- 27 is the location of the Paint input for PaintCircles
			end
			
			currentCircle.Radius=aCircle.radius
			currentCircle.Center = {aCircle.U, aCircle.V}
			currentCircle.PaintApplyColor.Opacity = opacityBezier
			
			opacityTable = {}
			-- set opacity key frames
			if aCircle.frame == 0 then
				opacityTable[0] = 1
			else
				opacityTable[0] = 0
				opacityTable[tonumber(aCircle.frame)-1] = 0
				opacityTable[tonumber(aCircle.frame)]=1
			end
			opacityBezier:SetKeyFrames(opacityTable)
			
			thePaintTool=table.getn(completeToolList)  -- next circle will connect to the one before
			opacityBezier:GetAttrs().TOOLB_Selected=false
			
			readString=io.read("*l")
		end
	end
end

print("Script Complete!")