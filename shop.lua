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

local bg            -- background image
local btns = {}     -- array to hold the various buttons
local shopText = {} -- array to hold the text objects


---------------------------------------------------------------------------------
-- GAMEPLAY FUNCTIONS
---------------------------------------------------------------------------------


callbackFunction = function(state)      -- function to handle response from app store

    if (state == "restored") or (state == "purchased") then


        if _G.bought == 2 then      -- user upgraded

            _G.paid = 1             -- update global variable to paid
            --_G.hintTime = 2         -- reduce number of correct answers needed for free hint
            btns[5].alpha = 0       -- hide upgrade button
            btns[6].alpha = 0       -- hide restore buttonn
            shopText[5].alpha = 0     -- hide upgrade text
            shopText[6].alpha = 0     -- hide restore text
            hideAds()               -- hide ads

            settings.paid = 1       -- set paid status in DB
            --settings.hints = settings.hints + 30        -- add hints
            settings.coins = settings.coins + 300        -- add coins
            settings:save()                             -- save the DB

            native.setActivityIndicator(false)          -- stop the activity indicator
            native.showAlert(state, "Thank you, you have successfully upgraded to the full version!", { "OK" })     -- show a thankyou message
            _G.bought = 0           -- reset the bought code flag
        end

        if _G.bought == 1 then          -- user bought 150 hints, update DB and show message
            settings.coins = settings.coins + 800
            native.showAlert("Thank you", "You have bought 800 stars!", { "OK" })
        end

        if _G.bought == 3 then            -- user bought 500 hints, update DB and show message
            settings.coins =settings.coins + 2000
            native.showAlert("Thank you", "You have bought 2000 stars!", { "OK" })
        end

        if _G.bought == 4 then            -- user bought 300 coins, update DB and show message
            settings.coins = settings.coins + 3200
            native.showAlert("Thank you", "You have bought 3200 stars!", { "OK" })
        end

        if _G.bought == 5 then              -- user bought 1000 coins, update DB and show message
            settings.coins = settings.coins + 6000
            native.showAlert("Thank you", "You have bought 6000 stars!", { "OK" })
        end

        settings:save()             -- save the DB
        _G.bought = 0               -- reset bought code flag



    elseif (state == "cancelled") then

    elseif (state == "failed") then
    end
end



local touchBtn = function(event)        -- function to handle button touch events

    local obj = event.target            -- localise button pressed

    if event.phase == "ended" then

        doink(obj)                      -- animate button
        audio.play(sounds[8])           -- play click sound

        if store.canMakePurchases then      -- check whether store is available

            if obj.id == 1 then iap.buyItem1(callbackFunction); end     -- 150 hints requested, call function within iap.lua
            if obj.id == 2 then iap.buyItem3(callbackFunction); end     -- 500 hints requested, call function within iap.lua
            if obj.id == 3 then iap.buyItem4(callbackFunction); end     -- 300 coins requested, call function within iap.lua
            if obj.id == 4 then iap.buyItem5(callbackFunction); end     -- 1000 coins requested, call function within iap.lua
            if obj.id == 5 then iap.buyItem2(callbackFunction); end     -- upgrade requested, call function within iap.lua
            if obj.id == 6 then  iap.restore(callbackFunction); end     -- restore requested, call function within iap.lua

        else

            native.showAlert("Store purchases are not available, please try again later", { "OK" }) -- show message that shop not available

        end

            if obj.id == 7 then         -- cancel button pressed
                doink(obj)
                audio.play(sounds[9])
                storyboard.hideOverlay("slideLeft", 500)        -- go back to previous screen
            end

    end
end

-- Called when the scene's view does not exist:
function scene:createScene(event)           -- function to create the shop screen
    localGroup = self.view

    local createScreen = function()         -- function to create the objects

        local i = display.newImageRect("optbg.png", 300, 380)
        i.x = 160; i.y = 250
        localGroup:insert(i)
        bg = i
        i.alpha = 0.97          -- load background image

        local t = display.newText("Shop", 0, 0, fontName[1], 30)
        t.x = 160; t.y = 92 + o
        t:setTextColor(255,255,255)
        localGroup:insert(t)
        shopText[10] = t                -- main shop title text object

        local t = display.newText("Upgrade and buy stars here!", 0, 0, fontName[1], 16)
        t.x = 160; t.y = 123 + o
        t:setTextColor(255,255,0)
        localGroup:insert(t)
        shopText[11] = t            -- description text object

        local btnTxt = {"800    £0.69/$0.99","2000    £1.49/$1.99", "3200    £1.99/$2.99","6000    £2.49/$3.99","Remove ads  £0.69/$0.99","Restore","Cancel"}
                                -- array to hold button titles
        for a = 1, 7, 1 do      -- loop through the 7 required buttons

            local r = math.random(150, 250); local g = math.random(150, 250); local b = math.random(150, 250) -- create a random colour

            local fn = "green_btn.png"
            local wd = 160

            if a == 7 then fn = "red_btn.png"; wd = 100; end


            local i = display.newImageRect(fn, wd, 36); i.x = 160; i.y = 120 + (a*40);
            localGroup:insert(i)
            i:addEventListener("touch", touchBtn)
            --i:setFillColor(r,g,b)
            i.id = a
            btns[a] = i

            local i = display.newImageRect("pig.png", 18,18); i.x = 104; i.y = 120 + (a*40);
            localGroup:insert(i)
            i:addEventListener("touch", touchBtn)
            --i:setFillColor(r,g,b)
            i.id = a
            btns[a].coin = i            -- load a button image with ID, add touch listener and position accordingly


            local t = display.newText(btnTxt[a], 0, 0, fontName[1], 10)
            t.x = 170; t.y = 118 + (a*40) + o
            t:setTextColor(255,255,255)
            localGroup:insert(t)
            shopText[a] = t          -- create text object for button image

              if a > 4 then i.alpha = 0; t.x = 160; end

        end
        if _G.paid == 1 then
            btns[5].alpha = 0
            shopText[5].alpha = 0
            btns[6].alpha = 0
            shopText[6].alpha = 0
        end                         -- if the user already paid don't shop the upgrade and restore buttons

    end

    createScreen()          -- call the function to create the shop screen


end

-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene(event)
    local group = self.view


end

-- Called immediately after scene has moved onscreen:
function scene:enterScene(event)
    local group = self.view


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
