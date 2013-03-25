module(..., package.seeall)


------------------------------------------------------------------
-- LIBRARIES
------------------------------------------------------------------

local storyboard = require("storyboard")
local scene = storyboard.newScene()


------------------------------------------------------------------
-- DISPLAY GROUPS
------------------------------------------------------------------

local localGroup = display.newGroup() -- overall display group


------------------------------------------------------------------
-- OBJECT DECLARATIONS
------------------------------------------------------------------

local bg                -- interstitial background image
local btns = {}         -- array to hold button images
local ptext = {}        -- array to hold text objects


---------------------------------------------------------------------------------
-- GAMEPLAY FUNCTIONS
---------------------------------------------------------------------------------

callbackFunction2 = function(state)         -- call back function to handle response from app store

    if (state == "purchased" or state == "restored") then

        if _G.bought == 2 then          -- if user upgraded

            onComplete = function()         -- function that runs after native alert has been closed by user
                storyboard.hideOverlay("slideLeft", 500)        -- close the in-app popup and return to app.lua
            end

            _G.paid = 1             -- set global variable to paid
            _G.hintTime = 2         -- reduce global variable for number of answers needed to get free hint
            settings.paid = 1
            hideAds()               -- call the global function in main.lua to hide whatever ads are showing
            settings:save()
            native.showAlert("Thank you", "You have successfully upgraded to the full version", { "OK" }, onComplete) -- show a native alrt
        end

    elseif (state == "cancelled") then

    elseif (state == "failed") then
    end
end


local touchButton = function(event)     -- function to handle touch events on ok and cancel butotons

    local obj = event.target            -- localise button that was pressed

    if event.phase == "ended" then

        if obj.id == 2 then             -- if ok button pressed

            doink(obj)                  -- animate button
            audio.play(sounds[8])       -- play click sound

            local buyThis = function(product)
                if store.canMakePurchases then
                    iap.buyItem2(callbackFunction2)     -- buy item2 and register call back function (as setup in iap.lua)
                else
                    native.showAlert("Store purchases are not available, please try again later", { "OK" })
                        -- show error message if store not available
                end
            end

            buyThis()
        end

        if obj.id == 1 then         -- if cancel button pressed
            _G.bought = 0           -- reset the bought global variable
            doink(obj)              -- animate button
            audio.play(sounds[9])   -- play click sound

            storyboard.hideOverlay("slideLeft", 500)        -- close the in-app popup and return control to app.lua
        end
    end
end

-- Called when the scene's view does not exist:
function scene:createScene(event)
    localGroup = self.view

    local createScreen = function()

        local i = display.newImageRect("optbg.png", 300, 360)
        i.x = 160; i.y = 250
        localGroup:insert(i)
        bg = i
        i.alpha = 0.98
        local r = math.random(100, 200)
        local g = math.random(80, 200)
        local b = math.random(120, 200)
        --i:setFillColor(r,g,b)               -- load background image and fill with random colours

        local i = display.newImageRect("red_btn.png", 90, 36); i.x = 90; i.y = 385;
        localGroup:insert(i)
        i:addEventListener("touch", touchButton)
        i.rotation = 0
        i.id = 1
        --i:setFillColor(255,0,0)
        btns[1] = i                     -- create cancel button with ID, add touch listener and fill with red colour

        local i = display.newImageRect("green_btn.png", 140, 46); i.x = 215; i.y = 385;
        localGroup:insert(i)
        i:addEventListener("touch", touchButton)
        i.rotation = 0
        i.id = 2
        --i:setFillColor(0,255,0)
        btns[2] = i                     -- create go button with ID, add touch listener and fill with green colour


        local t = display.newText("Cancel", 0, 0, fontName[1], 18)
        t.x = 90; t.y = 380 + o
        t:setTextColor(255,255,255)
        localGroup:insert(t)
        ptext[1] = t
        t.rotation = 0                  -- create text object for cancel buton

        local t = display.newText("Go!", 0, 0, fontName[1], 32)
        t.x = 215; t.y = 379 + o
        t:setTextColor(255,255,255)
        localGroup:insert(t)
        ptext[2] = t
        t.rotation = 0                  -- create text object for go button

        local t = display.newText("Remove", 0, 0, fontName[1], 36)
        t.x = 160; t.y = 105 + o
        t:setTextColor(255,200,0)
        localGroup:insert(t)
        ptext[3] = t
        t.rotation = 0

        local t = display.newText("Adverts!", 0, 0, fontName[1], 36)
        t.x = 160; t.y = 155 + o
        t:setTextColor(255,200,0)
        localGroup:insert(t)
        ptext[4] = t
        t.rotation = 0


        local t = display.newText("AND", 0, 0, fontName[1], 32)
        t.x = 160; t.y = 205 + o
        t:setTextColor(200,0,0)
        localGroup:insert(t)
        ptext[5] = t
        t.rotation = -1

         local t = display.newText(" * Unlock levels 11-20 !", 0, 0, fontName[1], 20)
        t.x = 160; t.y = 255 + o
        t:setTextColor(250,250,0)
        localGroup:insert(t)
        ptext[6] = t
        t.rotation = 0


        local t = display.newText("* 200 stars !", 0, 0, fontName[1], 20)
        t.x = 160; t.y = 285 + o
        t:setTextColor(255,255,255)
        localGroup:insert(t)
        ptext[7] = t
        t.rotation = 0

        local t = display.newText("* Free star every minute !", 0, 0, fontName[1], 20)
        t.x = 160; t.y = 315 + o
        t:setTextColor(250,250,0)
        localGroup:insert(t)
        ptext[8] = t
        t.rotation = 0
        t.alpha = 1

        local t = display.newText(" * Free star every minute!", 0, 0, fontName[1], 20)
        t.x = 160; t.y = 340 + o
        t:setTextColor(0)
        localGroup:insert(t)
        ptext[9] = t
        t.rotation = 0
        t.alpha = 0                 -- create text objects for the in-app popup


    end

    createScreen()      -- call the function to create the interstitial display objects


    ----------------------------------------------

    --      CREATE display objects and add them to 'group' here.
    --      Example use-case: Restore 'group' from previously saved state.

    -----------------------------------------------------------------------------
end

-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene(event)
    local group = self.view


    -----------------------------------------------------------------------------

    --      This event requires build 2012.782 or later.

    -----------------------------------------------------------------------------
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene(event)
    local group = self.view



    -----------------------------------------------------------------------------

    --      INSERT code here (e.g. start timers, load audio, start listeners, etc.)

    -----------------------------------------------------------------------------
end


-- Called when scene is about to move offscreen:
function scene:exitScene(event)
    local group = self.view


    -----------------------------------------------------------------------------

    --      INSERT code here (e.g. stop timers, remove listeners, unload sounds, etc.)

    -----------------------------------------------------------------------------
end

-- Called AFTER scene has finished moving offscreen:
function scene:didExitScene(event)
    local group = self.view

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
