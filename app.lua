module(..., package.seeall)


------------------------------------------------------------------
-- LIBRARIES
------------------------------------------------------------------

local storyboard = require("storyboard") -- load library to manage the scene
local scene = storyboard.newScene() -- create new scene
local GameRand = require"GameRand";


------------------------------------------------------------------
-- DISPLAY GROUPS
------------------------------------------------------------------

local localGroup = display.newGroup() -- overall display group
local logoGroup = display.newGroup() -- display group for logo images
local keyGroup = display.newGroup() -- display group for answer entry screen
local kbGroup = display.newGroup() -- display group for custom keyboard
local congratGroup = display.newGroup() -- display group for congratulations popup
local clueGroup = display.newGroup() -- display ground for clues section
local lupGroup = display.newGroup() -- display group for level up popup
local adGroup = display.newGroup() -- display group for in-house ad
local hudGroup = display.newGroup()
local bombGroup = display.newGroup()
local wordGroup = display.newGroup()
local afterGroup = display.newGroup()
local coinGroup = display.newGroup()

local tileGroup = display.newGroup()
local tilesGroup
local rowsGroup = {}
local insetGroup = {}


------------------------------------------------------------------
-- FORWARD DECLARATIONS							-- declare functions to avoid scope problems
------------------------------------------------------------------

local loadLogos

------------------------------------------------------------------
-- GGDATA VARIABLES								-- localise variables from disk storage
------------------------------------------------------------------

local ggLogos = GGData:new("logos")
local ggLevels = GGData:new("levels")
local ggClues = GGData:new("clueOrder")
local answersFile = GGData:new("answers")
local answers = answersFile.data
local thisAnswer = answers[1]


local rnd = GameRand()


local clueOrder = ggClues.data
local saved = ggLogos.data -- table of logo progress (saved is used as logos already used for images)
local hints = settings.hints -- number of hints the user has
local coins = settings.coins -- number of coins the user has
local totCoins = settings.coinTotal -- total coins used by player
local hintsUsed = settings.hintsUsed -- total hints used by player
local totGuesses = settings.guesses -- total guesses by player
local clicked = settings.clicked -- whether or not player clicked in-house advert yet
local wrong = settings.wrong -- number of wrong guesses by player
local nearly = settings.almost -- number of close guesses by player
local totalScore = settings.totalScore -- total score achieved by the player
local cLevel = settings.currentLevel -- current level being played
local lvls = ggLevels.data -- table of data for the levels
local solved = settings.solved -- number of logos solved by player
local unlocked = settings.unlocked -- last level unlocked by player


------------------------------------------------------------------
-- LOCAL VARIABLES
------------------------------------------------------------------

local numCols = 3 -- number of columns of logos on each page
local numRows = 3 -- number of rows of logos on each page
local useBorder = 0-- whether or not to use a border/background image for each logo
local bxSize = 86 -- X size of border images
local bySize = 86 -- Y size of border images
local yOffset = 24 -- Y axis offset of logo images
local xOffset = -44 -- X axis offset of logo images
local xSize = 104 -- X size of logo images
local ySize = 104 -- Y size of logo images
local xGap = 103 -- X gap between logo images
local yGap = 110 -- Y gap between logo images
local xIcon = 20 -- Amount to place tick/cross icons off-centre on X-axis from logos
local yIcon = 20 -- Amount to place tick/cross icons off-centre on Y-axis from logos
local url = "itms://itunes.com/apps/otterstudios/bandlogosquiz"
local data = require"data" -- load logos data from 'data.lua'
local adtog = 1 -- toggle between revmob and upgrade popups (1 = revmob, 2 = IAP)
local loading = false -- whether or not the logo images are currently being loaded
local canZoom = true -- whether or not the user is allowed to touch logo to zoom
local col = 1 -- column of next logo to load
local row = 1 -- row of next logo to load
local levels = data.levels -- will store table of information about levels from data.lua
local start = data.start -- will store table of where each level starts from data.lua
local nLevel = levels[cLevel] -- number of logos in this level
local sLevel = start[cLevel] -- first logo number in this level
local a = 1 -- next logo number to load
local logoNames = data.logoNames -- will store table of acceptable logo names from data.lua
local numLevels = #levels -- how many levels are in the game
local pages = 1 -- stores the number of pages of logos loaded
local page = 1 -- current page the user is viewing
local clues = data.clues -- will store table of clues from data.lua
local unlock = data.unlock -- will store of table of number of logos needed to unlock each level from data.lua
local order = data.order -- will store the order logos should be loaded from data.lua
local files = data.files -- will store the file names of the logos from data.lua
local startTime = 0 -- start time of a swipe movement
local cNum = 1 -- number of the current logo being answered
local cId -- ID number of the logo image of the current logo being answered
local stage = "prepare" -- current stage of the game
local leng = 0 -- length of the current word being entered
local keyState = "abc" -- whether or not the custom keyboard is in ABC or 123 mode
local moving = false -- whether or not the user is currently moving their finger across the screen
local storedStage       -- stores the current game stage when something interrupts it
local bomb = {}
local secTimer = system.getTimer()

local cols = { math.random(150, 250), math.random(150, 250), math.random(150, 250) }

if math.abs(cols[1] - cols[2]) < 30 then cols[2] = cols[2] - 50; end
if math.abs(cols[1] - cols[3]) < 30 then
    cols[3] = cols[3] + 50
    if cols[3] > 255 then cols[3] = 255; end
end


------------------------------------------------------------------
-- OBJECT DECLARATIONS
------------------------------------------------------------------

local tl = {}
local after = {}
local adImage = {} -- array to store in-house advert images
local hintBtn -- button image to open hints section
local hintBtnText -- text for hints section button
local solveBtn -- solve logo button image
local solveBtnText -- text for solve logo button
local zoomText -- text object for zooming into logo
local pageText -- text object for current / max pages
local shades = {} -- store shaded versions of logo images (when completed)
local bg -- main background image
local levelText -- text for current level being played
local bigbox -- border image for large logo on entry screen
local rect = {} -- array for newRect images
local back -- back arrow image
local hintText -- text object for number of hints remaining
local coinText -- text object for number of coins remaining
local key = {} -- custom keyboard key images
local keyText = {} -- custom keyboard text objects
local cursor -- cursor image object
local almost -- image displayed on entry screen when an answer is close
local lupBg -- background image for level up popup
local lupText = {} -- array for text objects on level up popup
local fbBtn -- button image to post logo on facebook wall
local fbText -- text object for facebook button
local logos = {} -- array for logo images
local hintIcon -- image for hint icon
local coinIcon -- image for coin icon
local ticks = {} -- array of tick images for each logo
local crosses = {} -- array of cross images for each logo
local almosts = {} -- array of 'almost' icons for each logo
local entry -- image for text entry box
local keyBg -- image for entry screen background
local word -- text object of the answer currently being entered
local cross -- image of cross for deleting of entire answer
local nocross -- image of cross for entry screen when the last answer was wrong
local conbg -- background image for congratulations popup
local conText = {} -- array of text objects for congrats popup
local bigLogo -- large logo image for entry screen
local concl -- rect object to close congrats popup
local cluebg -- background image for clues popup
local dispOrd = {} -- table to hold random order to display the logos on screen
local clueText = {} -- array of text objects for clues
local clueBtn = {} -- array of clue button images
local clueBtnText = {} -- array of text objects for clue buttons
local testText -- debug text



---------------------------------------------------------------------------------
-- GAMEPLAY FUNCTIONS
---------------------------------------------------------------------------------

local showShop = function ()

audio.play(sounds[9])

        transition.to(localGroup, { time = 500, alpha = 0.2 })      -- darken menu screen

        local options =
        {
            effect = "fromLeft",
            time = 400,
            isModal = true
        }

        storyboard.showOverlay("shop", options)     -- load the options screen as an overlay
end

local loadShop = function (event)

    if event.phase == "ended" then

        showShop()

    end
end



local levelUp = function() -- display level up popup message

    lupText[1].text = "Congratulations!"

    if unlocked < numLevels + 1 then
        lupText[2].text = "You just unlocked Level " .. unlocked .. " !" -- update text appropriately
    else
        lupText[2].text = "You Completed The Game!!"
    end

    lupGroup:toFront() -- bring group to front of display
    local red = math.random(50, 200)
    local blue = math.random(50, 200)
    local green = math.random(50, 200) -- choose a random colour

    --lupBg:setFillColor(red, blue, green) -- fill the background with random colour

    transition.to(lupGroup, { y = 100, time = 2000, alpha = 0.95 }) -- fade in and down the popup
    transition.to(lupGroup, { y = 100, delay = 4000, time = 1500, alpha = 0 }) -- fade out after delay
    transition.to(lupGroup, { y = -100, delay = 8000, time = 10 }) -- move back off screen after faded
    audio.play(sounds.levelup) -- play level up sound
end





local saveAll = function()

    settings:save()
    ggLogos:save()
    ggLevels:save()
end

local resetClues = function() -- returns clue screen objects to their correct positions and moves clue screen off-screen

    transition.to(clueGroup, { time = 700, x = 400, transition = easing.inOutExpo })
    transition.to(bigLogo, { rotation = 0, time = 700, x = 240, xScale = 1, yScale = 1, transition = easing.inOutExpo })
    transition.to(bigbox, { rotation = 0, time = 700, x = 240, xScale = 1, yScale = 1, transition = easing.inOutExpo })
    transition.to(fbBtn, { time = 700, x = 90, transition = easing.inOutExpo })
    transition.to(fbText, { time = 700, x = 90, transition = easing.inOutExpo })
    transition.to(hintBtn, { time = 700, x = 90, transition = easing.inOutExpo })
    transition.to(hintBtnText, { time = 700, x = 90, transition = easing.inOutExpo })
    transition.to(solveBtn, { time = 700, x = 90, transition = easing.inOutExpo })
    transition.to(solveBtnText, { time = 700, x = 90, transition = easing.inOutExpo })
end



local everySecond = function ()

secTimer = system.getTimer()

--print (stage)

    if stage == "enter" then

        coins = settings.coins
         coinText.text = coins
         --hud.coinText2.text = coins
    --print (occupied)


    saved[cNum].score = saved[cNum].score - 1

    if saved[cNum].score < 0 then saved[cNum].score = 0 ; end
    saved[cNum].time = saved[cNum].time + 1
    --print (levels[cLevel].score)


   else

   --print (stage)



   end


end



local afterScreen = function ()

    local hrs = math.floor(saved[cNum].time/3600)

    local rem = saved[cNum].time - (hrs * 3600)


    local mins = math.floor(rem/60)
    local sec = saved[cNum].time - (mins*60) - (hrs * 3600)

    if sec < 10 then sec = "0"..sec; end
    if mins < 10 then mins = "0"..mins; end

    local earned = 5

    if saved[cNum].score < 950 then earned = 4; end
    if saved[cNum].score < 850 then earned = 3; end
    if saved[cNum].score < 650 then earned = 2; end
    if saved[cNum].score < 350 then earned = 1; end

    settings.coinTotal = settings.coinTotal + earned

    --settings.totalScore = settings.totalScore + saved[cNum].score

    print ("total: "..settings.totalScore)

    if _G.osTarget == "iOS" then gameNetwork.request("setHighScore", { localPlayerScore = { value = tonumber(settings.totalScore), category = "kOverall13" } }); end


    local tat = {hrs..":"..mins..":"..sec, saved[cNum].revealed, saved[cNum].removed, saved[cNum].wrong, saved[cNum].score}

    for a =1, 5, 1 do

        after[a].txt.text = tat[a]
            after[a].txt:setReferencePoint(display.CenterLeftReferencePoint)
            after[a].txt.x = 200

            --if a== 5 then after[a].txt:setTextColor(255,255,255); end
    end

    display.remove(coinGroup)
    coinGroup = display.newGroup()

    for a = 1, earned, 1 do

            local i = display.newImageRect("pig.png", 32,32) -- load and position the border image
            i.x = (50 * a) ; i.y = 0; i.alpha = 1
            after.coins[a] = i
            coinGroup:insert(i)
            i:setFillColor(0,255,0)

            local rt = 0

            transition.to(i, {rotation = rt, time = 100, delay = 200+100 * a, x = 480+ (50 * a), y = 396, transition = easing.inOutExpo})

            local coinText = function ()

                coins = coins + 1
                settings.coins = coins
                coinText.text = coins
                coinText.text = coins
                audio.play(sounds.coinup)
                settings:save()

            end

            local playSound = function ()

                swipe()

            end

            timer.performWithDelay(100+ 150 * a, playSound)

            transition.to(i, {time = 300, delay = 1500+150 * a, x = 480+ 280, y = 20- yO*2, xScale = 0.3, yScale =0.3, alpha = 0,transition = easing.inOutExpo,onComplete = coinText})

             timer.performWithDelay(1500+ 150 * a, playSound)

    end

    transition.to(after.button, {alpha = 1, delay = 2600, time =300, transition = easing.inOutExpo})
        transition.to(after.txt1, {alpha = 1, delay = 2600, time =300, transition = easing.inOutExpo})
                transition.to(after.txt2, {alpha = 1, delay = 2600, time =300, transition = easing.inOutExpo})
    coinGroup:setReferencePoint(display.CenterReferencePoint)
    coinGroup.x = -320
    afterGroup:insert(coinGroup)


    settings:save()



end


local updateLevel = function() -- function to update the level after a correct answer has been given


    audio.play(sounds.solved) -- play logo solved sound
    solved = solved + 1 -- increment total solved variable
    settings.solved = solved -- store in database

    local nextunlock = unlock[unlocked] -- get number of logos needed to unlock the next level

    lvls[cLevel]["solved"] = lvls[cLevel]["solved"] + 1 -- increment number of logos solved on this level

    for a = 1, unlocked, 1 do
        lvls[a]["open"] = 1 -- failsafe in case a level did not unlock correctly before
    end

    if solved >= nextunlock then -- check if next level unlocked

        timer.performWithDelay(2500, levelUp) -- show level up message after delay
        unlocked = unlocked + 1 -- increment number of unlocked levels
        settings.unlocked = unlocked -- store in database
        lvls[unlocked]["open"] = 1 -- unlock next level
    end

    afterGroup:toFront()


    transition.to(afterGroup, { time = 700, x = 0, rotation = 0, transition = easing.outExpo }) -- show congrats popup
    transition.to(tileGroup, { time = 700, x = -600, transition = easing.inOutExpo })
    transition.to(bigLogo, { delay = 200, time = 1800, xScale = 1, yScale = 1, x = 160, rotation = 0, transition = easing.outExpo })
    transition.to(bigbox, { rotation = 0, delay = 200, time = 1800, xScale = 1, yScale = 1, x = 160, rotation = 0, transition = easing.outExpo })
     transition.to(word.bomb, { alpha = 0, time = 400})
     transition.to(word.fb, { alpha = 0, time = 400})
    --transition.to(fbText, { rotation = 0, delay = 100, time = 1200, x = -200, rotation = 0, transition = easing.outExpo })
    --transition.to(fbBtn, { delay = 100, time = 1200, x = -200, rotation = 0, transition = easing.outExpo })
    --transition.to(hintBtnText, { delay = 100, time = 1200, x = -200, rotation = 0, transition = easing.outExpo })
    --transition.to(hintBtn, { delay = 100, time = 1200, x = -200, rotation = 0, transition = easing.outExpo })
    --transition.to(solveBtnText, { delay = 100, time = 1200, x = -200, rotation = 0, transition = easing.outExpo })
    --transition.to(solveBtn, { delay = 100, time = 1200, x = -200, rotation = 0, transition = easing.outExpo })
    transition.to(zoomText, { delay = 100, time = 1200, x = 160, rotation = 0, transition = easing.outExpo }) -- move everything into the right place

    --word.text = logoNames[cNum][1] -- show the full name (in case the player guessed a variation)
    --kbGroup.alpha = 0 -- hide the keyboard
    --cursor.x = 600 -- move cursor off screen
    --cross.alpha = 0 -- hide delete cross
    --nocross.alpha = 0 -- hide incorrect cross
    --almost.alpha = 0 -- hide almost icon
    stage = "correct" -- set game status

    --logos[cId]:setFillColor(gray) -- set the logo to grey
    logos[cId].alpha = 1 -- set logo to see through
    ticks[cId].alpha = 1 -- show the tick icon for this logo
    crosses[cId].alpha = 0 -- hide the cross icon
    almosts[cId].alpha = 0 -- hide the almost icon
    shades[cId]:setFillColor(gray)
    shades[cId].alpha = 0.5 -- show the shadow image


    local red = math.random(50, 200)
    local blue = math.random(50, 200)
    local green = math.random(50, 200) -- get a random colour and fill the congrats popup background
    --conbg:setFillColor(red, blue, green)

    if saved[cNum]["score"] > 750 then -- check if player scored 750 or more on this logo

        transition.to(coinIcon, { rotation = 11, delay = 1000, time = 500, xScale = 1.3, yScale = 1.6, transition = easing.inOutExpo })
        transition.to(coinIcon, { rotation = -11, delay = 1500, time = 300, xScale = 1.0, yScale = 1.0, transition = easing.inOutExpo }) -- animate coin icon

        local playIt2 = function()
            audio.play(sounds.coinup)
        end

        timer.performWithDelay(1100, playIt2) -- play coin sound after delay

        --coins = coins + 1 -- add 1 to coins
        --totCoins = totCoins + 1 -- add 1 to total coins earned
        --settings.coinTotal = totCoins -- store in DB
        --settings.coins = coins -- store in DC
        --coinText.text = coins -- update coin text display
    end


    _G.adCount = _G.adCount + 1 -- increment ad count

    if _G.adCount == 12 then -- check if 12 correct answers have been given, if so show advert

        timer.performWithDelay(4000, delayIt)

        _G.adCount = 0 -- reset ad count
    end


    --_G.hintCount = _G.hintCount + 1 -- increment hint count

    if _G.hintCount == _G.hintTime then -- check if enough correct answers given to award hint

        _G.hintCount = 0 -- reset hint count
        --coins = coins + 1 -- add 1 to hints
        settings.coins = coins -- store in DB
        coinText.text = coins -- update hint text display

        transition.to(coinIcon, { rotation = 8, delay = 1400, time = 500, xScale = 1.6, yScale = 1.3, transition = easing.inOutExpo })
        transition.to(coinIcon, { rotation = -11, delay = 1900, time = 300, xScale = 1.0, yScale = 1.0, transition = easing.inOutExpo }) -- animate hint icon

        local playIt = function()
            audio.play(sounds.hintup)
        end

        timer.performWithDelay(1600, playIt) -- play hint sound after delay (after coin sound)
    end

    saved[cNum]["solved"] = 1 -- set this logo to solved

    --conText[2].text = "Score: " .. saved[cNum]["score"] -- update score on congrats popup
    lvls[cLevel]["score"] = lvls[cLevel]["score"] + saved[cNum]["score"] -- increase score for this level
    totalScore = totalScore + saved[cNum]["score"] -- increase total score for game
    settings.totalScore = totalScore


    gameNetwork.request("setHighScore", { localPlayerScore = { value = tonumber(totalScore), category = "games_overall" } }) -- post score to game center

    afterScreen()
    saveAll() -- save database to disk
end




local pressClue = function(event) -- handles touch events on clue screen buttons

    local obj = event.target -- localise the touched button to obj
    local used = saved[cNum]["hints"] -- get the number of hints used so far on this logo

    if event.phase == "ended" and obj.id == 4 then -- if close button pressed

        resetClues() -- move clue screen off-screen and reset objects
        audio.play(sounds[10]) -- play a click sound
        swipe() -- play a random swipe sound
    end

    if event.phase == "ended" and obj.id < 4 and hints == 0 then -- check if user has enough hints, if not display message
        local alert = native.showAlert("Sorry!", "You do not have enough hints, you can buy some in the store on the main menu...", { "OK" })
    end

    if event.phase == "ended" and obj.id < 4 and obj.id == (used + 1) and hints > 0 then

        if used < 4 then

            local ord1 = clueOrder[cNum][1] -- get the ID of the first clue for this logo
            local ord2 = clueOrder[cNum][2] -- get the ID of the second clue for this logo
            local ord3 = clueOrder[cNum][3] -- get the ID of the thid clue for this logo

            if used == 0 then -- if no clues used yet
                clueText[1].text = clues[cNum][ord1] -- display first clue
                clueBtn[1].alpha = 0.2 -- dim first clue button
                clueBtn[2].alpha = 0.9 -- light up second clue button
            end

            if used == 1 then -- if one clue used
                clueText[2].text = clues[cNum][ord2] -- display second clue
                clueBtn[2].alpha = 0.2 -- dim second clue
                clueBtn[3].alpha = 0.9 -- light up third clue button
            end

            if used == 2 then
                clueText[3].text = clues[cNum][ord3] -- display third clue
                clueBtn[3].alpha = 0.2 -- dim third clue button
            end

            saved[cNum]["hints"] = saved[cNum]["hints"] + 1 -- increment number of hints used on this logo

            hintsUsed = hintsUsed + 1 -- increment total number of hints used
            settings.hintsUsed = hintsUsed -- store in GGdata
            hints = hints - 1 -- reduce user's hints by 1
            settings.hints = hints -- store in GGdata
            hintText.text = hints -- update hint text object

            saved[cNum]["score"] = saved[cNum]["score"] - 75 * (1 + (used + 1)) -- reduce score on this logo
            saveAll() -- save to disk

            transition.to(hintIcon, { rotation = -8, delay = 300, time = 500, xScale = 1.3, yScale = 1.3, transition = easing.inOutExpo })
            transition.to(hintIcon, { rotation = 11, delay = 800, time = 300, xScale = 1.0, yScale = 1.0, transition = easing.inOutExpo })
            -- animate hintIcon to highlight one has been used
            local playIt = function()
                audio.play(sounds.hintup)
            end

            audio.play(sounds[8]) -- play a tap sound
            timer.performWithDelay(600, playIt) -- play the hint sound after a short delay
        end
    end
end

local closeCongrats = function() -- function to close the congrats screen (triggered by 'back' or 'done' buttons)

    audio.play(sounds[7]) -- play a click sound
    swipe() -- play a swipe sound

    transition.to(keyGroup, { time = 700, x = 700, transition = easing.inOutExpo })
    tileGroup.x = 0

    local reset = function()
        stage = "choose"

            display.remove(tileGroup)
            tileGroup = nil
            tilesGroup = nil

        timer.performWithDelay(400, reset) -- after a short delay, set game status
    end

    timer.performWithDelay(700, reset) -- after a delay to allow stuff to move off-screen, change game status back to 'choose'
end



local congratCloseTouch = function(event) -- function to handle touch events for the 'done' button on the congrats screen

    local obj = event.target

    if event.phase == "ended" then

        doink(obj) -- animate button
        closeCongrats() -- call function to close the congrats screen
    end
end



local callIap = function() -- displays the in-app purchase screen (pop.lua) as a storyboard overlay

    if _G.osTarget == "iOS" then
    transition.to(localGroup, { time = 500, alpha = 0.8 }) -- darken game screen slightly

    local options =
    {
        effect = "fromLeft",
        time = 400,
        isModal = true
    }

    storyboard.showOverlay("pop", options) -- show in-app screen

    else

    end
end



local calcOpenSlots = function ()


    local ok = 0

    for a = 1, tl.wLeng, 1 do

        if tl.insets[a].letter == true then

        if tl.insets[a].txt.text == "" and ok == 0 and tl.insets[a].revealed ~= true then

            tl.nextOpen = a
            ok = 1

        end

        end

    end

end




local checkAnswer = function ()

        totGuesses = totGuesses + 1
        settings.guesses = totGuesses

    if tl.answer == tl.word then



        stage = "complete"

          if saved[cNum]["score"] < 0 then saved[cNum]["score"] = 50; end -- if score went below zero due to previous actions, set to 50

          updateLevel() -- call function to update game after correct answer

        --native.showAlert("Complete","That's correct",{"OK"}, finishLevel)
        --audio.play(sounds.solved)

        --transition.to(mainGroup, {alpha = 0.15, time = 300, transition = easing.inOutExpo})
        --transition.to(afterGroup, {y=0, time = 400, transition = easing.inOutExpo})

        --afterScreen()


    else

        for a = 1, tl.wLeng, 1 do

            if tl.insets[a].revealed ~= true then
                tl.insets[a].txt:setTextColor(150,0,0)
            end
        end

        local resetBack = function ()

            for a = 1, tl.wLeng, 1 do


                if tl.insets[a].revealed ~= true then
                    tl.insets[a].txt:setTextColor(0,0,0)
                end
            end
        end

        saved[cNum].score = saved[cNum].score - 50
         saved[cNum].wrong = saved[cNum].wrong + 1
        wrong = wrong + 1
        settings.wrong = wrong
        if saved[cNum].score < 0 then saved[cNum].score = 0; end
        saveAll()

        timer.performWithDelay(1500, resetBack)

        transition.to(localGroup, { time = 100, x = 5, y = 5 }) -- start of shake screen effect


        for a = 1, 3, 1 do
            transition.to(localGroup, { delay = 0 + (120 * a), time = 40, x = 3, y = 3 })
            transition.to(localGroup, { delay = 40 + (120 * a), time = 40, x = -3, y = 3 })
            transition.to(localGroup, { delay = 80 + (120 * a), time = 40, x = 0, y = 0 })

        end


        audio.play(sounds.wrong)

    end

end


local showRevealed = function ()

    --thisAnswer[1] = 1
    --thisAnswer[3] = 1

    local cnt = 0
   -- print (tl.wLeng)

    for a = 1, tl.wLeng, 1 do

        if tl.insets[a].letter == true then cnt = cnt + 1; end

            if thisAnswer[a] == 1  then

                --print ("Revealed: "..a)
                tl.insets[a].txt.text = tl.wordArray[a]

                if stage ~= "bombdemo" and stage ~= "welcome" then
                    tl.insets[a].txt:setTextColor(0,100,0)
                end

                if stage == "bombdemo" or stage == "welcome" then
                audio.play(sounds[11])

                end

                tl.insets[a].active = false
                tl.insets[a].revealed = true

                --if insets[a].letter == true then cnt = cnt + 1; end

                for b = 1, #tl.tiles, 1 do

                    --print (tiles[b].orig.." "..cnt.." "..tiles[b].txt1.text)

                    if tl.tiles[b].orig == cnt then

                        tl.tiles[b].alpha = 0
                        tl.tiles[b].txt1.alpha = 0
                        tl.tiles[b].txt2.alpha = 0

                    end

                end

            end

    end

    calcOpenSlots()



end






local hintUp = function() -- shows a popup when user earns a free hint through gameplay time (re-uses level-up popup)
--
--    lupText[1].text = "Free Hint" -- alter the text on the level up popup
--    lupText[2].text = "Thanks for playing!"
--
--    lupGroup:toFront() -- bring group to front of display
--    local red = math.random(50, 200)
--    local blue = math.random(50, 200)
--    local green = math.random(50, 200) -- create a random colour
--
--    ---lupBg:setFillColor(red, blue, green) -- fill the background with the random colour
--
--    transition.to(lupGroup, { y = 100, time = 1200, alpha = 0.95 }) -- fade in and down the popup
--    transition.to(lupGroup, { y = 100, delay = 3000, time = 1000, alpha = 0 }) -- fade out the popup
--    transition.to(lupGroup, { y = -100, delay = 4000, time = 10 }) -- move the popup back off the screen at the end
--    audio.play(sounds.hintup) -- play the hint sound
end



local function gameLoop() -- enterFrame listener, runs once every frame

    if stage == "enter" or stage == "bomb" then tl.occupied = 0

        for a = 1, tl.wLeng, 1 do

            if tl.insets[a].letter == true then

                if tl.insets[a].txt.text ~= "" then
                    tl.occupied = tl.occupied + 1
                end

            end

        end

    end

        if stage == "bomb" then

            if tl.wLengSh - tl.occupied  == 1 then
                bomb[3].alpha = 0.3
            else
                bomb[3].alpha = 1
            end

            if tl.wLengSh + saved[cNum].removed == tl.bLeng then
                bomb[2].alpha = 0.3

                --print ("removed: "..saved[cNum].removed)
            else
                bomb[2].alpha = 1
            end

            if saved[cNum].category == 1 then
                bomb[1].alpha = 0.3
            else
                bomb[1].alpha = 1
            end
        end






    if loading then
        loadLogos() -- if game is in loading mode, run the loadLogos function
    end

    if keyGroup.x == 0 and stage ~= "correct" and stage ~= "zoomed" and stage ~= "bomb" then stage = "enter"; end -- handle odd cases where stage is wrong


    local t = system.getTimer() -- get the current time


    if _G.paid == 0 and t - _G.adTimer > 1000000 and clicked == 0 and _G.osTarget ~= "Amazon" then -- display in-house ad every 16.6 minutes

        adGroup:toFront() -- bring ad group to front of display

        _G.adTimer = system.getTimer() --  reset the timer

        storedStage = stage -- remember which stage the game is in
        stage = "ad" -- set the stage to 'ad' to stop other touches/actions

        transition.to(adGroup, { time = 600, x = 0, transition = easing.inOutExpo }) -- slide in the ad
    end


        if t - secTimer > 1000 then

            everySecond()

        end


    if t - _G.revTimer > 500000 and _G.paid == 0 and _G.revShow == 1 then -- display revmob interstitial every 8 minutes if in free mode

        RevMob.showFullscreen() -- show the interstitial

        _G.revTimer = system.getTimer() -- reset the timer
    end

    local cup = 120000

    if _G.paid == 1 then cup = 60000; end

    if t - _G.startTime > cup then -- give the user a free hint every 5 minutes

        _G.startTime = system.getTimer() -- reset time

        settings.coins = settings.coins + 1 -- increment stored hints by 1
        saveAll() -- save to disk

        if coins then coins = coins + 1; end -- increment local hints variable by 1
        if coinText then coinText.text = coins; end -- update hint icon text

        hintUp() -- run function to display popup message
    end
end


local calcAnswer = function ()

    tl.answer = ""
    tl.aLeng = 0

    for a = 1, tl.wLeng, 1 do

        tl.answer = tl.answer..tl.insets[a].txt.text

        if tl.insets[a].txt.text ~= "" then tl.aLeng = tl.aLeng + 1; end

    end


end


local delayIt = function() -- function to display either revmob interstitial or in-app advert every X correct answers

    if _G.paid == 0 and _G.osTarget == "iOS" then

        if adtog == 1 then
            adtog = 2
            if revShow == 1 then RevMob.showFullscreen(); end -- show revmob popup or in-app ad depending on adtog state
        else
            adtog = 1
            callIap()
        end
    end
end



local calcOpenSlots = function ()


    local ok = 0

    for a = 1, tl.wLeng, 1 do

        if tl.insets[a].letter == true then

        if tl.insets[a].txt.text == "" and ok == 0 and tl.insets[a].revealed ~= true then

            tl.nextOpen = a
            ok = 1

        end

        end

    end

end


local hideRemoved = function ()

    local removed = saved[cNum].removed

    --print ("removed"..removed)

    if removed > 0 then

        for a = 1, tl.bLeng, 1 do

            for b = tl.wLengSh + 1, tl.wLengSh+ removed, 1 do

                if tl.tiles[a].orig == b then

                    tl.tiles[a].alpha = 0
                    tl.tiles[a].txt1.alpha = 0
                    tl.tiles[a].txt2.alpha = 0

                end
            end
        end

    end

end




local touchInset = function (event)

    local obj = event.target

    if event.phase == "ended" and obj.active == true and stage == "enter" then

        local id = obj.fill

            swipe()
             saved[cNum].score = saved[cNum].score - 1
            if saved[cNum].score < 0 then saved[cNum].score = 0; end

            obj.txt.text = ""
            obj.active = false

            tl.answer = string.sub(tl.answer, 1, tl.aLeng -1)

            transition.to(tl.tiles[id], {alpha = 1, xScale = 1, yScale = 1, time = 400, transition = easing.inOutExpo})
            transition.to(tl.tiles[id].txt1, {alpha = 1, xScale = 1, yScale = 1, time = 400, transition = easing.inOutExpo})
            transition.to(tl.tiles[id].txt2, {alpha = 1, xScale = 1, yScale = 1, time = 400, transition = easing.inOutExpo})
            tl.tiles[id].active = true



            calcOpenSlots()
            --timer.performWithDelay(450, hideRemoved)
            calcAnswer()
           -- print(answer)

    end

end
local touchFb = function (event)

    local obj = event.target

     if event.phase == "ended" and stage == "enter" then

        doink(obj)
        audio.play(sounds[9])

        settings.photo = settings.photo + 1
        settings:save()

        local baseDir = system.TemporaryDirectory
        display.save( localGroup, "screenshot"..settings.photo..".jpg", baseDir )

        --local i = display.newImageRect("screenshot.jpg",baseDir, 320,480) i.x = 140 i.y = 240

       _G.fbType = "logo" -- set the type of facebook posting to make

        local function onComplete(event)
            if "clicked" == event.action then
                local i = event.index
                if 2 == i then
                elseif 1 == i then
                    postmymsg() -- call function to post on facebook wall (in main.lua)
                end
            end
        end

        native.showAlert("Ask your friends for help!", "Post this shirt on your wall?",
            { "Yes please", "No thanks" }, onComplete) -- show a native popup

     end



end



local touchHelp = function (event)


    local obj = event.target

    --print (obj.id)

    if event.phase == "ended" and stage == "bomb" then

        if obj.alpha == 1 then
        doink(obj)
        audio.play(sounds[9])
        end

        --stage = "enter"


        local closeBox = function ()

        swipe()

            transition.to(localGroup, {alpha = 1, time = 500, transition = easing.inOutQuad})
            transition.to(bombGroup, {x = 600, time = 500, transition = easing.inOutQuad})
            stage = "enter"
        end

        local updateCoins = function ()

            coins = coins - obj.cost
            settings.coinSpent = settings.coinSpent + obj.cost
            settings.coins = coins
            coinText.text = coins
            --hud.coinText2.text = coins

        end


        if obj.id == 1 and obj.alpha == 1 then

            saved[cNum].category = 1
            word.cat.text = clues[cNum][1]
            transition.to(word.cat, {delay = 500, time = 500, alpha = 1, transition = easing.inOutExpo})

            saved[cNum].score = saved[cNum].score - 30
            if saved[cNum].score < 0 then saved[cNum].score = 0; end
            updateCoins()
            saveAll()
            timer.performWithDelay(100,closeBox)

        end

        if obj.id < 5 and obj.alpha == 1 then

        doink(bomb[obj.id].txt1)
        doink(bomb[obj.id].txt2)
        doink(bomb[obj.id].coin)
        doink(bomb[obj.id].cost1)
        doink(bomb[obj.id].cost2)

        end

        if coins > obj.cost then

        if obj.id == 2 and saved[cNum].removed < tl.extra then

            local left = tl.extra - saved[cNum].removed
            local remove = 3
            if left < 3 then remove = left; end

           saved[cNum].removed = saved[cNum].removed + remove

            saved[cNum].score = saved[cNum].score - 75
            if saved[cNum].score < 0 then saved[cNum].score = 0; end
            updateCoins()
            saveAll()


            timer.performWithDelay(1000,hideRemoved)


            timer.performWithDelay(100,closeBox)
            --tage = "main"


        end



        if obj.id == 3 and tl.occupied < tl.wLeng - 1 then

            local ok = 0
            local ch

            while ok == 0 do

                ch = math.random(1,tl.wLeng)

                if thisAnswer[ch] == 0 and tl.insets[ch].letter == true and tl.insets[ch].txt.text == "" then
                    ok = 1


                end

            end


            saved[cNum].revealed = saved[cNum].revealed + 1
            saved[cNum].score = saved[cNum].score - 50
            if saved[cNum].score < 0 then saved[cNum].score = 0; end

            thisAnswer[ch] = 1
            showRevealed()
            updateCoins()
            saveAll()


              timer.performWithDelay(50,closeBox)
            --stage = "main"
        end

        if obj.id == 4 then

            tl.answer = tl.word
            for a = 1, tl.wLeng, 1 do
                if tl.insets[a].letter == true then thisAnswer[a] = 1; end
            end
            saved[cNum].score = 0
            showRevealed()
            updateCoins()
            settings.skipped = settings.skipped + 1
            saveAll()

            timer.performWithDelay(1200, checkAnswer)


            --transition.to(bombGroup, {x = 600, time = 500, transition = easing.inOutQuad})
            timer.performWithDelay(50,closeBox)




        end


        if obj.id == 5 then

          timer.performWithDelay(50,closeBox)

        end

        else

        local function onComplete(event)
            if "clicked" == event.action then
                local i = event.index
                if 2 == i then
                elseif 1 == i then
                    timer.performWithDelay(50,closeBox)
                    timer.performWithDelay(100,showShop)
                end
            end
        end

        native.showAlert("Sorry!","You haven't got enough stars. Do you want to buy some now?",{"Ok!","No thanks!"},onComplete)


        end


    end


end


local touchBomb = function (event)

    local obj = event.target

     if event.phase == "ended" and stage == "enter" then

        stage = "bomb"

        bombGroup:toFront()


        doink(obj)
        audio.play(sounds[7])
        swipe()

        transition.to(localGroup, {alpha = 0.2, time = 500, transition = easing.inOutQuad})
        transition.to(bombGroup, {x = 0, time = 500, transition = easing.inOutQuad})



     end


end


local touchPhoto = function (event)


    local obj = event.target

     local oth1 = 1; local oth2 = 2
        if obj.id == 2 then oth1 = 1; oth2 = 3; end
        if obj.id == 1 then oth1 = 2; oth2 = 3; end


    if event.phase == "ended" and stage == "main" and obj.zoomed == false and _G.firstRun == false then


        stage = "zoomed"
        obj.zoomed = true
        obj.xPrev = obj.x
        obj.yPrev = obj.y
    --    print(obj.photo.x)
    --    print(obj.photo.y)

        obj:toFront()
        transition.to(obj, {time = 800, xScale = 2, yScale =2, x = -obj.photo.x + (148-(obj.photo.x)), y = -obj.photo.y + (240 - (obj.photo.y)),transition = easing.inOutExpo})
         --transition.to(obj.frame, {xScale = 2, yScale =2, x = 160, y = 240})
         transition.to(localGroup, {time = 800, alpha = 0.15,transition = easing.inOutExpo})
         transition.to(photos[oth1], {time = 800, alpha = 0.15,transition = easing.inOutExpo})
          transition.to(photos[oth2], {time = 800, alpha = 0.15,transition = easing.inOutExpo})
    else


    if event.phase == "ended" and stage == "zoomed" and obj.zoomed == true then

        obj.zoomed = false
        stage = "main"
        obj.xPrev = obj.x
        obj.yPrev = obj.y
    --    print(obj.photo.x)
    --    g(obj.photo.y)

        obj:toFront()
        transition.to(obj, {time = 800, xScale = 1, yScale =1, x = 0, y = 0,transition = easing.inOutExpo})
         --transition.to(obj.frame, {xScale = 2, yScale =2, x = 160, y = 240})
         transition.to(localGroup, {time = 800, alpha = 1,transition = easing.inOutExpo})
         transition.to(photos[oth1], {time = 800, alpha = 1,transition = easing.inOutExpo})
          transition.to(photos[oth2], {time = 800, alpha = 1,transition = easing.inOutExpo})
    end

    end

    return true

end


local touchNext = function (event)

      local obj = event.target

    if event.phase == "ended" then

        audio.play(sounds[9])
        doink(obj)
        closeCongrats()

    end

end

local touchLetter = function (event)

    local obj = event.target

    if event.phase == "ended" and obj.active == true and stage == "enter"  then


        if tl.aLeng < tl.wLeng then

            audio.play(sounds[11])
            tl.insets[tl.nextOpen].txt.text = obj.value
            obj.active = false

            tl.answer = tl.answer..obj.value


            transition.to(obj, {alpha = 0, xScale = 0.1, yScale = 0.1, time = 400, transition = easing.inOutExpo})
            transition.to(obj.txt1, {alpha = 0, xScale = 0.1, yScale = 0.1, time = 400, transition = easing.inOutExpo})
            transition.to(obj.txt2, {alpha = 0, xScale = 0.1, yScale = 0.1, time = 400, transition = easing.inOutExpo})


            tl.insets[tl.nextOpen].fill = obj.id
            tl.insets[tl.nextOpen].active = true


            calcOpenSlots()
            calcAnswer()

            if tl.aLeng == tl.wLeng then checkAnswer(); end
    --        print(answer)
    --        print(nextOpen)
    --        print(aLeng)
        end

    end

end




local touchBig = function(event) -- handles touching of the big logo on entry screen (zooming)

    local obj = event.target

    if event.phase == "ended" and (stage == "ente" or stage == "corret") and obj.xScale == 1 and canZoom == true then -- check conditions OK for zooming

        storedStage = stage -- remember the current game state
        canZoom = false -- cannot zoom (stops clicking the logo again before it is in place)
        audio.play(sounds[7]) -- play click sound

        local resetZoom = function()
            canZoom = true
        end

        timer.performWithDelay(800, resetZoom) -- allow touches again after short delay


        local delayW = function()
            audio.play(sounds.woosh) -- play a whoosh sound
            zoomText.text = "Tap to return" -- change text object
        end

        local tgt = -180

        if stage == "correct" then tgt = -94; end -- alter position for localGroup to move to depending on stage
        stage = "zoomed" -- set game state

        timer.performWithDelay(300, delayW) -- update text and play sound after short delay

        local xT = -416
        if stage == "correct" then xT = 200; end

            transition.to(localGroup, {time = 600, x = xT, y= -80, xScale = 2.4, yScale = 2.4, transition = easing.inOutExpo})

    else

        if event.phase == "ended" and stage == "zoomed" and canZoom == true then -- check if already zoomed in

            canZoom = false -- cannot zoom (stops clicking the logo again before it is in place)
            audio.play(sounds[8]) -- play click sound
            stage = storedStage -- return the game state to how it was
            zoomText.text = "Tap to zoom" -- reset text object

            local resetZoom = function()
                canZoom = true
            end

            timer.performWithDelay(800, resetZoom) -- allow touches again after short delay
            audio.play(sounds.woosh)

            transition.to(localGroup, { y = 0, rotation = 0, time = 500, xScale = 1, yScale = 1, x = 0, transition = easing.inOutExpo }) -- return screen to normal
        end
    end
end



local fbHelp = function(event) -- function to handle touching of facebook button

    local obj = event.target -- localise touched button

    if event.phase == "ended" and stage == "enter" then -- check conditions are right

        doink(obj) -- animate button and text
        doink(fbText)

        _G.fbType = "logo" -- set the type of facebook posting to make
        _G.img = logos[cId].fn -- set the image filename to use

        local function onComplete(event)
            if "clicked" == event.action then
                local i = event.index
                if 2 == i then
                elseif 1 == i then
                    postmymsg() -- call function to post on facebook wall (in main.lua)
                end
            end
        end

        native.showAlert("Ask your friends for help!", "Post this logo on your wall?",
            { "Yes please", "No thanks" }, onComplete) -- show a native popup
    end
end


local alphaKey = function(event) -- function to handle touching of alphabet keys on custom keyboard

    local obj = event.target -- localise button touched
    local keyp = obj.id -- get the id of the button

    if event.phase == "began" and stage == "enter" then -- check conditions ok

        audio.play(sounds[11]) -- play a click sound

        obj.alpha = 0.6
        obj.xScale = 1.4
        obj.yScale = 1.4
        transition.to(obj, { time = 400, xScale = 1, yScale = 1, alpha = 0.97 }) -- animate the button to show it's been pressed

        local wid = word.width -- get width of answer entered in pixels

        if keyp < 27 then -- a key between A-Z or 0-9 was pressed
            cross.alpha = 0.7 -- show the cross icon
            leng = leng + 1 -- increment the length of the answer
            word.text = word.text .. obj.value -- add the letter/number pressed to the answer
            cursor.x = 163 + (wid / 2) -- move the cursor
        end


        if keyp == 29 then -- space bar pressed
            leng = leng + 1 -- increment the length of the answer
            word.text = word.text .. " " -- add a space to the answer
            cursor.x = 163 + (wid / 2) -- move the curosr
        end

        local gp = word.width - 240 -- check if the word is longer than 280 pixels

        if gp > 0 then

            word.xScale = 1 - (gp * 0.003) -- if so, scale down the word so it fits in the text box
            cursor.x = 163 + (wid / 2) - (gp * 0.4) -- move the cursor
        end
    end
end








local pressKey = function(event) -- handles touch events on non-alpha keyboard keys (including answer validation)

    local obj = event.target -- localise button pressed
    local keyp = obj.id -- get ID of button pressed

    if event.phase == "began" and stage == "enter" then -- do on began phase for greater responsiveness

        audio.play(sounds[11]) -- play click sound

        obj.alpha = 0.6
        obj.xScale = 1.2
        obj.yScale = 1.2

        transition.to(obj, { time = 400, xScale = 1, yScale = 1, alpha = 0.97 }) -- animate button pressed


        if keyp == 27 and leng > 0 then -- delete key pressed
            leng = leng - 1 -- reduced length of word

            saved[cNum]["score"] = saved[cNum]["score"] - 6 -- reduce score for this logo to reflect error
            saved[cNum]["errors"] = saved[cNum]["errors"] + 1 -- add one to error count on this logo

            local wlen = string.len(word.text)
            word.text = string.sub(word.text, 1, wlen - 1) -- remove one letter from answer
            local wid = word.width -- get width of answer in pixels
            word.xScale = 1 -- reset xScale to 1

            local gp = word.width - 280 -- check if the word is longer than 280 pixels

            if gp > 0 then
                word.xScale = 1 - (gp * 0.0023) -- if so, scale down the word so it fits in the text box
            end

            cursor.x = 163 + (wid / 2) -- move cursor to correct position
        end


        if keyp == 28 then -- 123/ABC key pressed

            local abcArray = { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" } -- set up temp array of alpha keys for top row
            local numArray = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" } -- set up temp array of numeric keys for top row

            if keyState == "abc" then -- if currently in alpha mode
                for a = 1, 10, 1 do -- cycle through 10 keys on top row
                    key[a].value = string.lower(numArray[a]) -- change the key values to numbers in array
                    keyState = "123" -- change the keyboard state to numeric
                    keyText[a].text = numArray[a] -- change the text on the keys to numbers
                    keyText[28].text = "A B C" -- updat the text on the keystate button
                end
            else -- if currently in numeric mode
                for a = 1, 10, 1 do -- cycle through 10 keys on top row
                    key[a].value = string.lower(abcArray[a]) -- change the key values to letters in array
                    keyState = "abc" -- change the keyboard state to alpha
                    keyText[a].text = abcArray[a] -- change the text on the keys to letters
                    keyText[28].text = "1 2 3" -- update the text on the keystate button
                end
            end
        end

        if keyp == 30 then -- enter button pressed

            if leng > 2 then -- check an answer has actually been entered

                local correct = false -- set up a local variable for whether the answer is correct
                local near = false -- set up a local variable for whether the answer is close
                saved[cNum]["last"] = word.text -- store the answer as the latest answer for this logo

                saveAll() -- save to disk

                local answers = table.maxn(logoNames[cNum]) -- get the number of possible answers for this logo

                for a = 1, answers, 1 do -- loop through the possible answers

                    local correctArray = {} -- set up a temp array for the letters in this correct answer
                    local myArray = {} -- set up a temp array for the letters in the user's answer
                    local tm = string.lower(logoNames[cNum][a]) -- convert the correct answer to lower case

                    for b = 1, string.len(tm), 1 do -- loop through all the letters in the correct answer

                        correctArray[b] = string.sub(tm, b, b) -- add each letter to the array
                    end

                    for c = 1, string.len(word.text), 1 do -- loop through all the letters in the user's answer

                        myArray[c] = string.sub(word.text, c, c) -- add each letter to the array
                    end

                    local totalLet = string.len(tm) -- total number of letters in the correct answer
                    local totalWord = string.len(word.text) -- total number of letters in the user's answer
                    local lengC = math.abs(totalLet - totalWord) -- compare the difference in length of the two answers

                    local matched = 0 -- set up a variable to hold the number of matched letters
                    local degree = 100 -- set up a variable to hold the degree of 'wrongness' in the answer

                    if totalLet > 0 and lengC < 3 then -- if checking against an actual answer and less than 3 letters in length difference

                        for d = 1, totalLet, 1 do -- loop through letters in correct answer

                            local thisMatch = 0 -- temp variable to store whether a match was found

                            for e = math.max(1, d - 1), math.min(string.len(word.text), d + 1), 1 do -- loop through letters either side of current letter

                                if correctArray[d] == myArray[e] then thisMatch = 1; end -- check if letter in correct answer equals that in user's answer
                            end

                            if thisMatch == 1 then matched = matched + 1; end -- if so, increase matched by 1
                        end
                    end

                    if totalLet > 1 then degree = totalLet - matched; end -- set degree of wrongness by comparing total letters to those matched
                    if totalLet > 1 and degree < 4 then near = true; end -- if degree of wrongness is less than 4 then call it a close answer
                    if totalLet < 4 then degree = 100; end -- avoid saying short answers are close because one letter matches

                    if (word.text == logoNames[cNum][a]) then -- check if user's answer exactly equals correct answer

                        if a > 1 then saved[cNum]["score"] = saved[cNum]["score"] - (350 * a); end -- if so, set flag and update score accordingly if top answer not given
                        correct = true
                    end

                    if correct == false and (degree < 2) then -- if only one letter out (i.e. misspelling), call it a correct answer but dock points accordingly

                        saved[cNum]["score"] = saved[cNum]["score"] - (150 * (a - 1)) - (300 * degree);
                        correct = true
                    end
                end

                if correct == true then -- check if user got correct answer

                    if saved[cNum]["score"] < 0 then saved[cNum]["score"] = 50; end -- if score went below zero due to previous actions, set to 50
                    saved[cNum]["guesses"] = saved[cNum]["guesses"] + 1 -- increase the number of guesses for this logo
                    totGuesses = totGuesses + 1 -- increase total number of guesses
                    settings.guesses = totGuesses -- store in DB

                    updateLevel() -- call function to update game after correct answer

                else

                    if near == false then -- check if a close answer was given, if not:

                        audio.play(sounds.wrong) --play the wrong answer sound
                        wrong = wrong + 1 -- add 1 to wrong answer total
                        settings.wrong = wrong -- store in DB
                        totGuesses = totGuesses + 1 -- add 1 to guesses total
                        settings.guess = totGuesses -- store in DB

                        saved[cNum]["score"] = saved[cNum]["score"] - 125 -- reduce score
                        saved[cNum]["guesses"] = saved[cNum]["guesses"] + 1 -- add 1 to guesses on this logo
                        saved[cNum]["almost"] = 0 -- set 'almost' flag to zero
                        crosses[cId].alpha = 0.9 -- show the cross icon for this logo on main screen
                        almosts[cId].alpha = 0; -- hide the almost icon for this logo on main screen
                        nocross.alpha = 0.8; -- show the cross icon on entry screen
                        almost.alpha = 0 -- hide the almost icon on entry screen

                        transition.to(localGroup, { time = 100, x = 5, y = 5 }) -- start of shake screen effect

                        for a = 1, 3, 1 do
                            transition.to(localGroup, { delay = 0 + (120 * a), time = 40, x = 3, y = 3 })
                            transition.to(localGroup, { delay = 40 + (120 * a), time = 40, x = -3, y = 3 })
                            transition.to(localGroup, { delay = 80 + (120 * a), time = 40, x = 0, y = 0 })
                        end
                        -- end of shake screen effect

                    else -- a close answer was given

                        audio.play(sounds.nearly) -- play nearly sound

                        nearly = nearly + 1 -- add 1 to nearly total
                        totGuesses = totGuesses + 1 -- add 1 to guesses total
                        settings.almost = nearly -- store in DB
                        settings.guesses = totGuesses -- store in DB

                        saved[cNum]["score"] = saved[cNum]["score"] - 50 -- reduce score
                        saved[cNum]["guesses"] = saved[cNum]["guesses"] + 1 -- add 1 to guesses on this logo
                        saved[cNum]["almost"] = saved[cNum]["almost"] + 1 -- add 1 to nearly guesses on this logo
                        saved[cNum]["wrong"] = 0 -- set 'wrong' flag to zero
                        almosts[cId].alpha = 0.9 -- show the almost icon for this logo on the main screen
                        crosses[cId].alpha = 0 -- hide the cross icon for this logo on the main screen
                        almost.alpha = 0.8; -- show the almost icon on the entry screen
                        nocross.alpha = 0 -- hide the cross icon on entry screen

                        transition.to(localGroup, { time = 100, x = 5, y = 5 })

                        for a = 1, 3, 1 do
                            transition.to(localGroup, { delay = 0 + (120 * a), time = 40, x = 3, y = 3 })
                            transition.to(localGroup, { delay = 40 + (120 * a), time = 40, x = -3, y = 3 })
                            transition.to(localGroup, { delay = 80 + (120 * a), time = 40, x = 0, y = 0 })
                        end
                    end -- shake screen effect
                end

                saveAll() -- save DB to disk
            end
        end

        if leng == 0 then cross.alpha = 0; end -- if answer is now empty hide the 'delete all' cross icon
    end
end

 local createInset = function ()

        local words = {}
        local wd = 1
        local cnt = 0
        local row = 1

        for a = 1, tl.wLeng, 1 do

            if string.byte(tl.wordArray[a]) == 32 or a == tl.wLeng then

                if a == tl.wLeng then cnt = cnt + 1;end
                words[wd] = cnt
               print ("Word "..wd.." - "..cnt)
                wd = wd + 1
                cnt = -1
            end

            cnt = cnt + 1
        end

       print ("WORDS: "..#words)
        words[#words+1] = 0
        words[#words+1] = 0

        local gaps = 0

        insetGroup[1] = display.newGroup()
         insetGroup[2] = display.newGroup()
          insetGroup[3] = display.newGroup()
          --insetGroup[row] = display.newGroup()

        tl.insets = {}

        local col = 1
        local skip = 0
        local wrd = 0

        for a = 1, tl.wLeng, 1 do

            local sp = 20

            if xO > 0 then sp = 22; end


            --if tl.wLeng > 10 then sp = 20; end

            if string.byte(tl.wordArray[a]) == 32 then

                local alu = 0.7
                wrd = wrd + 1

                print (col.." "..words[row+wrd].." "..row)

                if col + words[row+wrd] > 15 then

                skip = 1
                row = row + 1
                col = 1
                alu = 0
                gaps = 40
                wrd = 1

                end


            gaps = gaps - 4

            local r = display.newRect(0, 0, 2,28)
            r.x = - 15 + (sp* col) + gaps
           gaps = gaps - 4
            r.y = 252 + yO*2 + (row * 30)-yO/2
            r.letter = false
            r.active = false
            r.fill = 0
            insetGroup[row]:insert(r)
            tl.insets[a] = r
            r:setFillColor(250,200,0)
            r.alpha = alu




            local t = display.newText(" ", 0, 0, fontName[1], 18)
            t.x = - 15 + (sp* col) + gaps
            t.y = 252 + yO*2 + (row * 30) -yO/2
            t:setTextColor(0,0,0)
            tl.insets[a].txt = t
            insetGroup[row]:insert(t)


            else

            local i = display.newImageRect("inset.png", 18,28) -- load and position the border image
            i.x = - 15 + (sp* col) + gaps; i.y = 252 + yO*2 + (row*30) -yO/2; i.alpha = 1
            tl.insets[a] = i
            i.letter = true
            i.active = false
            i.fill = 0
            insetGroup[row]:insert(i)
            i:addEventListener("touch",touchInset)

            local t = display.newText("", 0, 0, fontName[1], 18)
            t.x = - 15 + (sp* col) + gaps
            t.y = 250 + yO*2 + o + (row*30) - yO/2
            t:setTextColor(0,0,0)
            tl.insets[a].txt = t
            insetGroup[row]:insert(t)

            end

            if skip == 0 then col = col + 1
            else
            skip = 0
            end

        end

    local wd = insetGroup[row].width
    --print ("INSET WIDTH"..wd)

    for a =1,3 , 1 do
    insetGroup[a]:setReferencePoint(display.CenterReferencePoint)
    insetGroup[a].x = 160
    tilesGroup:insert(insetGroup[a])
    end
    --hud.cat.x = 320 - (320-wd)/2


    end

  local createTiles = function ()

        local row =1


        local col = 1


        local rowL = math.round(tl.board/2)



        if rowL > 10 then rowL = 10; end
        if rowL < 7 then rowL = 7; end

    --    print ("ROWL" ..rowL)

        local rowLG = {0,0,0,0,0,0,6,4,2,0}

        local xG = 0

        if xO > 0 then xG = 2; end
        rowsGroup[1] = display.newGroup()
        rowsGroup[2] = display.newGroup()
        rowsGroup[3] = display.newGroup()

    --    print ("BOARDSIZE"..tl.board)

        for a = 1, tl.board, 1 do



            local i = display.newImageRect("letter"..row..".png", 29, 36) -- load and position the border image
            i.x = - 11 + ((31 + rowLG[rowL] + xG) * col) ; i.y = 309 + (40* row) + yO*2 ; i.alpha = 0.9
            tl.tiles[a] = i
            i.id = a
            i.active = true
            i.value = tl.boardArray[a].value
            i.orig = tl.boardArray[a].orig
            rowsGroup[row]:insert(i)

            i:addEventListener("touch",touchLetter)

    --        print (a.." "..i.value.." "..i.orig)

            --transition.to(i, {y = 359 + (47* row) + yO*2, time = 70, delay = 70*a})

            local t = display.newText(tl.boardArray[a].value, 0, 0, fontName[1], 24)
            t.x = - 10 + ((31 + rowLG[rowL] + xG) * col)
            t.y = 306+ (40* row) + o + yO*2
            t:setTextColor(0,0,0)
            tl.tiles[a].txt1 = t
            rowsGroup[row]:insert(t)


            local t = display.newText(tl.boardArray[a].value, 0, 0, fontName[1], 24)
            t.x = - 11 + ((31 + rowLG[rowL] + xG) * col)
            t.y = 305 + (40* row)  + o + yO*2
            t:setTextColor(255,255,255)
            tl.tiles[a].txt2 = t
            rowsGroup[row]:insert(t)


    --        print (col)
            col = col + 1
            if col == rowL+1 and a < tl.board then
                col = 1

                row = row + 1


            end





        end

        for a = 1,row, 1 do
            rowsGroup[a]:setReferencePoint(display.CenterReferencePoint)
            rowsGroup[a].x = 160
            tilesGroup:insert(rowsGroup[a])
        end

         tilesGroup:setReferencePoint(display.CenterReferencePoint)
         tilesGroup.x = 160
         tilesGroup.y = 360

         tileGroup:insert(tilesGroup)

         keyGroup:insert(tileGroup)

    end



local createTileGroup = function ()


    tileGroup = display.newGroup()
    tilesGroup = display.newGroup()
    tl.tiles = {}
    tl.word = string.upper(logoNames[cNum][1])  ;
    --    print ("ANSWER"..tl.word)
    tl.wLeng = string.len(tl.word)
    --    print ("LENG"..tl.wLeng)
    tl.shortWord = string.gsub(tl.word , " ", "")
    --     print ("SHORT"..tl.shortWord)
    tl.wLengSh = string.len(tl.shortWord)
    --    print ("SLENG"..tl.wLengSh)
    tl.bLeng = 12

      tl.occupied = 0

    local lengsA = {6, 9, 13, 17, 21, 25, 29}
    local lengsB = {14, 18, 22, 24, 28, 30, 32}



    for a = 1, 7, 1 do

        if tl.wLengSh > lengsA[a] then tl.bLeng = lengsB[a]; end

    end

    --    print ("BLENG"..tl.bLeng)
     tl.extra = tl.bLeng - tl.wLengSh
      tl.board = tl.bLeng
    --    print ("EXTRA"..tl.extra)

     tl.aLeng = 0
     tl.boardArray = {}
     tl.nextOpen = 1
     tl.wordArray = {}
     tl.shortArray = {}
     tl.answer = ""

    for a = 1, tl.wLeng, 1 do
        tl.wordArray[a] = string.sub(tl.word,a,a)
    end

    for a = 1, tl.wLengSh, 1 do
        tl.shortArray[a] = string.sub(tl.shortWord,a,a)
    end


local calcExtra = function ()

  rnd:seed(cNum)

  tl.ext =""

  for a = 1, tl.extra, 1 do

    local ok = 0
    local tmp

    while ok == 0 do


        local chLetter = 64 + rnd:randInt(1,26)

        tmp = string.char(chLetter)

        ok = 1

        for b = 1, tl.wLengSh, 1 do

            if tl.wordArray[b] == tmp then ok = 0; end

        end

    end

    tl.ext = tl.ext..tmp


    --print (tmp)


  end

  tl.letters = tl.shortWord..tl.ext

  --print ("NEW BOARD: "..tl.letters)

end

calcExtra()



for a = 1, tl.bLeng, 1 do

    tl.boardArray[a] = {}
    tl.boardArray[a].value = string.sub(tl.letters,a,a)
    tl.boardArray[a].orig = a
end

shuffle(tl.boardArray)


createTiles()
createInset()





end





local selectLogos = function(event) -- function to handle touch events on logos

    local obj = event.target -- localise button pressed
    local oid = obj.id -- get id of button pressed

    if (event.phase == "began" and stage == "choose") then

        if _G.platformName == "Android" then
            display.getCurrentStage():setFocus(obj) -- set focus to avoid touch problems on some android devices
        end
    end

    if event.phase == "ended" and moving == false and stage == "choose" then -- check conditions are OK

        if _G.platformName == "Android" then
            display.getCurrentStage():setFocus(nil) -- lose focus on android devices
        end





        word.xScale = 1 -- reset xScale of answer text object
        zoomText.alpha = 0 -- show zoomText object
        zoomText.x = 240 -- reset zoomText position
        doink(obj) -- animate logo
        doink(shades[oid]) -- animate logo shade object
        audio.play(sounds[7]) -- play click sound
        hudGroup:toFront()

        cNum = obj.num -- get the number of the logo being answered
        cId = obj.id -- get the ID of the logo image on main screen

        word.cat.alpha  = saved[cNum].category

        thisAnswer = answers[cNum]

        createTileGroup()
         word.cat.text = clues[cNum][1]
         word.cat:toFront()
        after.title.text  = tl.word
        after.button.alpha = 0
            after.txt1.alpha = 0
            after.txt2.alpha = 0

        local wid = after.title.width -- get width of last answer in pixels
        local gp = wid - 260 -- get number of pixels greater than 280

        after.title.xScale = 1

        if gp > 0 then
            after.title.xScale = 1 - (gp * 0.0040) -- scale down answer text if too wide for text box
        end

        afterGroup.x = 600

        showRevealed()
        hideRemoved()
        stage = "enter" -- set game status
        word.text = "" -- reset answer text object
        word.text = saved[cNum]["last"] -- set to last answer given for this logo

        local wid = word.width -- get width of last answer in pixels
        local gp = word.width - 280 -- get number of pixels greater than 280

        if gp > 0 then
            word.xScale = 1 - (gp * 0.0023) -- scale down answer text if too wide for text box
        end
        word.bomb.alpha = 1
            word.fb.alpha = 1

        --cursor.x = 160 + (wid / 2) -- set the cursor position according to answer length
        leng = string.len(word.text) -- get the length of the last answer given
        ---nocross.alpha = 0; -- hide the wrong answer icon
        --almost.alpha = 0 -- hide the almost right icon

        if leng > 0 then cross.alpha = 0.8; end -- if an answer has been entered, show the delete all icon

        swipe() -- play a swipe sound

        if saved[cNum]["guesses"] > 0 and saved[cNum]["solved"] == 0 and saved[cNum]["almost"] == 0 then
            nocross.alpha = 0.8 -- if last guess was incorrect, show wrong answer icon
        end

        if saved[cNum]["guesses"] > 0 and saved[cNum]["almost"] == 1 and saved[cNum]["solved"] == 0 then
            almost.alpha = 0.8 -- if last guess was almost correct, show almost icon
        end

        local en = ".png" -- set a temp variable for the filename suffix (default is to show the clue version)
        local xn = 240 -- temp variable for the position of the big logo (depending on whether logo solved or not)

        if saved[cNum]["solved"] == 1 then -- if logo is already solved:
            xn = 160 -- show big logo in middle of screen
            fbBtn.alpha = 0
            fbText.alpha = 0
            hintBtn.alpha = 0
            hintBtnText.alpha = 0
            solveBtn.alpha = 0
            solveBtnText.alpha = 0 -- hide buttons as not needed
            after.button.alpha = 1
            after.txt1.alpha = 1
            after.txt2.alpha = 1

            if _G.paid == 1 then en = ".png"; end -- show the full version of the logo if paid version
            en = ".png"     -- comment out to only allow paid users to see full version
        else
            --fbBtn.alpha = 1
            --fbText.alpha = 1
            --hintBtn.alpha = 1
            --hintBtnText.alpha = 1 -- show buttons
            --solveBtn.alpha = 1
            --solveBtnText.alpha = 1
        end

        if bigbox then display.remove(bigbox); end -- remove the previous big logo and border
        if bigLogo then display.remove(bigLogo); end

        if useBorder == 1 then
            local i = display.newImageRect("border.png", 132,132) -- load and position the border image
            i.x = xn; i.y = 123; i.alpha = 1
            bigbox = i
        end

        local fn = obj.fn -- get the file name of the current logo


        bigLogo = display.newImageRect( "logos/"..fn ..en, 180,180) -- load and position the logo image
        bigLogo.x = 160; bigLogo.y = 146 - yO
        bigLogo:addEventListener("touch", touchBig)

         if useBorder == 1 then keyGroup:insert(bigbox); end
        keyGroup:insert(bigLogo) -- add logo and border to keyGroup display group

        -- add touch listener to logo for zooming

        --zoomText:toFront() -- bring zoom prompt text back in front of big logo

        fbBtn.x = 90; fbText.x = 90
        hintBtn.x = 90; hintBtnText.x = 90 -- ensure facebook, hint and solve buttons in right position
        solveBtn.x = 90; solveBtnText.x = 90

        transition.to(keyGroup, { time = 700, x = 0, transition = easing.inOutExpo }) -- slide in the entry screen

        if saved[cNum]["solved"] == 1 then -- if logo was already solved set up screen accordingly

             local hrs = math.floor(saved[cNum].time/3600)

                local rem = saved[cNum].time - (hrs * 3600)


    local mins = math.floor(rem/60)
    local sec = saved[cNum].time - (mins*60) - (hrs * 3600)

    if sec < 10 then sec = "0"..sec; end
    if mins < 10 then mins = "0"..mins; end

    local earned = 5

    if saved[cNum].score < 950 then earned = 4; end
    if saved[cNum].score < 850 then earned = 3; end
    if saved[cNum].score < 650 then earned = 2; end
    if saved[cNum].score < 350 then earned = 1; end


    local tat = {hrs..":"..mins..":"..sec, saved[cNum].revealed, saved[cNum].removed, saved[cNum].wrong, saved[cNum].score}

    for a =1, 5, 1 do

        after[a].txt.text = tat[a]
            after[a].txt:setReferencePoint(display.CenterLeftReferencePoint)
            after[a].txt.x = 200

            --if a== 5 then after[a].txt:setTextColor(255,255,255); end

    end

            --conText[2].text = "Score: " .. saved[cNum]["score"] -- display the score that was achieved

            zoomText.x = 160 -- move the zoom text prompt to the middle of screen

            --kbGroup.alpha = 0 -- hide the keyboard
            --cursor.x = 600 -- move cursor off-screen
            --cross.alpha = 0 -- hide the cross icon
            stage = "correct" -- set the current game state to 'correct'
            afterGroup.x = 0 -- show the congrats screen
            afterGroup:toFront()
            tilesGroup.x = 600
            word.bomb.alpha = 0
            word.fb.alpha = 0


            --word.text = logoNames[cNum][1] -- put the correct answer in the text box

            local red = math.random(50, 200)
            local blue = math.random(50, 200)
            local green = math.random(50, 200)



            --conbg:setFillColor(red, blue, green) -- fill the congrats background with a random colour
        end
    end
end




local touchAd = function(event) -- handles touch events for in-house ad

    local obj = event.target

    if event.phase == "ended" then

        if obj.id == 1 then -- download button pressed

            local doit = function()

                settings.clicked = 1
                saveAll()
                system.openURL(url) --	open ad URL (defined at top of this file)
            end

            timer.performWithDelay(500, doit) -- open URL after delay to wait for ad to move off screen

            transition.to(adGroup, { time = 400, x = 600, transition = easing.InOutExpo }) -- move ad off screen

        else -- cancel button pressed

            transition.to(adGroup, { time = 400, x = 600, transition = easing.InOutExpo }) -- move ad off screen
        end

        local resetIt = function ()

        stage = storedStage -- set game status back to how it was
        if stage == "prepare" then stage = "choose"; end -- handle case where ad launches during loading of logos
        if keyGroup.x == 0 then stage = "enter"; end -- handle case where ad launches just after a logo was pressed
        end

        timer.performWithDelay(100, resetIt)
    end
end




local gotoMenu = function() -- function to return to menu screen

    audio.play(sounds[9]) -- play click sound
    swipe() -- call swipe sound function
    saveAll() -- save DB to disk
    storyboard.gotoScene("menu", "fromLeft", 500) -- load menu.lua scene
end


local touchBack = function(event) -- function to handle touching of back arrow

    local obj = event.target -- localise the button pressed


    if event.phase == "ended" and stage == "correct" then

        doink(obj)
        closeCongrats() -- close the congrats screen if that is open
    end


    local skip = 1 -- temp variable to track whether to call gotoMenu at the end


    if event.phase == "ended" and stage == "choose" and loading == false then -- game is on main screen and not loading logos

        local ornot = math.random(1, 10) -- random variable to decide whether to show a popup

        local fbed = settings.liked -- get whether the user liked your facebook page already
        local rated = settings.rated    -- get whether the user rated your app already

        if fbed == 0 and ornot == 5 and _G.fbPopup == 0 then -- if the user hasn't liked it yet, the popup hasnt appeared this session and the random chance is met

            skip = 0 -- temp variable to avoid calling gotoMenu twice

            function onComplete3(event) -- function to handle clicking on a dialog button

                if "clicked" == event.action then
                    local i = event.index
                    _G.fbPopup = 1 -- prevent same popup appearing twice in same session
                    if i == 1 then -- user pressed 'yes please' button
                        local h = settings.coins
                        h = h + 100 -- get current number of hints and add 30
                        settings.coins = h -- store in DB
                        settings.liked = 1 -- store that user liked on FB
                        saveAll() -- save to disk
                        if coinText then coinText.text = h; end -- update HUD text

                        system.openURL("http://www.facebook.com/OtterStudios") -- goto facebook page
                    end

                    timer.performWithDelay(1000, gotoMenu) -- after a short delay call function to go to menu
                end
            end

            native.showAlert("Like us on Facebook...", "...and get 100 free stars!", { "Yes please!", "No Thanks!" }, onComplete3) -- show a popup for user to like on FB
        end

        if rated == 0 and ornot == 2 then       -- if the user hasn't rated yet

            local rtxt = "Rate this game and let other people know!"

            if _G.popup == 1 then rtxt = "Rate this game and get 100 free stars!"; end
            skip = 0

            function onComplete4(event)

                if "clicked" == event.action then
                    local i = event.index
                    _G.fbPopup = 1
                    if i == 1 then

                        if _G.popup == 1 then

                        local h = settings.coins
                        h = h + 100 -- get current number of hints and add 30
                        settings.coins = h -- store in DB
                        --settings.liked = 1 -- store that user liked on FB
                        saveAll() -- save to disk
                        if coinText then coinText.text = h; end -- update HUD text


                        end





                        settings.rated = 1
                        saveAll()
                        local model = system.getInfo("model")
                        local options
                        if model == "Kindle Fire" or model == "WFJWI" or model == "KFTT" or model == "KFOT" or model == "KFJWA" or model == "KFJWI" then
                            options =
                            {
                            supportedAndroidStores = {"amazon"},
                                }
                        else
                            options =
                                {
                                iOSAppId = "624737837",
                                nookAppEAN = "0987654321",
                                supportedAndroidStores = { "google", "samsung", "nook" },
                                }
                        end
                        native.showPopup("rateApp", options)

                    end

                timer.performWithDelay(1000, gotoMenu)

                end
            end

            native.showAlert("Enjoying this game?", rtxt, { "Ok!", "Not right now!" }, onComplete4)

        end

        if skip == 1 then
            gotoMenu() -- if popup was not shown, call function to go back to menu
        end
    end


    if event.phase == "ended" and stage == "enter" then -- user is on entry screen

        doink(obj) -- animate button


--        fbBtn.alpha = 1
--        fbText.alpha = 0
--        hintBtn.alpha = 1
--        hintBtnText.alpha = 0
--        solveBtn.alpha = 1
--        solveBtnText.alpha = 0
--        cross.alpha = 0 -- reset entry screen objects
        leng = 0

        --cursor.x = 160
        saved[cNum]["last"] = word.text -- store the currently entered answer for this logo

        word.text = ""
        clueText[1].text = ""
        clueText[2].text = ""
        clueText[3].text = ""
        resetClues() -- reset clue screen objects


        audio.play(sounds[9]) -- play click sound
        swipe() -- play swipe sound


        saveAll() -- save to disk


        --keyText[28].text = "1 2 3"
--        local abcArray = { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" }
--        for a = 1, 10, 1 do
--            key[a].value = string.lower(abcArray[a])
--            keyState = "abc"
--            keyText[a].text = abcArray[a]
--        end -- reset the keyboard to alpha mode
--

        transition.to(keyGroup, { time = 700, x = 700, transition = easing.inOutExpo }) -- move the keyboard etc off screen


        local reset = function()

            stage = "choose"
            display.remove(tileGroup)
            tileGroup = nil
            tilesGroup = nil
        end

        timer.performWithDelay(400, reset) -- after a short delay, set game status
    end
end




local touchCoin = function(event) -- function to handle touching of the coin icon on top bar

    if event.phase == "ended" and stage == "enter" then

        doink(event.target) -- animate icon

        audio.play(sounds[7]) -- play click sound
        if coins > 19 then -- check if user has enough coins

            local onComplete = function(event) -- handle native alert button presses
                if "clicked" == event.action then
                    local i = event.index
                    if i == 2 then
                        -- Player click 'Cancel'; do nothing, just exit the dialog
                    elseif i == 1 then

                        transition.to(coinIcon, { rotation = 11, time = 500, xScale = 1.3, yScale = 1.3, transition = easing.inOutExpo })
                        transition.to(coinIcon, { rotation = -11, delay = 500, time = 300, xScale = 1.0, yScale = 1.0, transition = easing.inOutExpo }) -- animate the coin icon
                        coins = coins - 20 -- remove 20 coins from the player
                        settings.coins = coins -- update the DB
                        coinText.text = coins -- update coin text object
                        resetClues() -- returns clue screen objects to their correct positions

                        saved[cNum]["score"] = 50 -- award a score of 50

                        updateLevel() -- run function to solve the logo
                    end
                end
            end


            local alert = native.showAlert("Are You Sure?", "You have " .. coins .. " coins, revealing the answer will cost you 20 coins...", { "Yes", "No" }, onComplete)
        else
            local alert = native.showAlert("Sorry!", "You do not have enough coins, you can buy more in the shop...", { "OK" }) -- show message if user doesn't have enough coins
        end
    end
end




local touchHint = function(event) -- function to handle touching of hint icon on top bar

    if event.phase == "ended" and stage == "enter" and clueGroup.x > 0 then -- check that conditions are right for showing clue screen

        doink(event.target) -- animate icon

        swipe() -- play swipe sound
        audio.play(sounds[8]) -- play click sound

        transition.to(clueGroup, { time = 700, x = 0, transition = easing.inOutExpo })
        transition.to(bigbox, { rotation = 90, time = 700, x = -52, xScale = 0.45, yScale = 0.45, transition = easing.inOutExpo })
        transition.to(bigLogo, { rotation = 90, time = 700, x = -52, xScale = 0.45, yScale = 0.45, transition = easing.inOutExpo })
        transition.to(fbText, { delay = 100, time = 1200, x = -200, rotation = 0, transition = easing.outExpo })
        transition.to(fbBtn, { delay = 100, time = 1200, x = -200, rotation = 0, transition = easing.outExpo })
        transition.to(hintBtnText, { delay = 100, time = 1200, x = -200, rotation = 0, transition = easing.outExpo })
        transition.to(hintBtn, { delay = 100, time = 1200, x = -200, rotation = 0, transition = easing.outExpo })
        transition.to(solveBtnText, { delay = 100, time = 1200, x = -200, rotation = 0, transition = easing.outExpo })
        transition.to(solveBtn, { delay = 100, time = 1200, x = -200, rotation = 0, transition = easing.outExpo }) -- move everything into correct position

        local used = saved[cNum]["hints"] -- get number of hints already used on this logo

        if used == 0 then
            clueBtn[1].alpha = 0.9
            clueBtn[2].alpha = 0.2
            clueBtn[3].alpha = 0.2
        end

        if used == 1 then
            clueBtn[1].alpha = 0.2
            clueBtn[2].alpha = 0.9
            clueBtn[3].alpha = 0.2
        end

        if used == 2 then
            clueBtn[1].alpha = 0.2
            clueBtn[2].alpha = 0.2
            clueBtn[3].alpha = 0.9
        end -- light up the clue buttons accordingly

        if used == 3 then
            clueBtn[1].alpha = 0.2
            clueBtn[2].alpha = 0.2
            clueBtn[3].alpha = 0.2
        end
    end
end




local touchCross = function(event) -- handles touching of cross icon to delete entire answer

    if event.phase == "ended" then

        saved[cNum]["score"] = saved[cNum]["score"] - 20 -- reduce score to reflect mistake
        saved[cNum]["errors"] = saved[cNum]["errors"] + 1 -- increase error count

        saveAll() -- save to disk

        audio.play(sounds[7]) -- play click sound

        leng = 0 -- reset length of answer to zero
        word.text = "" -- reset text object of answer to blank
        word.xScale = 1 -- reset scale of text in case it had been scaled down
        cursor.x = 160 -- reset cursor to the middle
        cross.alpha = 0 -- hide the cross icon
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

                logoGroup.x = -320 * (page - 1)
                logoGroup.x = logoGroup.x + diffX -- move the logo group along with the finger
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


            transition.to(logoGroup, { x = -320 * (page - 1), time = 1400, transition = easing.outExpo })
            transition.to(bg, { x = 240 + (-30 * (page - 1)), time = 1400, transition = easing.outExpo }) -- move the logos and background accordingly

            startTime = 0 -- reset startTime
        end
    end
end



loadLogos = function()

    local offset = (pages - 1) * 320 -- X offset for each page

    -- function to load the logos one by one (done this way to avoid delay when initially loading scene)

    if a < 10 then audio.play(sounds[7]); end -- play a click sound when logos on first page load

    local before = start[cLevel] - 1 -- number of logos before this level
    local logoNum = dispOrd[a] -- get the number of the logo to load in this position (they are loaded in a random order each time the level loads)
    --offset = 0

    local thisLogo = order[before + logoNum] -- gets the number of the logo within the database
    local fn = files[thisLogo] -- gets the file name for this logo

    --print (thisLogo)

    if useBorder == 1 then -- if a border image is to be used
        local i = display.newImageRect("border.png", bxSize, bySize) -- load the border image
        i.x = (col * xGap) + xOffset + offset-- set x pos
        i.y = (row * yGap) + yOffset -- set y pos
        i.alpha = 0.9 -- set alpha value
        i.num = thisLogo -- store the number of the logo within the database
        i.id = a -- store the physical number of the logo within the level
        logos[a + nLevel] = i -- put the border image at the end of the logos array
        logoGroup:insert(i) -- insert the image into logoGroup
    end

    local suffix = ".png" -- set a temp variable for the filename suffix to use

    if saved[thisLogo]["solved"] == 1 then
        suffix = ".png" -- if the user paid, show the full logo
    end

    logos[a] = display.newImageRect( "logos/"..fn .. suffix, xSize, ySize) -- load the appropriate logo image
    logos[a].x = (col * xGap) + xOffset + offset -- set the x position of the logo
    logos[a].y = (row * yGap) + yOffset + (col*4) -- set the y position of the logo
    logos[a]:addEventListener("touch", selectLogos) -- add a touch listener
    logos[a].num = thisLogo -- store the number of the logo within the database
    logos[a].id = a -- store the physical number of the logo within the level
    logos[a].fn = fn -- store the logo's filename


    shades[a] = display.newImageRect( "logos/"..fn .. suffix, xSize, ySize) -- load the appropriate shadow image
    shades[a].x = (col * xGap) + xOffset + offset
    shades[a].y = (row * yGap) + yOffset + (col*4)
    shades[a].num = thisLogo
    shades[a].id = a

    logoGroup:insert(logos[a]) -- now insert the actual logo
    logoGroup:insert(shades[a]) -- insert the shaded image first
    shades[a].alpha = 0 -- hide the shaded image until needed

    ticks[a] = display.newImageRect("tick.png", 24,24) -- load the tick image
    ticks[a].x = (col * xGap) + xOffset + xIcon + offset -- set the xPos using the icon offset value
    ticks[a].y = (row * yGap) + yOffset + yIcon -- set the yPos using the icon offset value
    ticks[a].num = thisLogo -- store the number of the logo within database
    ticks[a].alpha = 0 -- hide the tick until needed
    logoGroup:insert(ticks[a]) -- insert ticks to logoGroup

    if saved[thisLogo]["solved"] == 1 then -- check if this logo was already solves
        ticks[a].alpha = 1 -- show the tick
        logos[a].alpha = 1 -- fade the original slightly
        shades[a]:setFillColor(gray)
        shades[a].alpha = 0.5-- show the shaded version on top of the original
    end


    crosses[a] = display.newImageRect("cross.png", 24,24) -- load the cross image
    crosses[a].x = (col * xGap) + xOffset + xIcon + offset
    crosses[a].y = (row * yGap) + yOffset + yIcon
    crosses[a].num = thisLogo
    crosses[a].alpha = 0
    logoGroup:insert(crosses[a])
    if pages > 1 then
        --logos[a].alpha = 0
    end

    if saved[thisLogo]["guesses"] > 0 and saved[thisLogo]["solved"] == 0 and saved[thisLogo]["almost"] == 0 then
        crosses[a].alpha = 1
    end

    almosts[a] = display.newImageRect("nearly.png", 50, 50)
    almosts[a].x = (col * xGap) + xOffset + xIcon + offset
    almosts[a].y = (row * yGap) + yOffset + yIcon
    almosts[a].num = thisLogo
    almosts[a].alpha = 0
    logoGroup:insert(almosts[a])
    if pages > 1 then
        --logos[a].alpha = 0
    end

    if saved[thisLogo]["guesses"] > 0 and saved[thisLogo]["almost"] > 0 and saved[thisLogo]["solved"] == 0 then
        almosts[a].alpha = 1
    end

    col = col + 1

    if col == numCols + 1 then
        col = 1
        row = row + 1;
    end

    if row == numRows + 1 then
        col = 1
        row = 1

        if a < nLevel then
            pages = pages + 1
            pageText.text = page .. " / " .. pages
            audio.play(sounds[11])
        end
    end


    a = a + 1
    if a > nLevel then
        loading = false
        audio.setVolume(_G.sound)
    end

    if a == 10 then stage = "choose"; end

    if a == 19 then
        native.setActivityIndicator(false)

        Runtime:addEventListener("touch", touchScreen)
    end
end



---------------------------------------------------------------------------------
-- STORYBOARD FUNCTIONS
---------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
function scene:createScene(event)

    localGroup = self.view

    local createScreen = function() -- function to create the background and HUD

        local r = display.newRect(0, 0, 384, 576)
        r.x = 160; r.y = 240
        r:setFillColor(25, 25, 25)
        localGroup:insert(r)

        bg = display.newImageRect("bg.jpg", 576, 576)
        bg.x = 240; bg.y = 240
        bg.alpha = 0.7
        --bg:setFillColor(200,200,200)
        localGroup:insert(bg) -- load and position background image


        local r = display.newImageRect("rect.png", 384, 130)
        --:setFillColor(cols[1], cols[2], cols[3])
        r.alpha = 1
        r.x = 160; r.y = -6 - yO * 2
        hudGroup:insert(r)
        rect[1] = r -- load and position top bar image
        r.rotation = 1

          local red = math.random(100, 255)
    local blue = math.random(100, 255)
    local green = math.random(100, 255)

        back = display.newImageRect("back.png", 46,42); back.x = 32; back.y = 22 - yO * 2; back.alpha = 1
        hudGroup:insert(back)
        back:addEventListener("touch", touchBack) -- load back button, position and add touch listener
        back.rotation = 126
        back:setFillColor(red,green,blue)

        levelText = display.newText("level "..cLevel, 0, 0, fontName[1], 30)
        levelText.x = 160; levelText.y = 19 + o - yO * 2
        levelText:setTextColor(210,210,210)
        hudGroup:insert(levelText) -- create text header
        levelText.rotation =1

        testText = display.newText("", 0, 0, fontName[1], 12)
        testText.x = 60; testText.y = 5 + o
        testText:setTextColor(0, 0, 0)
        if checkMem == nil then testText.alpha = 0; end
        testText.text = yO

        localGroup:insert(testText) -- create a text object for debugging

        coinIcon = display.newImageRect("pig.png", 52,52); coinIcon.x = 286; coinIcon.y = 24 - yO * 2; coinIcon.alpha = 0.8
        hudGroup:insert(coinIcon)
        coinIcon.rotation = -11
        coinIcon:setFillColor(red,green,blue)
        coinIcon:addEventListener("touch",loadShop)
        -- create and position coin icon

        hintIcon = display.newImageRect("bulb.png", 48,40); hintIcon.x = 232; hintIcon.y = 26 - yO * 2; hintIcon.alpha = 0.8
        hudGroup:insert(hintIcon)
        hintIcon.rotation = 0
        hintIcon:setFillColor(red,green,blue)
        hintIcon.alpha = 0
         -- create and position hint icon

        coinText = display.newText(coins, 0, 0, fontName[1], 10)
        coinText.x = 286; coinText.y = 23+ o - yO * 2; coinText.rotation = -11
        coinText:setTextColor(222, 225, 225)
        hudGroup:insert(coinText) -- create and position coin number text

        hintText = display.newText(hints, 0, 0, fontName[1], 10)
        hintText.x = 226; hintText.y = 18 + o - yO * 2; hintText.rotation = 11
        hintText:setTextColor(225, 225, 225)
        hudGroup:insert(hintText) -- create and position hint number text
        hintText.alpha = 0

        pageText = display.newText("1 / " .. pages, 0, 0, fontName[1], 12)
        pageText.x = 290; pageText.y = 65 - yO*2
        pageText:setTextColor(210,210,210) -- create text object for page numbers

        localGroup:insert(pageText)

        localGroup:insert(hudGroup)

    end


    local createLogos = function() -- function to prepare game for loading of logos
       local s = 0.4
        if _G.sound == 0 then s = 0; end
        audio.setVolume(s)
        loading = true
        localGroup:insert(logoGroup)
    end

    local createBombs = function ()

        local i = display.newImageRect("optbg.png", 280, 360) -- load and position the border image
        i.x = 160 ; i.y = 245; i.alpha = 1
        bomb.bg = i
        bombGroup:insert(i)

        local t = display.newText("Get Help!", 0, 0, fontName[1], 24)
        t.x = 160
        t.y = 100
        t:setTextColor(255,255,255)
        bomb.title = t
        bombGroup:insert(t)

        local i = display.newImageRect("red_btn.png", 160, 50) -- load and position the border image
        i.x = 160 ; i.y = 384; i.alpha = 1
        bomb.cancel = i
        i.cost = 0
        bombGroup:insert(i)
        i:addEventListener("touch",touchHelp)
        i.id = 5

        local t = display.newText("Cancel", 0, 0, fontName[1], 16)
            t.x = 161
            t.y = 381+ o
            t:setTextColor(0,0,0)
            bomb.txt1 = t
            bombGroup:insert(t)

            local t = display.newText("Cancel", 0, 0, fontName[1], 16)

            t.x = 160
            t.y = 380+ o
            t:setTextColor(255,255,255)
            bomb.txt2 = t
            bombGroup:insert(t)


        local txt = {"Show Location", "Remove Letters","Reveal Letter","Reveal Answer"}
        local cost = {5, 25, 15, 100}
        local nm = "pig"

        for a = 1, 4, 1 do

            if a == 4 then nm = "pig"; end
            local i = display.newImageRect("green_btn.png", 200, 50) -- load and position the border image
            i.x = 160 ; i.y = 100 + a * 56; i.alpha = 1
            bomb[a] = i
            i.cost = cost[a]
            bombGroup:insert(i)
            i.id = a
            i:addEventListener("touch",touchHelp)

            local t = display.newText(txt[a], 0, 0, fontName[1], 14)
            t:setReferencePoint(display.CenterRightReferencePoint)
            t.x = 185
            t.y = 98 + (a*56) + o
            t:setTextColor(0,0,0)
            bomb[a].txt1 = t
            bombGroup:insert(t)

            local t = display.newText(txt[a], 0, 0, fontName[1], 14)
            t:setReferencePoint(display.CenterRightReferencePoint)
            t.x = 184
            t.y = 97 + (a*56) + o
            t:setTextColor(255,255,255)
            bomb[a].txt2 = t
            bombGroup:insert(t)

            local i = display.newImageRect(nm..".png", 24,20) -- load and position the border image
            i.x = 202 ; i.y = 100+ a * 56; i.alpha = 1
            bomb[a].coin = i
            bombGroup:insert(i)
            i:setFillColor(250,250,0)

            local t = display.newText(cost[a], 0, 0, fontName[1], 12)
            t:setReferencePoint(display.CenterLeftReferencePoint)
            t.x = 225
            t.y = 98 + (a*56) + o
            t:setTextColor(0,0,0)
            bomb[a].cost1 = t
            bombGroup:insert(t)

            local t = display.newText(cost[a], 0, 0, fontName[1], 12)
            t:setReferencePoint(display.CenterLeftReferencePoint)
            t.x = 224
            t.y = 97 + (a*56) + o
            t:setTextColor(255,255,255)
            bomb[a].cost2 = t
            bombGroup:insert(t)

        end


        --keyGroup:insert(bombGroup)



    end


    local createAfter = function ()

        after.coins = {}
        --after.word = {}

        local i = display.newImageRect("optbg.png", 190,300) -- load and position the border image
        i.x = 160 ; i.y = 330; i.alpha = 1
        i.rotation = 90
        after.bg = i
        afterGroup:insert(i)

        local t = display.newText("Crystal Palace", 0, 0, fontName[1], 24)
        t.x = 160
        t.y = 260
        t:setTextColor(245,245,245)
        after.title = t
        afterGroup:insert(t)

        local wd = ""

--        for a = 1, tl.wLeng, 1 do
--
--         local t = display.newText(tl.wordArray[a], 0, 0, fontName[1], 32)
--            t.x = 19 * a
--            t.y = 146
--            t:setTextColor(255,255,255)
--            afterWord[a] = t
--            wordGroup:insert(t)
--
--
--        end
--

--        wordGroup:setReferencePoint(display.CenterReferencePoint)
--        wordGroup.x = 160
        afterGroup:insert(wordGroup)



        local t = display.newText("England", 0, 0, fontName[1], 18)
        t.x = 160
        t.y = 186
        t.alpha = 0
        t:setTextColor(255,50,50)
        after.word = t
        afterGroup:insert(t)

        local tit = {"Time Taken: ","Revealed: ","Removed: ", "Incorrect: ","Score: "}

        local sz = 12
        local gp = 0

        for a = 1, 5, 1 do

            if a == 5 then sz = 16; gp = 3; end

            local t = display.newText(tit[a], 0, 0, fontName[1], sz)

            t:setReferencePoint(display.CenterRightReferencePoint)
            t:setTextColor(250,150,0)

            --if a== 5 then t:setTextColor(250,250,0); end
            t.x = 160
            t.y = 270 + (a* 18) + gp + o
            after[a] = t
            afterGroup:insert(t)

            local t = display.newText("Test", 0, 0, fontName[1], sz)

            t:setReferencePoint(display.CenterLeftReferencePoint)
            t:setTextColor(230,230,0)
            t.x = 200
            t.y = 270 + (a* 18) + gp + o
            after[a].txt = t
            afterGroup:insert(t)


        end

         local i = display.newImageRect("green_btn.png", 150,36) -- load and position the border image
            i.x = 160 ; i.y = 398; i.alpha = 0
            after.button = i
            afterGroup:insert(i)
            i:addEventListener("touch",touchNext)

            local t = display.newText("Continue", 0, 0, fontName[1], 16)
        t.x = 161
        t.y = 395 + o
        t:setTextColor(0,0,0)
        after.txt1 = t
        afterGroup:insert(t)
        t.alpha = 0

              local t = display.newText("Continue", 0, 0, fontName[1], 16)
        t.x = 160
        t.y = 394 + o
        t:setTextColor(255,255,255)
        after.txt2 = t
        afterGroup:insert(t)
        t.alpha = 0



    keyGroup:insert(afterGroup)

    end


    local createKeyboard = function() -- function to create the answer entry screen and custom keyboard


        keyBg = display.newImageRect("keybg.jpg", 450, 584)
        keyBg.x = 160; keyBg.y = 240
        keyBg:setFillColor(225, 220, 220)
        keyBg.alpha = 1
        keyGroup:insert(keyBg) -- load and position a background image for entry screen

        fbBtn = display.newImageRect("text.png", 160, 24)
        fbBtn.x = 160; fbBtn.y = 84
        fbBtn.alpha = 0
        keyGroup:insert(fbBtn)
        fbBtn:addEventListener("touch", fbHelp)
        fbBtn:setFillColor(cols[1], cols[2], cols[3]) -- load a button image for facebook help

        fbText = display.newText("ask for help on facebook!", 0, 0, fontName[1], 12)
        fbText.x = 100
        fbText.y = 84 + o
        fbText:setTextColor(0, 0, 0)
        keyGroup:insert(fbText)
        fbText.alpha = 0 -- create text for fb button

        hintBtn = display.newImageRect("text.png", 160, 24)
        hintBtn.x = 160; hintBtn.y = 142
        hintBtn.alpha = 0
        keyGroup:insert(hintBtn)
        hintBtn:addEventListener("touch", touchBomb)
        hintBtn:setFillColor(cols[1] - 20, cols[2] - 20, cols[3] - 20) -- load a button image for going to hint screen

        hintBtnText = display.newText("get hint!", 0, 0, fontName[1], 14)
        hintBtnText.alpha = 0
        hintBtnText.x = 68
        hintBtnText.y = 142 + o
        hintBtnText:setTextColor(r, g, b)
        keyGroup:insert(hintBtnText) -- create text for hint button

        solveBtn = display.newImageRect("text.png", 160, 24)
        solveBtn.x = 160; solveBtn.y = 199
        solveBtn.alpha = 0
        keyGroup:insert(solveBtn)
        solveBtn:addEventListener("touch", touchBomb)
        solveBtn:setFillColor(cols[1] - 40, cols[2] - 40, cols[3] - 40) -- load a button image for solving logo using coins

        solveBtnText = display.newText("resolve!", 0, 0, fontName[1], 14)
        solveBtnText.x = 68
        solveBtnText.y = 199 + o
        solveBtnText.alpha = 0
        solveBtnText:setTextColor(0, 0, 0)
        keyGroup:insert(solveBtnText) -- create text for solve button

        zoomText = display.newText("Tap to zoom", 0, 0, fontName[1], 24)
        zoomText.x = 240
        zoomText.y = 204
        zoomText:setTextColor(210,210,210)
        keyGroup:insert(zoomText)
        zoomText.xScale = 0.5; zoomText.yScale = 0.5 -- create text to prompt user to zoom into logo



        word = display.newText("", 0, 0, fontName[1], 16)
        word.x = 160; word.y = 246 + o
        word:setTextColor(25, 22, 25)
        keyGroup:insert(word) -- create text object for answer
        word.alpha = 0

        local i = display.newImageRect("bomb.png", 44,44) -- load and position the border image
        i.x = 290 + xO ; i.y = 140 - yO*2; i.alpha = 1
        word.bomb = i
        keyGroup:insert(i)
        i:addEventListener("touch",touchBomb)



        local i = display.newImageRect("fb.png", 44,44) -- load and position the border image
        i.x = 290 + xO; i.y = 186 - yO*2; i.alpha = 1
        word.fb = i
        i:addEventListener("touch",touchFb)

        keyGroup:insert(i)


        local t = display.newText("", 0, 0, 100, 60, fontName[1], 10)

        t.y = 180 + o - yO
        t:setTextColor(240,240,240)
        word.cat  = t
        keyGroup:insert(t)
        t.alpha = 1
        word.cat:setReferencePoint(display.CenterReferencePoint)
         t.x = 78 - xO
    --hud.cat.x = 320 - (320-wd)/2





        keyGroup:insert(kbGroup) -- insert the keyboard into the entry screen display group
    end




    local createCongrats = function() -- function to create the congrats popup after a logo is solved

        conbg = display.newImageRect("optbg.png", 160, 310)
        conbg.rotation = 90
        conbg.x = 160; conbg.y = 350
        conbg.alpha = 0.9
        conbg:setFillColor(cols[1], cols[2], cols[3]) -- load the background image and colour the same as the top bar
        congratGroup:insert(conbg)

        concl = display.newRoundedRect(0, 0, 150, 50, 18)
        concl.x = 160; concl.y = 384
        concl:setFillColor(25, 25, 25)
        concl.alpha = 0.4
        concl:addEventListener("touch", congratCloseTouch) -- create a rounded rectangle button to close the congrats screen
        congratGroup:insert(concl)

        conText[1] = display.newText("correct!", 0, 0, fontName[1], 38)
        conText[1].x = 160
        conText[1].y = 302 + o
        conText[1]:setTextColor(0, 0, 0)
        congratGroup:insert(conText[1]) -- create text object for 'correct' message

        conText[2] = display.newText("", 0, 0, fontName[1], 24)
        conText[2].x = 160
        conText[2].y = 338 + o
        conText[2]:setTextColor(255, 255, 255) -- create text object to display score
        congratGroup:insert(conText[2])

        conText[3] = display.newText("done!", 0, 0, fontName[1], 20)
        conText[3].x = 160
        conText[3].y = 382 + o
        conText[3]:setTextColor(255, 255, 255)
        congratGroup:insert(conText[3]) -- create text object for 'done' button

        congratGroup.y = 600 -- move the congrats popup off screen for now
        keyGroup:insert(congratGroup) -- insert popup into the entry screen group
    end

    local createAd = function() -- function to create an in-house ad interstitial

        local i = display.newRect(0, 0, 90, 40)
        i.x = 60; i.y = 205
        adGroup:insert(i)
        i.alpha = 0.5
        i.id = 1 -- add ID number so button can be identified by touch listener
        i:addEventListener("touch", touchAd) -- create a cancel button and add touch listener

        local i = display.newRect(0, 0, 90, 40)
        i.x = 60; i.y = 255
        adGroup:insert(i)
        i.alpha = 0.5
        i.id = 2 -- add ID number so button can be identified by touch listener
        i:addEventListener("touch", touchAd) -- create an ok button and add touch listener

        if doesFileExist("ad.jpg", system.CachesDirectory) == false then

            local i = display.newImageRect("ad.jpg", 320, 480)
            i.x = 160; i.y = 240
            adGroup:insert(i)
            adImage[1] = i

        else

            local i = display.newImageRect("ad.jpg", system.CachesDirectory, 320, 480)
            i.x = 160; i.y = 240
            adGroup:insert(i)
            adImage[1] = i
        end -- load the appropriate ad image (use the one downloaded from server if available)

        localGroup:insert(adGroup) -- insert ad display group into main display group
        adGroup.x = 600 -- move the ad group off screen for now
    end


    local createLevelUp = function() -- function to create the level-up popup

        lupBg = display.newImageRect("optbg.png", 180,310)
        lupBg.rotation = 90
        lupBg.x = 160; lupBg.y = 0
        lupBg.alpha = 1
        --lupBg:setFillColor(cols[1], cols[2], cols[3]) -- load background and colour the same as top bar
        lupGroup:insert(lupBg)

        lupText[1] = display.newText("Congratulations!", 0, 0, fontName[1], 24)
        lupText[1].x = 160
        lupText[1].y = -20 + o
        lupText[1]:setTextColor(255,255,255) -- create congratulations message text object

        lupGroup:insert(lupText[1])

        lupText[2] = display.newText("You just unlocked level 2!", 0, 0, fontName[1], 14)
        lupText[2].x = 160
        lupText[2].y = 20 + o
        lupText[2]:setTextColor(255,255,0)
        lupGroup:insert(lupText[2]) -- create text object to show which level was complete

        lupGroup.y = -100 -- move the level up group off scren
        lupGroup.alpha = 0 -- hide for now
        localGroup:insert(lupGroup) -- insert level up group into main display group
    end

    local createClues = function() -- function to create the cluesscreen

        cluebg = display.newImageRect("cluebg.png", 250, 170)
        cluebg.x = 190; cluebg.y = 142
        cluebg.alpha = 1
        clueGroup:insert(cluebg) -- load clue text background image

        for a = 1, 3, 1 do

            clueText[a] = display.newText("", 0, 0, 210, 80, fontName[1], 10)
            clueText[a].x = 190
            clueText[a].y = 70 + (a * 50) + o
            clueText[a]:setTextColor(0, 0, 0)
            clueGroup:insert(clueText[a])
        end -- create and position clue text objects

        for a = 1, 4, 1 do

            local clueArray = { "1", "2", "3", "X" } -- array for clue button text objects

            clueBtn[a] = display.newImageRect("key2.png", 36, 36)
            clueBtn[a].x = 30
            clueBtn[a].rotation = 0
            clueBtn[a].y = 32 + (a * 36) + 24
            clueBtn[a].value = string.lower(clueArray[a])
            clueBtn[a].id = a
            clueBtn[a]:addEventListener("touch", pressClue)
            clueBtn[a].alpha = 0.9
            clueGroup:insert(clueBtn[a])
            clueBtn[a]:setFillColor(150, 150, 250) -- create clue buttons with IDs and add touch listener

            local t = display.newText(clueArray[a], 0, 0, fontName[1], 20)
            t.x = 30
            t.y = 33 + (a * 36) + o + 24
            t:setTextColor(0, 0, 0) -- create clue button text objects and position

            clueBtnText[a] = t -- add to array
            clueGroup:insert(clueBtnText[a])
        end
    end

    createScreen() -- call function to create the HUD
    createLogos() -- call function to prepare logos for loading
    createAd() -- call function to creat in-house ad interstitial
    keyGroup.x = 600 -- move entry screen group off screen
    clueGroup.x = 400 -- move clue screen group off screen
    createKeyboard() -- call function to create the keyboard and entry screen
    createCongrats() -- call function to create the congrats popup
    createLevelUp() -- call function to create the level-up popup
    createClues() -- call function to create clues screen
    createBombs()
    createAfter()


    bombGroup.x = 600
    afterGroup.x = 600

    localGroup:insert(keyGroup) -- insert entry screen into main display group
    localGroup:insert(clueGroup) -- insert clue screen into main display group
end

-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene(event)
    local group = self.view
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene(event)
    local group = self.view

    --displayAds()


    local previous = storyboard.getPrevious()

    if previous ~= "main" and previous then
        storyboard.removeScene(previous)
    end

    for b = 1, nLevel, 1 do
        dispOrd[b] = b
    end

    shuffle(dispOrd)

    Runtime:addEventListener("enterFrame", gameLoop)

    local choose = math.random(1, 5)

    if choose == 1 and _G.paid == 0 and _G.osTarget == "iOS" then
        timer.performWithDelay(500, callIap)
        _G.iapUp = 1
    else
        if _G.iapUp == 0 and _G.paid == 0 and _G.osTarget == "iOS" then
            timer.performWithDelay(500, callIap)
            _G.iapUp = 1
        end
    end
end


-- Called when scene is about to move offscreen:
function scene:exitScene(event)
    local group = self.view
end

-- Called AFTER scene has finished moving offscreen:
function scene:didExitScene(event)
    local group = self.view

    display.getCurrentStage():setFocus(nil)
    Runtime:removeEventListener("touch", touchScreen)
    Runtime:removeEventListener("enterFrame", gameLoop)

     display.remove(bombGroup)


    bombGroup = nil

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
end

-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
function scene:overlayEnded(event)
    local group = self.view
    local overlay_scene = event.sceneName -- overlay scene name

    transition.to(localGroup, { time = 500, alpha = 1 })
    coinText.text = coins


    local reloadIt = function()

        storyboard.reloadScene("app")
    end

    if _G.bought == 2 then

        settings.paid = 1
        coins = coins + 200
        settings.coins = coins
        coinText.text = coins
        coinText.text = coins
        audio.play(sounds.coinup)
        settings:save()

    end
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



