module(..., package.seeall)

------------------------------------------------------------------
-- LIBRARIES
------------------------------------------------------------------

local storyboard = require("storyboard")
local scene = storyboard.newScene()


------------------------------------------------------------------
-- DISPLAY GROUPS
------------------------------------------------------------------

local menuGroup = display.newGroup()        -- display group for the menu items
local localGroup = display.newGroup()       -- main display group


------------------------------------------------------------------
-- GGDATA VARIABLES								-- localise variables from disk storage
------------------------------------------------------------------


local ggLevels = GGData:new("levels")       -- load levels database

local lvls = ggLevels.data -- table of data for the levels
local unlocked = settings.unlocked      -- last level unlocked by the player
local solved = settings.solved          -- total number of logos solved
local hints = settings.hints            -- number of hints the user has
local coins = settings.coins            -- number of coins the user has
local cLevel = settings.currentLevel    -- the last level that was played

------------------------------------------------------------------
-- LOCAL VARIABLES
------------------------------------------------------------------

local loading = false       -- whether or not the game is currently loading the menu images
local lv = 10              -- number of levels open to a free user
local totalLevels = 20     -- total number of levels in the game
local a = 1                 -- menu item to be loaded next
local row = 1               -- row of the next menu item
local col = 1               -- column of the next menu item
local data = require("data")    -- get info from data.lua on level structure
local levels = data.levels -- will store table of information about levels from data.lua
local unlock = data.unlock -- will store of table of number of logos needed to unlock each level from data.lua
local page = 1              -- current page being loaded (calculated in willEnterScene)
local pages = 1             -- total number of pages loaded so far
local moving = false        -- whether or not the user is moving finger on screen



local cols = { math.random(100, 200), math.random(100,200), math.random(100,200) }        -- array to hold colour values

if math.abs(cols[1] - cols[2]) < 30 then cols[2] = cols[2] - 50; end
if math.abs(cols[1] - cols[3]) < 30 then
    cols[3] = cols[3] + 50
    if cols[3] > 255 then cols[3] = 255; end
end                         -- adjust colours so they don't come out grey


if _G.paid == 1 or _G.platformName == "Android" or _G.osTarget == "Amazon" then lv = totalLevels; end
 -- adjust number of levels to open if user paid

------------------------------------------------------------------
-- OBJECT DECLARATIONS
------------------------------------------------------------------

local menus = {}        -- array for the menu buttons
local numberText = {}   -- array for the level number text objects
local locks = {}        -- array for the level locked images
local scoreText = {}    -- array for the level score text objects
local progText = {}     -- array for the level progress text objects
local progBar = {}      -- array for the progress bar borders
local fillBar = {}     -- array for the progress bar fill objects
local bg                -- background image
local rect = {}         -- array to hold hud items
local back              -- back arrow image
local testText              -- debug text
local hintIcon -- image for hint icon
local coinIcon -- image for coin icon
local hintText -- text object for number of hints remaining
local coinText -- text object for number of coins remaining
local pageText -- text object for current / max pages
local levelText -- tttle text

---------------------------------------------------------------------------------
-- GAMEPLAY FUNCTIONS
---------------------------------------------------------------------------------


local selectLogos = function(event)     -- function to handle level button touch events

    local obj = event.target            -- localise button pressed

    if (event.phase == "began") then

        if _G.platformName == "Android" then
            display.getCurrentStage():setFocus(obj)     -- avoid problems on some android devices
        end

    end

     print (obj.locked..lv)

    if (event.phase == "ended") and moving == false and obj.locked == 1 and obj.num <= lv then


        if _G.platformName == "Android" then
            display.getCurrentStage():setFocus(nil) -- avoid problems on some android devices
        end

        audio.play(sounds[10])      -- play click sound
        swipe()                     -- play swipe sound

        settings.currentLevel = obj.num     -- set level to be loaded
        settings:save()                     -- save to DB

        storyboard.gotoScene("app", "fromRight", 500)       -- load app.lua scene
    end
end



local loadLevels = function()

    menus[a] = display.newImageRect("cluebg.png", 200,160)
    menus[a].x = -80 + (col * 240);
    menus[a].y = -24 + (row * 180); menus[a].alpha = 0.95
    menus[a].num = a
    menus[a].locked = lvls[a]["open"]
    menus[a].rotation = 1           -- load level container image

    local red = math.random(100, 255)
    local blue = math.random(100, 255)
    local green = math.random(100, 255)

    --menus[a]:setFillColor(red, green,blue)
    menuGroup:insert(menus[a])          -- give image a random colour and insert to group

    menus[a]:addEventListener("touch", selectLogos) -- add touch listener

    local t = display.newText("level " .. a, 0, 0, fontName[1], 30)
    t.x = -80 + (col * 240);
    t.y = -70 + (row * 180) + o
    t.rotation = 0
    --t.alpha = 0.9
    t:setTextColor(red, green, blue)
    numberText[a] = t
    menuGroup:insert(numberText[a])     -- create text object to display the level number

    local t = display.newText("score: " .. lvls[a]["score"], 0, 0, fontName[1], 16)
    t.x = -80 + (col * 240);
    t.y = -34 + (row * 180) + o
    t.rotation = 0
    t:setTextColor(red -30,green -30,blue - 30)
    t.alpha = 0.9
    scoreText[a] = t
    menuGroup:insert(scoreText[a])  -- create text object to display the score on this level

    local done = lvls[a]["solved"]      -- get how many logos solved on this level
    local toget = levels[a]             -- get how many logos are on this level
    local percent = math.floor((done / toget) * 100)   -- calculate progress percentage

    local t = display.newText(done .. " / " .. toget, 0, 0, fontName[1], 14)
    t.x = -80 + (col * 240);
    t.y = 10 + (row * 180) + o
      t.rotation = 0
    t:setTextColor(red - 50,green -50,blue - 50)
    progText[a] = t
    menuGroup:insert(progText[a])       -- create text object to display level progress

    progBar[a] = display.newRoundedRect(0, 0, 150, 8, 3)
    progBar[a].x = -80 + (col * 240);
    progBar[a].y = 30 + (row * 180)
    progBar[a]:setStrokeColor(2,2,2)
    progBar[a].strokeWidth = 2
    progBar[a].alpha = 0.7
    progBar[a].rotation = 0
    menuGroup:insert(progBar[a])        -- create container bar for progress bar

    local fillup = (148 / 100) * percent        -- work out how wide to make the progress bar

    fillBar[a] = display.newRoundedRect(0, 0, fillup, 6, 2)
    fillBar[a]:setReferencePoint(display.CenterLeftReferencePoint)
    fillBar[a].x = -154 + (col * 240);
    fillBar[a].y = 30 + (row * 180)
    fillBar[a]:setFillColor(red,green,blue)
    fillBar[a].alpha = 0.9          -- create the progress bar

    if fillup == 0 then fillBar[a].alpha = 0; end       -- hide if empty

    menuGroup:insert(fillBar[a])

    local lopen = lvls[a]["open"]       -- get whether this level is open

    if a > lv then lopen = 0; end      -- if the user didn't pay yet close later levels

    if lopen == 0 then

        scoreText[a].alpha = 0      -- hide score if level closed
        fillBar[a].alpha = 0
        progBar[a].alpha = 0        -- hide progress bar if level closed

        locks[a] = display.newImageRect("padlock.png", 80,105);
        locks[a].x = -80 + (col * 240);
        locks[a].y = -34+ (row * 180); locks[a].alpha = 1
        menuGroup:insert(locks[a])      -- create a padlock image if level closed

        if a >= (unlocked + 1) and a < totalLevels+1 then
            progText[a].text = unlock[a - 1] - solved .. " to go..."
            progText[a].y = 30 + (row * 180) + o
            locks[a].y = -34 + (row * 180)
             numberText[a].alpha = 0
        end        -- if level closed but available, show how many logos needed to unlock

        if a > lv then
            progText[a]:setTextColor(red,green,blue)
            progText[a].text = "upgrade in shop"
            progText[a].y = 30 + (row * 180) + o
            locks[a].y = -34+ (row * 180)
            numberText[a].alpha = 0
        end
    end         -- if level closed and not available, show message for user to upgrade


    if a < 10 then audio.play(sounds[7]); end       -- play a click sound as each level container is loaded

    row = row + 1           -- move to the next row

    if row == 3 then
        col = col + 1
        row = 1

        if a < totalLevels then
            pages = pages + 1
            pageText.text = page .. " / " .. pages
            audio.play(sounds[11])
        end
    end                 -- move to next page when each page is filled

    a = a + 1           -- move onto next logo

    if a > totalLevels then
        loading = false
        audio.setVolume(_G.sound)
        stage = "choose"
    end             -- if all levels have been loaded, stop loading sequence and increase volume

end


local function gameLoop()       -- main runtime game loop

    testText.text = showAds.." "..revShow

    if loading then
        loadLevels()         -- keep loading levels as long as they are available
    end

end


local touchScreen = function(event) -- handles runtime touch events on screen (for swiping)

    if stage == "choose" then -- only allow swiping on main screen

        local diffX -- set up variable to store the X distance the finger has moved

        if event.phase == "began" then
            startTime = system.getTimer() -- get the time the finger first touches the screen
        end

        if event.phase == "moved" and event.yStart > 60 and event.yStart < 370 and pages > 1 then -- if finger moves in central area and there are pages to swipe to


            if _G.platformName == "Android" then
                display.getCurrentStage():setFocus(obj) -- avoids problems on some android devices where touches on buttons aren't registered
            end

            moving = true -- set a variable that states the user is currently moving their finger
            diffX = event.x - event.xStart -- calculate the X distance the finger has moved

            if math.abs(diffX) > 1 then -- if the finger has moved > 1 pixel

                menuGroup.x = -240 * (page - 1)
                menuGroup.x = menuGroup.x + diffX -- move the logo group along with the finger
            end
        end


        if event.phase == "ended" then

            if _G.platformName == "Android" then
                display.getCurrentStage():setFocus(nil) -- avoids problems on some android devices where touches on buttons aren't registered
            end

            moving = false -- reset variable as user no longer moving finger
            local moved -- temp variable to store which direction the user swiped
            diffX = (event.x - event.xStart) -- get the final amount of movement
            local absX = math.abs(diffX) -- get the absolute amount of movement irrespective of direction
            local endTime = system.getTimer() -- get the time the movement ended
            local moveTime = endTime - startTime -- calculate the total amount of time the finger touched the screen
            if diffX > 0 then moved = "left"; end
            if diffX < 0 then moved = "right"; end -- calculate which direction the user swiped

            local threshold = 15 -- sets a threshold for number of pixels the user must move finger to constitute a swipe

            if moveTime > 1000 then threshold = 100; end -- if the user moved finger slowly increase the threshold

            if page > 1 and moved == "left" and absX > threshold then -- if the finger swiped left far enough and there is a page to the left to swipe to
                page = page - 1 -- move the user to the previous page
                swipe() -- play a swipe sound
            else

                if page < pages and moved == "right" and absX > threshold then -- if the finger swiped right far enough and there is a page to the left to swipe to
                    page = page + 1 -- move the user to the next page
                    swipe() -- play a swipe sound
                end
            end

            pageText.text = page .. " / " .. pages -- update the page text display


            transition.to(menuGroup, { x = -240 * (page - 1), time = 1400, transition = easing.outExpo })
            transition.to(bg, { x = 240 + (-20 * (page - 1)), time = 1400, transition = easing.outExpo }) -- move the logos and background accordingly

            startTime = 0 -- reset startTime
        end
    end
end



local touchBack = function(event)   -- handles touching of back button

    if event.phase == "ended" then
        audio.play(sounds[9])       -- play a click sound
        swipe()                     -- play a swipe sound


        storyboard.gotoScene("start", "fromLeft", 500)      -- go back to start menu
    end
end


---------------------------------------------------------------------------------
-- STORYBOARD FUNCTIONS
---------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
function scene:createScene(event)
    localGroup = self.view

    if _G.paid == 0 then

        if _G.showAds == 1 then

            displayAds()

        end
    end

    local createScreen = function()

         bg = display.newImageRect("bg.jpg", 576, 576)
        bg.x = 230; bg.y = 240
        bg.alpha = 1
        localGroup:insert(bg) -- load and position background image

        local r = display.newImageRect("rect.png", 384, 130)
        --:setFillColor(cols[1], cols[2], cols[3])
        r.alpha = 1
        r.x = 160; r.y = -6 - yO * 2
        localGroup:insert(r)
        rect[1] = r -- load and position top bar image
        r.rotation = 1

          local red = math.random(100, 255)
    local blue = math.random(100, 255)
    local green = math.random(100, 255)

        back = display.newImageRect("back.png", 46,42); back.x = 32; back.y = 22 - yO * 2; back.alpha = 1
        localGroup:insert(back)
        back:addEventListener("touch", touchBack) -- load back button, position and add touch listener
        back.rotation = 126
        back:setFillColor(red,green,blue)

        levelText = display.newText("select", 0, 0, fontName[1], 30)
        levelText.x = 160; levelText.y = 19 + o - yO * 2
        levelText:setTextColor(210,210,210)
        localGroup:insert(levelText) -- create text header
        levelText.rotation =1

        testText = display.newText("", 0, 0, fontName[1], 12)
        testText.x = 60; testText.y = 5 + o
        testText:setTextColor(0, 0, 0)
        if checkMem == nil then testText.alpha = 0; end
        testText.text = yO

        localGroup:insert(testText) -- create a text object for debugging

        coinIcon = display.newImageRect("pig.png", 52,52); coinIcon.x = 286; coinIcon.y = 24 - yO * 2; coinIcon.alpha = 0.8
        localGroup:insert(coinIcon)
        coinIcon.rotation = -11
        coinIcon:setFillColor(red,green,blue)

        -- create and position coin icon

        hintIcon = display.newImageRect("bulb.png", 48,40); hintIcon.x = 232; hintIcon.y = 26 - yO * 2; hintIcon.alpha = 0.8
        localGroup:insert(hintIcon)
        hintIcon.rotation = 0
        hintIcon:setFillColor(red,green,blue)
        hintIcon.alpha = 0
         -- create and position hint icon

        coinText = display.newText(coins, 0, 0, fontName[1], 10)
        coinText.x = 286; coinText.y = 23 + o - yO * 2; coinText.rotation = -11
        coinText:setTextColor(222, 225, 225)
        localGroup:insert(coinText) -- create and position coin number text

        hintText = display.newText(hints, 0, 0, fontName[1], 10)
        hintText.x = 226; hintText.y = 18 + o - yO * 2; hintText.rotation = 11
        hintText:setTextColor(225, 225, 225)
        localGroup:insert(hintText) -- create and position hint number text
        hintText.alpha = 0

        pageText = display.newText("1 / " .. pages, 0, 0, fontName[1], 12)
        pageText.x = 290; pageText.y = 65 - yO*2
        pageText:setTextColor(210,210,210) -- create text object for page numbers

        localGroup:insert(pageText)

    end

     local createLogos = function()

        local s = 0.4
        if _G.sound == 0 then s = 0; end
        audio.setVolume(s)
        loading = true
        localGroup:insert(menuGroup)
    end

    createScreen()
    createLogos()
    ----------------------------------------------

    --      CREATE display objects and add them to 'group' here.
    --      Example use-case: Restore 'group' from previously saved state.

    -----------------------------------------------------------------------------
end

-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene(event)
    local group = self.view

        page = math.round(cLevel/2)
        menuGroup.x = -240 * (page - 1)

end

-- Called immediately after scene has moved onscreen:
function scene:enterScene(event)
    local group = self.view
    --audio.play(sounds.intro)


    Runtime:addEventListener("enterFrame", gameLoop)


    local previous = storyboard.getPrevious()

    if previous ~= "main" and previous then
        storyboard.removeScene(previous)
    end

    local ready = function()

        Runtime:addEventListener("touch", touchScreen)
    end

    timer.performWithDelay(500, ready)


    -----------------------------------------------------------------------------

    --      INSERT code here (e.g. start timers, load audio, start listeners, etc.)

    -----------------------------------------------------------------------------
end


-- Called when scene is about to move offscreen:
function scene:exitScene(event)
    local group = self.view

    Runtime:removeEventListener("touch", touchScreen)
    Runtime:removeEventListener("enterFrame", gameLoop)
    -----------------------------------------------------------------------------

    --      INSERT code here (e.g. stop timers, remove listeners, unload sounds, etc.)

    -----------------------------------------------------------------------------
end

-- Called AFTER scene has finished moving offscreen:
function scene:didExitScene(event)
    local group = self.view

     display.getCurrentStage():setFocus(nil)

    -----------------------------------------------------------------------------

    --      This event requires build 2012.782 or later.

    -----------------------------------------------------------------------------
end


-- Called prior to the removal of scene's "view" (display group)
function scene:destroyScene(event)
    local group = self.view

    -----------------------------------------------------------------------------

    --      INSERT code here (e.g. remove listeners, widgets, save state, etc.)

    -----------------------------------------------------------------------------
end

-- Called if/when overlay scene is displayed via storyboard.showOverlay()
function scene:overlayBegan(event)
    local group = self.view
    local overlay_scene = event.sceneName -- overlay scene name

    -----------------------------------------------------------------------------

    --      This event requires build 2012.797 or later.

    -----------------------------------------------------------------------------
end

-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
function scene:overlayEnded(event)
    local group = self.view
    local overlay_scene = event.sceneName -- overlay scene name

    -----------------------------------------------------------------------------

    --      This event requires build 2012.797 or later.

    -----------------------------------------------------------------------------
end



---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener("createScene", scene)

-- "willEnterScene" event is dispatched before scene transition begins
scene:addEventListener("willEnterScene", scene)

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener("enterScene", scene)

-- "exitScene" event is dispatched before next scene's transition begins
scene:addEventListener("exitScene", scene)

-- "didExitScene" event is dispatched after scene has finished transitioning out
scene:addEventListener("didExitScene", scene)

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener("destroyScene", scene)

-- "overlayBegan" event is dispatched when an overlay scene is shown
scene:addEventListener("overlayBegan", scene)

-- "overlayEnded" event is dispatched when an overlay scene is hidden/removed
scene:addEventListener("overlayEnded", scene)

---------------------------------------------------------------------------------

return scene
