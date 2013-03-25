module(..., package.seeall)

------------------------------------------------------------------
-- LIBRARIES
------------------------------------------------------------------

local storyboard = require("storyboard")
local scene = storyboard.newScene()


------------------------------------------------------------------
-- DISPLAY GROUPS
------------------------------------------------------------------

local localGroup = display.newGroup()


------------------------------------------------------------------
-- OBJECT DECLARATIONS
------------------------------------------------------------------

local shopBtn       -- button to bring up the shop screen
local shopTxt       -- text object for shop button
local playBtn       -- button to start game
local playText      -- text object for play button
local optBtn        -- button to go to options screen
local optText       -- text for options button
local title         -- title image
local disclaimerText    -- text for legal disclaimer or other copyright message
local bg            -- background image


---------------------------------------------------------------------------------
-- GAMEPLAY FUNCTIONS
---------------------------------------------------------------------------------

local touchOpt = function(event)        -- function to handle touching of options button

    local obj = event.target

    if event.phase == "ended" then

        doink(obj)                      -- animate button
        audio.play(sounds[9])           -- play click sound

        swipe()                         -- play swoosh sound
        storyboard.gotoScene("options", "fromBottom", 500)      -- go to options.lua
    end
end



local touchPlay = function(event)       --  function to handle touching of play button

    local obj = event.target

    if event.phase == "ended" then

        doink(obj)                      -- animate button

        audio.play(sounds[9])           -- play click sound

        swipe()                         -- play swoosh sound
        storyboard.gotoScene("menu", "fromRight", 500)      -- govto menu.lua
    end
end



fadeMusic = function()              -- function to handle fading and removal of title music

    if sounds.intro and _G.sound == 1 then            -- check whether the sound file exists in memory
        audio.fade(sounds.intro, { channel = 12, time = 2250, volume = 0 })     -- fi so, fade it out

        disposeOf = function()

            audio.stop()
            audio.dispose(sounds.intro)
            audio.setVolume(_G.sound)
            sounds.intro = nil
            disposeOf = nil
        end

        timer.performWithDelay(2500, disposeOf)         -- after a delay, stop and dispose of the audio, reset volume
    end
end


local touchShop = function(event)       -- function to handle touching of shop button

    local obj = event.target

    if event.phase == "ended" then

        doink(obj)              -- animate button

        audio.play(sounds[9])   -- play click sound

        if _G.platformName ~= "Android" then
        swipe()                 -- play swoosh sound

        transition.to(localGroup, { time = 500, alpha = 0.2 })      -- darken menu screen

        local options =
        {
            effect = "fromLeft",
            time = 400,
            isModal = true
        }

        storyboard.showOverlay("shop", options)     -- load the options screen as an overlay

        else


         local onComplete = function (event)

            if "clicked" == event.action then
                local i = event.index
                if 2 == i then
                elseif 1 == i then
                    RevMob.openAdLink()

                    local dela = math.random(120000,1000000)
                    timer.performWithDelay(dela,updateCoins)
                end
            end

            end

            native.showAlert("Get Stars", "Install and run another free app to get 300 stars! (May take up to 10 minutes to register, please do not quit this app until hints are credited)", {"OK","Not right now"},onComplete)


        end


    end
end



---------------------------------------------------------------------------------
-- STORYBOARD FUNCTIONS
---------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
function scene:createScene(event)       -- function to create the start menu

    localGroup = self.view              -- assign the scene's view to localGroup display group

    local createScreen = function()     -- function to create all the menu objects

        bg = display.newImageRect("bg.jpg", 576, 576); bg.x = 140; bg.y = 240; bg.alpha = 1
        localGroup:insert(bg)           -- load background image

        local i = display.newImageRect("title.png", 300,180)
        i.x = -600; i.y = 122

        localGroup:insert(i)
        title = i
        transition.to(i, {x = 160, time = 500, delay = 100, transition = easing.inOutExpo})     -- load title image and slide in



        disclaimerText = display.newText("An Otter Studios Production. All logos and trademarks in this game are property of their respective clubs. Otter Studios is not affiliated or endorsed by any of the teams depicted.", 0, 0, 260, 60, fontName[1], 9)
        disclaimerText.x = 160; disclaimerText.y = 600
        disclaimerText:setTextColor(245,245,245)
        localGroup:insert(disclaimerText)               -- create disclaimer text object and slide in from top
        transition.to(disclaimerText, {y = 450+ o+yO*2, time = 1000, delay = 500, transition = easing.inOutExpo})

        playBtn = display.newImageRect("btn.png", 110, 42); playBtn.x = 160; playBtn.y = -200;
        playBtn.alpha = 1
        transition.to(playBtn, { delay = 300, time = 800, y = 245, transition = easing.inOutExpo })
        local r = math.random(100, 200)
        local g = math.random(100, 200)
        local b = math.random(100, 200)
        playBtn.rotation = -2
        --playBtn:setFillColor(r, g, b)
        playBtn:addEventListener("touch", touchPlay)
        localGroup:insert(playBtn)                      -- create play button, add touch listener and give it a random colour

        playText = display.newText("play", 0, 0, fontName[1], 18)
        playText.x = 160; playText.y = -212 + o
        playText:setTextColor(r,g,b)
        playText.rotation = -2
        transition.to(playText, { delay = 300, time = 800, y = 240 + o, transition = easing.inOutExpo })
        localGroup:insert(playText)
        --playText.rotation = 0           -- create text for play button

        optBtn = display.newImageRect("btn.png", 110,42); optBtn.x = 160; optBtn.y = 600;
        optBtn.alpha = 1
        optBtn.rotation = -2
        transition.to(optBtn, { delay = 300, time = 800, y = 300, transition = easing.inOutExpo })
        r = math.random(100, 200)
        g = math.random(100, 200)
        b = math.random(100, 200)
        --optBtn:setFillColor(r, g, b)
        optBtn:addEventListener("touch", touchOpt)
        localGroup:insert(optBtn)            -- create options button, add touch listener and give it a random colour

        optText = display.newText("options", 0, 0, fontName[1], 18)
        optText.x = 160; optText.y = 600 + o
        optText:setTextColor(r,g,b)
        optText.rotation = - 2
        transition.to(optText, { delay = 300, time = 800, y = 294 + o, transition = easing.inOutExpo })
        localGroup:insert(optText)
        --optText.rotation = 0            -- create text for options button

        local st = "shop"

        --if _G.revShow == 1 then

        if _G.platformName == "Android" then st = "get stars"; end


            shopBtn = display.newImageRect("btn.png", 110, 42); shopBtn.x = 160; shopBtn.y = -200;
            shopBtn.alpha = 1
            transition.to(shopBtn, { delay = 300, time = 800, y = 355, transition = easing.inOutExpo })
            r = math.random(100, 200)
            g = math.random(100, 200)
            b = math.random(100, 200)
            shopBtn.rotation = -2
            --shopBtn:setFillColor(r, g, b)
            localGroup:insert(shopBtn)
            shopBtn:addEventListener("touch", touchShop)    -- create shop button, add touch listener and give it a random colour

            shopText = display.newText(st, 0, 0, fontName[1], 18)
            shopText.x = 160; shopText.y = -200 + o
            shopText:setTextColor(r,g,b)
            transition.to(shopText, { delay = 300, time = 800, y = 349+ o, transition = easing.inOutExpo })
            localGroup:insert(shopText)
            shopText.rotation = -2                -- create shop button text

            --end

    end

    createScreen()      -- call the function to create the menu objects

end

-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene(event)
    local group = self.view


end

-- Called immediately after scene has moved onscreen:
function scene:enterScene(event)
    local group = self.view

    hideAds()

    local ready = function()

        local previous = storyboard.getPrevious()       -- get the previous scene

        if previous ~= "main" and previous then
            storyboard.removeScene(previous)        -- if it wasn't main.lua, delete the scene from memory
        end

        audio.play(sounds.intro, { channel = 12 })      -- play intro music
        audio.play(sounds.woosh)                        -- play a woosh sound as objects slide in

    end

    timer.performWithDelay(1000, ready)        -- after a second delay, start music and remove previous scene from memory


end


-- Called when scene is about to move offscreen:
function scene:exitScene(event)
    local group = self.view

    fadeMusic()

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

    transition.to(localGroup, { time = 200, alpha = 1 })    -- fade menu screen back in after returning from shop menu

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
