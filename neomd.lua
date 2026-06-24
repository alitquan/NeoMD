local home        = os.getenv("HOME")
local images      = home .. "/Pictures"
local pictures    = home .. "/Images"
local imageDirs   = {".", images, pictures} 
local extensions  = {"jpg","png","jpeg"} 
local results     = {} 
local indentation = "   "

local lfs = require("lfs") 

-- make sure variable names are fine 
function test1() 
    print ("BEGIN -- variables")
    print (images)
    print (pictures) 
    print ("END") 


-- determines if file is image based on its extension 
function containsExtension(str)
    local lowerCase= string.lower(str)
    for _,extension in ipairs(extensions) do
        if str:find(extension,1,true) then
            return true
        end
    end
    return False 
end


-- search the target directories for images, and add them to the buffer 
--  TODO: get the dates of the file. Organize table by date 
function searchDirs() 
    for i = 1, #imageDirs do
        local dir = imageDirs[i]
        print ("Searching " .. dir) 

        for entry in lfs.dir(dir) do
            if entry ~= "." and entry ~= ".." then
                if containsExtension(entry) then
                    local filepath = dir .. "/" .. entry
                    table.insert(results, filepath)
                    print (indentation .. entry .. " is an image ")  
                else 
                    print (indentation .. entry .. " is not an image ")  
                end
            end
        end 
    end
    return results 
end

-- driving test function 
function testRun() 
    local retVal = searchDirs() 
    
    print ("time to get the table") 
    for i,dir in ipairs(retVal) do
        print (i,dir)
    end
end

-- TODO: make table on current line using the RESULTS
-- IDEA: add a little switch column that lets you toggle between chronological / alphabetical 

