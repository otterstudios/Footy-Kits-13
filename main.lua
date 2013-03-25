display.setStatusBar( display.HiddenStatusBar )									-- hide the status bar
system.setIdleTimer(false)																	-- disable device sleeping
audio.setSessionProperty(audio.MixMode, audio.AmbientMixMode)		-- allow user's background music to play
_G.osTarget = "iOS"									-- device to target for current build
---------------------------------------------------------------------------------
-- LIBRARIES					-- load global libraries that will be used throughout the app
---------------------------------------------------------------------------------

local storyboard = require "storyboard"		-- import storyboard library
json = require("json")								-- import json library (used by GGData)
GGData = require("GGData") 					-- import data storage library (courtesy of Glitch Games)
settings = GGData:new("settings")			-- load data storage object
facebook = require("facebook")				-- import facebook library for facebook integration
gameNetwork = require("gameNetwork")	-- import gamenetwork library for GameCenter
iap = require("iap") 						-- import in-app purchasing (must edit iap.lua with your info)
require "revmob"							-- import revmob library for interstitial CPI ads (recommended for good eCPM)

---------------------------------------------------------------------------------
-- LOCAL VARIABLES
---------------------------------------------------------------------------------

local scene = storyboard.newScene()		-- initialise this scene
local myScene = "template"							-- which scene to load first (useful for debugging specific scenes)
local testing = false					-- whether or not to use testing mode for debugging
local first = settings.first							-- get whether or not the app has been run before (if not, first = nil)
--first = nil  ;native.showAlert("DEBUG","Remember to comment this out!",{"OK"})		-- uncomment to simulate first app run

local config = "http://www.otterstudios.co.uk/kits_13_10.cfg"		-- location of external config file for iOS
local appId = "490946604288037"											-- facebook app ID
local inneractive =  "OtterStudios_FootyKits13_iPhone"		-- inneractive app ID for iOS
local REVMOB_IDS = { ["Android"] = "514dd57b575ed7be000000d5", ["iPhone OS"] = "514dd585cbcbe80800000086" }		-- revmob app IDs

---------------------------------------------------------------------------------
-- GLOBAL VARIABLES
---------------------------------------------------------------------------------


_G.adShow = "Mediate" 								-- which advert system to use (Corona native inneractive ads are currently crashing on first run)
_G.rateIt = 0												-- whether or not the 'rate this app' popup has appeared during this session
_G.popup = settings.popup							-- whether or not to show 'rate me' popups
_G.revShow = settings.revmob					-- whether or not to show revmob popups (may want to disable them during apple review process)
_G.en = system.getInfo("environment")			-- whether or not app is running on simulator or device
_G.showAds = 0										-- whether or not to show banner adverts
_G.bought = 0											-- flag for type of last purchase to pass between scenes
_G.iapUp = 0												-- whether or not the in-app purchase prompt has been shown this session or not
_G.adTimer = system.getTimer()  -750000	-- timer for in-house cross-promotion ads
_G.revTimer = system.getTimer()					-- timer for revmob interstitials
_G.fbType = "about"									-- type of facebook posting to make
_G.hintCount = 0										-- count for awarding of hints, increments one every correct answer
_G.hintTime = 3											-- threshold for awarding of hints, once hintCount reaches this a hint is awarded
_G.adCount = 6											-- counting of correct answers, revmob interstial shown when adCount = 8
_G.startTime = system.getTimer()				-- timer for awarding of free hints based on gameplay time
_G.loggedIntoGC = false								-- whether or not user successfully signed into GameCenter
_G.fbPopup = 0											-- whether or not 'like us on facebook' popup has appeared this session
_G.platformName = system.getInfo("platformName")		-- platform the app is running on (iPhone OS, Android etc)
_G.fontName = {}										-- array to hold font information
_G.o = 0													-- 'y' offset amount for text positioning differences between simulator and device
_G.sounds = {}											-- array to hold sound files

_G.device = system.getInfo("model")
_G.model = "I4"; _G.xO = 0; _G.yO = 0

if display.pixelHeight ~= nil then
    if (( "iPhone" == system.getInfo( "model" ) ) or ( "iPhone Simulator" == system.getInfo( "model" ) ) ) and ( display.pixelHeight > 960 ) then _G.model = "I5"; end
    if (display.pixelHeight == 1024 or display.pixelHeight == 2048) then _G.model = "IP"; end
else

end

local xu = 322
if _G.model == "I5" then _G.yO = 22; end
if _G.model == "IP" then _G.xO = 0; _G.xO = 20; end

if _G.osTarget == "Amazon" or  _G.osTarget == "Android" then
	config = "http://www.otterstudios.co.uk/kits_13_10a.cfg";										-- select different configs/app IDs dependent on device target
	inneractive =  "OtterStudios_FootyKits13_Android"
    _G.o = 2
end


if _G.popup == nil then _G.popup = 0; end			-- if a value doesn't exist yet in the data storage, set to zero
if _G.revShow == nil then _G.revShow = 0; end

if en == "device" and _G.platformName == "iPhone OS" then
    _G.o = 2												-- 'y' offset amount for differences between simulator/device/
end


---------------------------------------------------------------------------------
-- ADVERTS																	-- initialise advert library depending on current choice in _G.adShow
---------------------------------------------------------------------------------

if _G.adShow == "Mediate" then
require("admediator")

local sc = display.contentScaleX
print (sc.." "..display.pixelWidth)

local sw = display.pixelWidth*sc - 320
local sc = display.contentScaleX
print ("WIDTH EXTRA: "..sw.." "..sc)

local xu = xO/2
if _G.osTarget == "Amazon" then xu = 35; end

if _G.osTarget == "Android" then xu = 0; end

AdMediator.init(xu,430+yO*2,60)											-- position at x = 0, y = 430 and use 60 second intervals
AdMediator.enableAutomaticScalingOnIPAD(true)			-- scale up iPad adverts
AdMediator.addNetwork(
        {
            name="admediator_inneractive", weight=20, backfillpriority=2,
            enabled=true, networkParams = {clientKey=inneractive}
        }
    )
end



if _G.adShow == "Inner" then
    ads = require"ads";
    ads.init("inneractive",inneractive)
end

if testing == false then									-- whether or not to use revmob in testing mode
        RevMob.startSession(REVMOB_IDS)
else
    RevMob.startSession(REVMOB_IDS, RevMob.TEST_WITH_ADS)
end

---------------------------------------------------------------------------------
-- SOUNDS																		-- load sounds into memory
---------------------------------------------------------------------------------



sounds["solved"] = audio.loadSound("FM_crowd_cheer1.mp3")
--sounds["nearly"] = audio.loadSound("nearly.mp3")
sounds["wrong"] = audio.loadSound("FM_crowd_groans.mp3")
sounds["nearly"] = audio.loadSound("FM_crowd_near_miss.mp3")
sounds["levelup"] = audio.loadSound("FM_crowd_cheer_win.mp3")
sounds[7] = audio.loadSound("FM_kick1.mp3")
sounds[8] = audio.loadSound("FM_kick2.mp3")
sounds[9] = audio.loadSound("FM_kick3.mp3")
sounds[10] = audio.loadSound("FM_kick4.mp3")
sounds[11] = audio.loadSound("FM_kick5.mp3")
sounds["coinup"] = audio.loadSound("coinup.mp3")
sounds["hintup"] = audio.loadSound("hintup.mp3")
sounds[1] = audio.loadSound("w1.mp3")
sounds[2] = audio.loadSound("w2.mp3")
sounds[3] = audio.loadSound("w3.mp3")
sounds[4] = audio.loadSound("w4.mp3")
sounds[5] = audio.loadSound("w5.mp3")
sounds[6] = audio.loadSound("w6.mp3")
sounds["spent"] = audio.loadSound("spent.mp3")
sounds["woosh"] = audio.loadSound("whoosh.mp3")
sounds["intro"] = audio.loadStream("intro.mp3")



---------------------------------------------------------------------------------
-- FONTS																		-- initialise fonts depending on device type
---------------------------------------------------------------------------------

fontName[1] = "Chinacat"; if platformName == "Android" then fontName[1] = "chint___"; end

---------------------------------------------------------------------------------
-- FIRST RUN											-- sets up storage database on first run
---------------------------------------------------------------------------------

function shuffle(t)
    local rand = math.random; assert(t, "table.shuffle() expected a table, got nil")
    local iterations = #t; local j

    for i = iterations, 2, -1 do
        j = rand(i); t[i], t[j] = t[j], t[i] 				-- function to shuffle a table (used for shuffling clues)
    end
end

local firstRun = function ()
end

if first == nil then

    local levelTemp = GGData:new("levels")			-- create level data storage object
    local logoTemp = GGData:new("logos")			-- create logos data storage object
    local orderTemp = GGData:new("clueOrder")       -- create clues data storage object
    local answerTemp = GGData:new("answers")

    local levels = {}											-- set up a database for level information

    levels[1] = {}												-- each level has its own array of information
	levels[1]["open"] = 1									-- open first level
	levels[1]["solved"] = 0									-- the number of logos solved on a level
	levels[1]["score"] = 0									-- the total score on a level

    for a = 2, 20, 1 do
        levels[a] = {}; levels[a]["open"] = 0; levels[a]["solved"] = 0; levels[a]["score"] = 0	-- setup and lock remaining levels
    end


    local logos = {}												-- set up a database for logo information
    local clueOrder = {}
    local answers = {}                                           -- set up a database for the random order of clues

    for a = 1,1000, 1 do											-- loop through all logos

        logos[a] = {}; 												-- each logo has its own array of information

		logos[a]["solved"] = 0									-- whether or not the logo is solved
		logos[a]["wrong"] = 0								-- how many guesses the player made on this logo
		logos[a]["revealed"] = 0									-- how many hints the player has used
        logos[a]["score"] = 999								-- current score on this logo
		logos[a]["removed"] = 0									-- number of typing errors made
		logos[a]["category"] = 0
        logos[a]["time"] = 0									-- number of times the player was almost correcy
		logos[a]["last"] = ""
        logos[a]["guesses"] = 0

        answers[a] = {}
      											-- each logo has its own array of information

		for b = 1, 30, 1 do
            answers[a][b] = 0      									-- whether or not the logo is solved
        end									-- string to hold the last answer typed on this logo


        clueOrder[a] = {}							-- array to hold the order in which clues should be shown

        for b = 1, 3, 1 do										-- cycle through the three clues

        	clueOrder[a][1] = 1
        	clueOrder[a][2] = 2						-- put in ascending order
         	clueOrder[a][3] = 3
        end

		shuffle(clueOrder[a])						-- use the shuffle function to shuffle the order of clues for this logo

    end

	logoTemp.data = logos					-- add the logos table to the saved data
    orderTemp.data = clueOrder
    answerTemp.data = answers
  	settings.totalScore = 0					-- total score achieved by the player
	settings.solved = 0							-- total logos solved by the player
	settings.rated = 0							-- whether or not the user clicked to rate the game yet
	settings.hints = 200					-- initial number of hints given to the player
	settings.coins = 150					-- initial number of coins given to the player
	settings.currentLevel = 1					-- current level being played
	levelTemp.data = levels					-- add the levels table to the levels data
	settings.unlocked = 1						-- number of levels unlocked
	settings.first = 1								-- mark that the app has now been run for the first time
	settings.sound = 1							-- whether or not sound should play
	--settings.hintsUsed = 0					-- total number of hints used by the player
	settings.guesses = 0						-- total number of guesses made by the player
	settings.paid = 0 							-- whether or not the user upgraded via IAP
	settings.clicked = 0 						-- whether or not the player clicked on the in-house ad yet
	settings.liked = 0							-- whether or not the player clicked to like your facebook page yet
	--settings.seenInstruct = 0				-- whether or not the player has seen the instructions popup yet
    settings.coinTotal = 0
    settings.photo = 0
    settings.wrong = 0
    settings.skipped = 0
    settings.coinSpent = 0
    settings:save()								-- save database to disk
    logoTemp:save()								-- save database to disk
    levelTemp:save()								-- save database to disk
    orderTemp:save()
    answerTemp:save()
    _G.paid = 0									-- we know the user can't have paid as this is the first run

else

    _G.paid = settings.paid			-- this is not first run, so see if the user has upgraded or not

    if _G.paid == 0 and _G.revShow == 1 then			-- if the user hasn't paid and revmob turned on, show interstitial

        local waitBit = function()
            RevMob.showFullscreen()
        end

        --timer.performWithDelay(5500,waitBit)				-- give revmob some time to initialise startSession command run above
    else
        _G.hintTime = 2										-- if the user has upgraded, reduce the number of questions needed to get a bonus hint
    end
end


---------------------------------------------------------------------------------
-- EXTERNAL CONFIG FILE
---------------------------------------------------------------------------------

function configListener(event)							-- listener to handle retrieval of config file from server
    if (event.isError) then
        print("Network error!")
    else
        local params = json.decode(event.response)

        if params ~= nil then

            if tonumber(params.config.popup) ~= _G.popup then
                _G.popup = tonumber(params.config.popup)				-- if popup parameter has changed, update and save to disk
                settings.popup = _G.popup
                settings:save()
            end

             if tonumber(params.config.showAds) == 1 then
                _G.showAds = 1												-- if set to show ads on server, update global variable
            end

		    if tonumber(params.config.revShow )~= _G.revShow then
                _G.revShow = tonumber(params.config.revShow)
                settings.revmob = _G.revShow						-- if revmob show parameter has changed, update and save
                settings:save()
            end

            if params.config.itunes ~= nil then						-- if in-house

                local it = settings.url

                if it ~= params.config.itunes then				-- if in-house ad app ID has changed, get the new one and download new ad image
                    it = params.config.itunes
                    settings.url = it
                    settings.clicked = 0						-- reset clicked parameter as the user has a new in-house ad to see
                    settings:save()
                    network.download( "http://otterstudios.co.uk/ad.jpg", "GET", downloadListener, "ad.jpg",system.CachesDirectory );
                end
            end

        end

    end
end

network.request(config, "GET", configListener)					-- send a request to get the config file from the server




---------------------------------------------------------------------------------
-- GLOBAL FUNCTIONS
---------------------------------------------------------------------------------
function updateCoins ()

    settings.coins = settings.coins + 300
    settings:save()


end

function displayAds()

     local device = system.getInfo("model")
     local ady
     local adx
     local isTall = false

    if display.pixelHeight ~= nil then
        isTall = ( "iPhone" == system.getInfo( "model" ) ) and ( display.pixelHeight > 960 )
    end

     if string.sub(device, 1, 4) == "iPad" then
        ady = 950; adx = 0; aos = 0;
     else
        ady = 430
        adx = 0
        if isTall == true then ady = 530; end
     end

    if _G.adShow == "Mediate" then
        AdMediator.start()
    end

    if _G.adShow == "Inner" then
        ads.show("banner", { x = adx, y = ady, interval = 180 })
    end

end



function hideAds()												-- global function to hide ads whatever the ad mediator/engine is being used when user upgrades

    if _G.adShow == "Mediate" then
    	AdMediator.hide()
    end

     if _G.adShow == "Inner" then
    	ads.hide()
    end

end


swipe = function()								-- global function to play a random 'swipe' sound

    local playIt = function()

        local s = math.random(1, 6)

        audio.play(sounds[s])
    end
    timer.performWithDelay(350, playIt)
end


doink = function(obj)							-- global function to animate buttons
    local obj = obj
    transition.to(obj, { time = 100, xScale = 1.2, yScale = 1.2 })
    transition.to(obj, { delay = 100, time = 300, xScale = 1, yScale = 1 })
end

function doesFileExist(theFile, path)		-- global function to find if a file exists (not currently used but may be useful!)
        local thePath = path or system.DocumentsDirectory
        local filePath = system.pathForFile(theFile, thePath)
        local results = false

        local file = io.open(filePath, "r")

        --If the file exists, return true
        if file then
                io.close(file)
            results = true
        end

        return results
end




function testNetworkConnection()							-- global function to test whether or not the device currently has internet access
    local netConn = require('socket').connect('www.apple.com', 80)
    if netConn == nil then
        return false
    end
    netConn:close()
    return true
end



---------------------------------------------------------------------------------
-- INITIALISE
---------------------------------------------------------------------------------

local function initCallback(event)							-- callback function for gameCenter login
    if event.data then
        loggedIntoGC = true
        --native.showAlert( "Success!", "User has logged into Game Center", { "OK" } )
    else
        loggedIntoGC = false
        -- native.showAlert( "Fail", "User is not logged into Game Center", { "OK" } )
    end
end

_G.sound = settings.sound				-- set sound according to saved parameter
audio.setVolume(_G.sound)

function initGameCenter()
    gameNetwork.init("gamecenter", initCallback)
end

if _G.osTarget == "iOS" then initGameCenter(); end


---------------------------------------------------------------------------------
-- FACEBOOK								-- function to handle facebook posting
---------------------------------------------------------------------------------

local function callFacebook(event)
    if ("session" == event.type) then
        if event.phase ~= "login" then
            return
        end

        if fbCommand == POST_ABOUT and _G.fbType == "about" then

            local postMsg
            if _G.osTarget == "iOS" then
                    postMsg = {
                    message = "is playing Logos Quiz...",
                    name = "Logos Quiz on iOS and Amazon Kindle",
                    caption = "Download now on the app store!",
                    link = "https://itunes.apple.com/us/app/video-games-quiz/id577836095?ls=1&mt=8",
                    picture = "http://www.otterstudios.co.uk/logo256.jpg"
                }
            end

              if _G.osTarget == "Amazon" then
                    postMsg = {
                    message = "is playing Football Logos Quiz on Kindle...",
                    name = "Football Logos Quiz on Amazon Kindle",
                    caption = "Download now on the Amazon Store!",
                    link = "http://www.amazon.com/gp/mas/dl/android?p=com.otterstudios.footylogos",
                    picture = "http://www.otterstudios.co.uk/logo256.jpg"
                }
            end



            facebook.request("me/feed", "POST", postMsg)
        end
if fbCommand == POST_MSG and _G.fbType == "logo" then

            local attachment

            if _G.platformName ~= "Android" then
               -- (NOTE: available starting in daily build 2011.709)
                attachment = {
                    message = "I'm stuck on Football Kits Quiz '13, which team is this?",
                    source = {
                            baseDir=system.TemporaryDirectory,
                            filename="screenshot"..settings.photo..".jpg",
                            type="image"
                                },
                            }

            else
               attachment = {
                    message = "I'm stuck on Football Kits Quiz '13, which team is this?",
                    source = {
                            baseDir=system.TemporaryDirectory,
                            filename="screenshot"..settings.photo..".jpg",
                            type="image"
                                },
                            }
            end

            facebook.request( "me/photos", "POST", attachment)
        end


    elseif ("request" == event.type) then

        local response = event.response

        if (not event.isError) then

            response = json.decode(event.response)

        else
            statusMessage.textObject.text = "Post failed"
        end

    elseif ("dialog" == event.type) then
    end
end


if (appId and testNetworkConnection) then
    function postmymsg(event)
        fbCommand = POST_MSG
        facebook.login(appId, callFacebook, { "publish_stream" })
    end
end

if (appId and testNetworkConnection) then
    function postabout(event)
        fbCommand = POST_ABOUT
        facebook.login(appId, callFacebook, { "publish_stream" })
    end
end




---------------------------------------------------------------------------------
-- STORYBOARD FUNCTIONS
---------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
function scene:createScene(event)
    local group = self.view

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

scene:addEventListener("createScene", scene)
scene:addEventListener("willEnterScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("didExitScene", scene)
scene:addEventListener("destroyScene", scene)
scene:addEventListener("overlayBegan", scene)
scene:addEventListener("overlayEnded", scene)

if testing == true then

peak = 0
ave = 0
current = 0
all = 0
count = 1

memText = display.newText("",0,0, system.defaultFont, 18)
memText.x = 160
memText.y = 240
memText:setTextColor(0,0,0)

round = math.round
function checkMem()
        collectgarbage()
        current = collectgarbage("count")
        local texUsed = system.getInfo( "textureMemoryUsed" ) / 1000000
        memText:toFront()

       if current > peak then peak = current end

        all = all + current
        ave = all / count
        count = count + 1

       print ("-------------")        print ("p: "    .. round(peak))
        print ("a: "    .. round(ave))
        print ("c: "    .. round(current))
        memText.text = round(current).. " "..round(texUsed)

end

timer.performWithDelay(1000, checkMem, 0)
end


storyboard.gotoScene(myScene)
---------------------------------------------------------------------------------

return scene


