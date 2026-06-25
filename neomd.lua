local home        = os.getenv("HOME")
local dir_images      = home .. "/Pictures"
local dir_pictures    = home .. "/Images"
local imageDirs   = {".", dir_images, dir_pictures} 
local extensions  = {"jpg","png","jpeg"} 
local results     = {} 
local indentation = "   "

local lfs = require("lfs") 

-- make sure variable names are fine 
function test1() 
    print ("BEGIN -- variables")
    print (dir_images)
    print (dir_pictures) 
    print ("END") 
end 


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

    -- refresh or buffer will keep adding more elements each time it opens
    -- since index has to be less than length, wraparound breaks if you do not reset
    -- IDEA: what about if you want to do a refresh search while in buffer? 
    results = {}
    for i = 1, #imageDirs do
        local dir = imageDirs[i]
        print ("Searching " .. dir) 

        for entry in lfs.dir(dir) do
            if entry ~= "." and entry ~= ".." then
                if containsExtension(entry) then
                    local filepath = dir .. "/" .. entry
                    local attr = lfs.attributes(filepath)
                    
                    local result = {
                        path = filepath,
                        name = entry,
                        modified = attr.modification,
                    } 
                    table.insert(results, result)
                    print (indentation .. entry .. " is an image ")  
                else 
                    print (indentation .. entry .. " is not an image ")  
                end
            end
        end 
    end
    return results 
end

-- IDEA: add a little switch column that lets you toggle between chronological / alphabetical 


--
-- BUFFER LOGIC
--
--



-- this represents the current vertical position of the user
local state = {
    user_index = 1,
    images = {} 
} 

-- instructional lines in the buffer 
local headers = 8

-- this represents the current window 
local mWindow = nil

-- setting up buffer params 
local buffer1  = vim.api.nvim_create_buf(false,true) 
local b1_width = 50 
local b1_height= 15

local opts = {
    relative = "editor",
    width = b1_width,
    height = b1_height,
    row = 5,
    -- col = 10,
    col = math.floor ((vim.o.columns - b1_width) / 2),
    style = "minimal",
    border = "rounded", 
    title = " Choose Image ",
    title_pos = "center",
}


local namespace = vim.api.nvim_create_namespace("choose-file") 

local function highlight_current_line(buffer) 
    vim.api.nvim_buf_clear_namespace(buffer,namespace,0,-1)

    -- these are informational lines at the top that cannot be selected. 
    local line = headers + state.user_index - 1

    vim.api.nvim_buf_add_highlight(
        buffer,
        namespace,
        "CursorLine",
        line,
        0,
        -1 
    )
end



local function shift_cursor_to_item(win)
    local row = headers + state.user_index
    vim.api.nvim_win_set_cursor(win, {row,0}) 
end 



function populateBuffer(buffer,window) 

    -- reset the images so that it doesn't add more when this function is ran again 
    state.images = {} 

    -- search for images and populate list 
    state.images = searchDirs()
    

    local lines = {
        "Choose an image,",
        "",
        "j/k  -- up/down",
        "<CR> -- insert markdown image ",
        " s   -- toggle sort",
        " n   -- toggle name/path",
        "",
        " " .. string.rep("-",b1_width - 2),
    } 

    for i,file in ipairs(state.images) do
        print ("This is what file is: " .. file.name) 
        table.insert(lines,file.name) 
    end
    
    vim.api.nvim_buf_set_lines(buffer,0,-1,false, lines)
    highlight_current_line(buffer)
    shift_cursor_to_item(window)
end



---
-- activate buffers 
--

function toggleBuffer1()
    vim.api.nvim_set_current_buf(buffer1)
end


function floatBuffer1() 
    mWindow = vim.api.nvim_get_current_win() 
    window1 = vim.api.nvim_open_win(buffer1,true,opts)
end






----
-- Map Keys
--


-- test

vim.g.mapleader = " "

local function set_global_keys()
    vim.keymap.set("n","<leader>!",function()
        testBuffer1()

    end,{
        desc = "Open choose-file buffer",
        silent = true,
    })
end


set_global_keys()


-- buffer   = buffer 1 
-- bWindow  = buffer window
-- mWindow  = main window (neovim) 
local function setup_buffer_keys(buffer,bWindow, mWindow) 
    local function move_selection(buffer, bWindow, movement)
        local count = #state.images

        if count == 0 then
            return
        end
        local user_index = state.user_index + movement 

        -- wrap from begin -> end 
        if user_index < 1 then 
            user_index = count  
        end 

        -- wrap from end -> beginning 
        if user_index > #state.images then
            user_index = 1
        end 
        state.user_index = user_index

        -- remember that this uses state.user_index locally  
        highlight_current_line(buffer) 

        vim.api.nvim_win_set_cursor(bWindow, {
            headers + state.user_index,
            0
        })


    end 


    --- mapping 

    -- down 
    vim.keymap.set("n","j", function() 
        move_selection(buffer,bWindow,1)
    end, {buffer = buffer, silent = true, nowait = true}) 

    -- up 
    vim.keymap.set("n","k", function() 
        move_selection(buffer,bWindow,-1)
    end, {buffer = buffer, silent = true, nowait = true}) 

    -- enter key 
    vim.keymap.set("n","<CR>",function()
        local selectedImage = state.images[state.user_index] 

        if not selectedImage then
            return
        end

        -- what you selected when you hit enter 
        local retval = selectedImage.path

        if vim.api.nvim_win_is_valid (mWindow) then
            -- set main window 
            vim.api.nvim_set_current_win(mWindow) 

            -- close buffer window
            vim.api.nvim_win_close(bWindow, true)

            vim.api.nvim_put(
                {"![alt text](" .. retval .. ")"},
                "l",
                true,
                true
            )
        
        end

    end, {buffer = buffer, silent = true, nowait = true}) 

    -- menu toggles 
    --   probably need to update images and display the creation time, and then refresh
end


---
-- Driver 
--


function testRun() 
    local retVal = searchDirs() 
    
    print ("time to get the table") 
    for i,item in ipairs(retVal) do
        print (i,item.path, item.name, item.modified)
    end
end


function testBuffer1() 
    floatBuffer1()
    populateBuffer(buffer1,window1)
    setup_buffer_keys(buffer1,window1,mWindow)
end


