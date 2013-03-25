module(..., package.seeall)


------------------------------------------------------------------
-- LIBRARIES
------------------------------------------------------------------

local storyboard = require("storyboard")
local scene = storyboard.newScene()


------------------------------------------------------------------
-- DISPLAY GROUPS
------------------------------------------------------------------

local localGroup = display.newGroup()       -- main display group
local statGroup = display.newGroup()        -- display group for the stats screen
local aboutGroup = display.newGroup()       -- display group for the about screen


------------------------------------------------------------------
-- LOCAL VARIABLES
------------------------------------------------------------------


local cols = { math.random(100, 200), math.random(100,200), math.random(100,200) }        -- array to hold colour values

if math.abs(cols[1] - cols[2]) < 30 then cols[2] = cols[2] - 50; end
if math.abs(cols[1] - cols[3]) < 30 then
    cols[3] = cols[3] + 50
    if cols[3] > 255 then cols[3] = 255; end
end

local stage = "menu"       -- current game state

------------------------------------------------------------------
-- OBJECT DECLARATIONS
------------------------------------------------------------------

local statBg            -- background for stats screen
local statText = {}     -- array for stats text objects
local opBtns = {}       -- array for options screen button objects
local aCross            -- close about screen button
local bg                -- main background image
local levelText         -- main title text object
local rect = {}         -- array for top bar objects
local back              -- back button
local aboutBg           -- about screen background
local aboutText = {}   -- array for about screen text objects
local noCross           -- close stats screen button


---------------------------------------------------------------------------------
-- GAMEPLAY FUNCTIONS
---------------------------------------------------------------------------------

local touchButton = function(event)         -- function to handle touch events on options buttons

    local obj = event.target            -- localise button pressed

    if event.phase == "ended" and obj.active == true and stage == "menu" then       -- check if the button is active

        doink(obj)                      -- animate button
        audio.play(sounds[11])          -- play click sound

        if obj.id == 2 then             -- twitter button pressed
            system.openURL("http://www.twitter.com/otterstudios")       -- open twitter page
                                                 -- animate button
        end

        if obj.id == 7 then             -- info button pressed
            swipe()                 -- play swipe sound
            transition.to(aboutGroup, { time = 1000, x = 0, transition = easing.inOutExpo })    -- move in about screen
            stage = "about"
        end

        if obj.id == 6 then
            swipe()                     -- play swipe sound
            transition.to(statGroup, { time = 1000, x = 0, transition = easing.inOutExpo }) -- move in stats screen
            stage = "stats"
        end

        if obj.id == 5 then         -- shop button pressed

            swipe()
            local options =
            {
                effect ="fromLeft",
                time = 400,
                isModal = true
            }
            storyboard.showOverlay("shop", options)     -- show shop screen overlay
        end


        if obj.id == 3 then         -- gamecenter button pressed

            if loggedIntoGc then        -- if logged in
                --gameNetwork.show("leaderboards", { leaderboard = { timeScope = "AllTime" }, listener = dismissCallback })
                system.openURL("gamecenter:")       -- show gamecenter app
            else
                gameNetwork.init("gamecenter", initCallback)        -- if not logged in, login to gamecenter
                system.openURL("gamecenter:")                       -- show gamecenter app
                --gameNetwork.show("leaderboards", { leaderboard = { timeScope = "AllTime" }, listener = dismissCallback })
            end
        end

        if obj.id == 1 then             -- sound off button pressed
            obj.alpha = 0               -- hide the button
            obj.active = false          -- make the button inactive
            _G.sound = 0
            audio.setVolume(_G.sound)   -- set sound to zero
            opBtns[8].alpha = 1         -- show the on button
            transition.to(opBtns[8], { time = 100, xScale = 1.3, yScale = 1.3 })
            transition.to(opBtns[8], { delay = 100, time = 300, xScale = 1, yScale = 1 })   -- animate the button
            opBtns[8].active = true     -- make the off button active
            settings.sound = 0          -- store sound value in DB
            settings:save()             -- save DB
        end

        if obj.id == 8 then             -- sound on button pressed
            obj.alpha = 0               -- hide button
            obj.active = false          -- make button inactive
            _G.sound = 1
            audio.play(sounds.hintup)       -- play a sound to indicate sound back on
            audio.setVolume(_G.sound)       -- set the volume
            opBtns[1].alpha = 1             -- show the off button
            opBtns[1].active = true         -- make the off button active
            transition.to(opBtns[1], { time = 100, xScale = 1.3, yScale = 1.3 })
            transition.to(opBtns[1], { delay = 100, time = 300, xScale = 1, yScale = 1 })  -- animate the button
            settings.sound = 1          -- store sound value in DB
            settings:save()             -- save DB
        end

        if obj.id == 4 then         -- facebook button pressed

            local function onComplete(event)
                if "clicked" == event.action then
                    local i = event.index
                    if 2 == i then
                        -- Do nothing; dialog will simply dismiss
                    elseif 1 == i then

                        _G.fbType = "about"         -- set the type of facebook post to make
                       settings.coins = settings.coins + 150     -- add 50 to hints
                       settings:save()                          -- save DB
                       postabout()                              -- call function in main.lua to post to facebook
                    end
                end
            end

            -- Show alert asking if user wants to share on facebook for a reward
            local alert = native.showAlert("Tell your friends!", "Share on your facebook wall and get 150 stars?",
                { "Yes please", "No thanks" }, onComplete)

        end
    end
end

local closeAbout = function(event)      -- handles touch event on about screen close button

    local obj = event.target

    if event.phase == "ended" then

        audio.play(sounds[10])      -- play click sound
        stage = "menu"              -- reset game status
        doink(obj)                  -- animate button
        swipe()                     -- play swipe sound

        transition.to(aboutGroup, { time = 1000, x = 600, transition = easing.inOutExpo }) -- move about screen off-screen
    end
end

local closeStats = function(event)      -- handles touch event on stats screen close button

    local obj = event.target

    if event.phase == "ended" then

        audio.play(sounds[10])      -- play click sound
        stage = "menu"              -- reset game status
        doink(obj)                  -- animate button
        swipe()                     -- play swipe sound
        transition.to(statGroup, { time = 1000, x = 600, transition = easing.inOutExpo }) -- move stats screen off-screen
    end
end




local touchBack = function(event)           -- function to handle back button

    if event.phase == "ended" and stage == "menu" then      -- if on main screen

        audio.play(sounds[9])           -- play click sound
        swipe()                         -- play swipe sound

        --storyboard.removeScene("options")
        storyboard.gotoScene("start", "fromLeft", 500)   -- go back to main menu
    end
end




---------------------------------------------------------------------------------
-- STORYBOARD FUNCTIONS
---------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
function scene:createScene(event)
    localGroup = self.view


    local createScreen = function()     --function to create the background and HUD

        bg = display.newImageRect("bg.jpg", 640, 576)
        bg.x = 240; bg.y = 240
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

        levelText = display.newText("Options", 0, 0, fontName[1], 24)
        levelText.x = 160; levelText.y = 24 + o - yO * 2
        levelText:setTextColor(255,255,255)
        localGroup:insert(levelText) -- create text displaying title



    end

    local createButtons = function ()       -- function to create the options buttons

        local names = { "son", "tw", "gc", "fbo", "shop", "st", "inf", "soff" }      -- array containing file names
        local sx = { 60,60,60,60,60,60,60,60 }      -- array containing x sizes for buttons
        local sy = { 60,60,60,60,60,60,60,60}      -- array containing y sizes for buttons
        local px = { 110, 70, 160, 250, 210, 110, 210, 110 }        -- array containing x positions for buttons
        local py = { 150, 240, 240, 240, 331, 330, 152, 150 }        -- array containing y positions for buttons
        local al = { 1,1,1,1,1,1,1, 0 }


        for a = 1, 8, 1 do      -- loop through the 8 buttons

            local btn = display.newImageRect(names[a] .. ".png", sx[a], sy[a]);
            btn.x = px[a]; btn.y = py[a]; btn.id = a; btn.active = true
            localGroup:insert(btn)
            btn.alpha = al[a]
            btn:addEventListener("touch", touchButton)
            opBtns[a] = btn                 -- load button image, set ID, position and size accordingly, add touch listener
        end

        if _G.osTarget == "Amazon" or _G.osTarget == "Android" then
            opBtns[3].active = false
            opBtns[3].alpha = 0
            opBtns[5].active = false
            opBtns[5].alpha = 0
            opBtns[6].x = 160
        end                             -- if running on amazon hide gamecenter and shop buttons

        if _G.sound > 0 then
            opBtns[1].alpha = 1
            opBtns[1].active = true
            opBtns[8].alpha = 0
            opBtns[8].active = false
        else
            opBtns[8].alpha = 1
            opBtns[8].active = true
            opBtns[1].alpha = 0
            opBtns[1].active = false              -- show the appropriate sound button depending on current status
        end
    end

    local createAbout = function()          -- function to create the about screen

        aboutBg = display.newImageRect("optbg.png", 280, 400)
        aboutBg.x = 160
        aboutBg.y = 254
        aboutBg.alpha = 0.96
        --aboutBg:setFillColor(cols[1],cols[2],cols[3])
        aboutGroup:insert(aboutBg)          -- load background imae

        local t = display.newText("Information", 0, 0, fontName[1], 22)
        t.x = 160; t.y = 95
        t:setTextColor(255,255,255)
        aboutGroup:insert(t)
        aboutText[1] = t                -- create title text object

        local i = "Touch a logo to open the entry screen, and type in the name of the team the shirt belongs to. If you don't know it, you can press the bomb icon to bring up a help menu."
        local i2 = "Your score is based on how long it takes you to get the correct answer and how many hints you use. The higher your score the more stars you earn. A star is also awarded every minute of play!"
        local i3 = "If you get really stuck you can post the screenshot on your facebook wall for your friends to help. Good luck!"
        local i4 = "Programming, UI graphics and design by Nick Sherman."
        if _G.osTarget == "Amazon" then
        i2 = "You lose points for misspelling the game or using hints/coins. A coin is awarded for every game solved with a score of 750 or more. A clue is awarded for every 2 correct answers and 5 minutes of gameplay."
        end         -- define the required information screen text

        local t = display.newText(i, 300, 100, 240, 100, fontName[1], 11)
        t.x = 160; t.y = 170
        t:setTextColor(255,255,0)
        aboutGroup:insert(t)
        aboutText[2] = t

        local t = display.newText(i2, 300, 100, 240, 100, fontName[1], 11)
        t.x = 160; t.y = 246
        t:setTextColor(255,255,255)
        aboutGroup:insert(t)
        aboutText[3] = t

        local t = display.newText(i3, 300, 100, 240, 100, fontName[1], 11)
        t.x = 160; t.y = 337
        t:setTextColor(255,255,0)
        aboutGroup:insert(t)
        aboutText[4] = t

        local t = display.newText(i4, 300, 100, 240, 100, fontName[1], 12)
        t.x = 160; t.y = 393
        t:setTextColor(255,255,255)
        aboutGroup:insert(t)
        aboutText[5] = t                -- create the text objects with the appropriate text values set above

        aCross = display.newImageRect("cross.png", 30,30)
        aCross.x = 160
        aCross.y = 400
        aboutGroup:insert(aCross)
        aCross.rotation = 0
        aCross:addEventListener("touch", closeAbout)        -- create close screen cross icon and add touch listener

        localGroup:insert(aboutGroup)
        aboutGroup.x = 600                  -- move about screen off-screen for now
    end



    local createStats = function()

        statBg = display.newImageRect("optbg.png", 260, 300)
        statBg.x = 160
        statBg:setFillColor(cols[1],cols[2],cols[3])
        statBg.y = 244
        statBg.alpha = 0.96
        statGroup:insert(statBg)        -- load background image

        local t = display.newText("Game Stats", 0, 0, fontName[1], 24)
        t.x = 160; t.y = 130
        t:setTextColor(255,255,255)
        statGroup:insert(t)
        statText[1] = t                 -- create title text object

        local q = 680                       -- set number of logos in the game here!
        local a = settings.guesses
        local s = settings.solved
        local w = settings.wrong
        local sc = settings.totalScore
        local n = settings.almost
        local c = settings.coinTotal
        local h = settings.coinSpent        -- localise values from DB
        local sk = settings.skipped

        local ta = { "Total Kits:", "Total Guesses:", "Solved:", "Wrong:", "Skipped:", "Total Score:", "Coins Earned:", "Coins Spent:" }
        local tb = { q, a, s, w, sk, sc, c, h }
                -- setup arrays of stats titles and values

        local colour1 = 255
        local colour2 = 255
        local colour3 = 255
        local cc = 1            -- set up colours for text and a toggle variable

        for a = 1, 8, 1 do      -- loop through the 8 stats categories

            local t = display.newText(ta[a], 0, 0, fontName[1], 12)
            t:setReferencePoint(display.CenterLeftReferencePoint)
            t.x = 70; t.y = 145 + (a * 24)
            t:setTextColor(colour1, colour2, colour3)

            statGroup:insert(t)
            statText[a+1] = t           -- create the stat header text object

            if cc == 1 then
                colour1 = 255; colour2 = 255; colour3 = 0; cc = 2
            else
                colour1 = 255; colour2 = 255;colour3 = 255; cc = 1
            end                                                 -- swap colours

            local t = display.newText(tb[a], 0, 0, fontName[1], 12)
            t:setReferencePoint(display.CenterRightReferencePoint)
            t.x = 250; t.y = 145 + (a * 24)
            t:setTextColor(colour1, colour2, colour3)       -- create the stat value text object

            statGroup:insert(t)
            statText[a+9] = t

        end

        noCross = display.newImageRect("cancel.png", 26, 26)
        noCross.x = 160
        noCross.y = 365
        noCross:setFillColor(255, 255, 255)
        statGroup:insert(noCross)
        noCross.rotation = 45
        noCross:addEventListener("touch", closeStats)           -- create the close stats screen button

        statGroup.x = 600                   -- move the stats screen off
        localGroup:insert(statGroup)
    end

    createScreen()          -- call function to create HUD
    createButtons()         -- call function to create options buttons
    createStats()           -- call function to create stats screen
    createAbout()           -- call function to create about screen

end

-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene(event)
    local group = self.view

end

-- Called immediately after scene has moved onscreen:
function scene:enterScene(event)
    local group = self.view

    local ready = function()
        local previous = storyboard.getPrevious()

        if previous ~= "main" and previous then
            storyboard.removeScene(previous)
        end

    end

    timer.performWithDelay(1000, ready)


end


-- Called when scene is about to move offscreen:
function scene:exitScene(event)
    local group = self.view


end

-- Called AFTER scene has finished moving offscreen:
function scene:didExitScene(event)
    local group = self.view


end


-- Called prior to the removal of scene's "view" (display group)
function scene:destroyScene(event)
    local group = self.view


end

-- Called if/when overlay scene is displayed via storyboard.showOverlay()
function scene:overlayBegan(event)
    local group = self.view
    local overlay_scene = event.sceneName -- overlay scene name


end

-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
function scene:overlayEnded(event)
    local group = self.view
    local overlay_scene = event.sceneName -- overlay scene name


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
