package.preload['json']=(function(...)local e=string
local u=math
local c=table
local i=error
local d=tonumber
local s=tostring
local a=type
local l=setmetatable
local r=pairs
local f=ipairs
local o=assert
local n=Chipmunk
module("json")local n={buffer={}}function n:New()local e={}l(e,self)self.__index=self
e.buffer={}return e
end
function n:Append(e)self.buffer[#self.buffer+1]=e
end
function n:ToString()return c.concat(self.buffer)end
local t={backslashes={['\b']="\\b",['\t']="\\t",['\n']="\\n",['\f']="\\f",['\r']="\\r",['"']='\\"',['\\']="\\\\",['/']="\\/"}}function t:New()local e={}e.writer=n:New()l(e,self)self.__index=self
return e
end
function t:Append(e)self.writer:Append(e)end
function t:ToString()return self.writer:ToString()end
function t:Write(e)local n=a(e)if n=="nil"then
self:WriteNil()elseif n=="boolean"then
self:WriteString(e)elseif n=="number"then
self:WriteString(e)elseif n=="string"then
self:ParseString(e)elseif n=="table"then
self:WriteTable(e)elseif n=="function"then
self:WriteFunction(e)elseif n=="thread"then
self:WriteError(e)elseif n=="userdata"then
self:WriteError(e)end
end
function t:WriteNil()self:Append("null")end
function t:WriteString(e)self:Append(s(e))end
function t:ParseString(n)self:Append('"')self:Append(e.gsub(n,'[%z%c\\"/]',function(n)local t=self.backslashes[n]if t then return t end
return e.format("\\u%.4X",e.byte(n))end))self:Append('"')end
function t:IsArray(t)local n=0
local i=function(e)if a(e)=="number"and e>0 then
if u.floor(e)==e then
return true
end
end
return false
end
for e,t in r(t)do
if not i(e)then
return false,'{','}'else
n=u.max(n,e)end
end
return true,'[',']',n
end
function t:WriteTable(e)local o,t,i,n=self:IsArray(e)self:Append(t)if o then
for t=1,n do
self:Write(e[t])if t<n then
self:Append(',')end
end
else
local n=true;for e,t in r(e)do
if not n then
self:Append(',')end
n=false;self:ParseString(e)self:Append(':')self:Write(t)end
end
self:Append(i)end
function t:WriteError(n)i(e.format("Encoding of %s unsupported",s(n)))end
function t:WriteFunction(e)if e==Null then
self:WriteNil()else
self:WriteError(e)end
end
local r={s="",i=0}function r:New(n)local e={}l(e,self)self.__index=self
e.s=n or e.s
return e
end
function r:Peek()local n=self.i+1
if n<=#self.s then
return e.sub(self.s,n,n)end
return nil
end
function r:Next()self.i=self.i+1
if self.i<=#self.s then
return e.sub(self.s,self.i,self.i)end
return nil
end
function r:All()return self.s
end
local n={escapes={['t']='\t',['n']='\n',['f']='\f',['r']='\r',['b']='\b',}}function n:New(n)local e={}e.reader=r:New(n)l(e,self)self.__index=self
return e;end
function n:Read()self:SkipWhiteSpace()local n=self:Peek()if n==nil then
i(e.format("Nil string: '%s'",self:All()))elseif n=='{'then
return self:ReadObject()elseif n=='['then
return self:ReadArray()elseif n=='"'then
return self:ReadString()elseif e.find(n,"[%+%-%d]")then
return self:ReadNumber()elseif n=='t'then
return self:ReadTrue()elseif n=='f'then
return self:ReadFalse()elseif n=='n'then
return self:ReadNull()elseif n=='/'then
self:ReadComment()return self:Read()else
i(e.format("Invalid input: '%s'",self:All()))end
end
function n:ReadTrue()self:TestReservedWord{'t','r','u','e'}return true
end
function n:ReadFalse()self:TestReservedWord{'f','a','l','s','e'}return false
end
function n:ReadNull()self:TestReservedWord{'n','u','l','l'}return nil
end
function n:TestReservedWord(n)for o,t in f(n)do
if self:Next()~=t then
i(e.format("Error reading '%s': %s",c.concat(n),self:All()))end
end
end
function n:ReadNumber()local n=self:Next()local t=self:Peek()while t~=nil and e.find(t,"[%+%-%d%.eE]")do
n=n..self:Next()t=self:Peek()end
n=d(n)if n==nil then
i(e.format("Invalid number: '%s'",n))else
return n
end
end
function n:ReadString()local n=""o(self:Next()=='"')while self:Peek()~='"'do
local e=self:Next()if e=='\\'then
e=self:Next()if self.escapes[e]then
e=self.escapes[e]end
end
n=n..e
end
o(self:Next()=='"')local t=function(n)return e.char(d(n,16))end
return e.gsub(n,"u%x%x(%x%x)",t)end
function n:ReadComment()o(self:Next()=='/')local n=self:Next()if n=='/'then
self:ReadSingleLineComment()elseif n=='*'then
self:ReadBlockComment()else
i(e.format("Invalid comment: %s",self:All()))end
end
function n:ReadBlockComment()local n=false
while not n do
local t=self:Next()if t=='*'and self:Peek()=='/'then
n=true
end
if not n and
t=='/'and
self:Peek()=="*"then
i(e.format("Invalid comment: %s, '/*' illegal.",self:All()))end
end
self:Next()end
function n:ReadSingleLineComment()local e=self:Next()while e~='\r'and e~='\n'do
e=self:Next()end
end
function n:ReadArray()local t={}o(self:Next()=='[')local n=false
if self:Peek()==']'then
n=true;end
while not n do
local o=self:Read()t[#t+1]=o
self:SkipWhiteSpace()if self:Peek()==']'then
n=true
end
if not n then
local n=self:Next()if n~=','then
i(e.format("Invalid array: '%s' due to: '%s'",self:All(),n))end
end
end
o(']'==self:Next())return t
end
function n:ReadObject()local r={}o(self:Next()=='{')local t=false
if self:Peek()=='}'then
t=true
end
while not t do
local o=self:Read()if a(o)~="string"then
i(e.format("Invalid non-string object key: %s",o))end
self:SkipWhiteSpace()local n=self:Next()if n~=':'then
i(e.format("Invalid object: '%s' due to: '%s'",self:All(),n))end
self:SkipWhiteSpace()local l=self:Read()r[o]=l
self:SkipWhiteSpace()if self:Peek()=='}'then
t=true
end
if not t then
n=self:Next()if n~=','then
i(e.format("Invalid array: '%s' near: '%s'",self:All(),n))end
end
end
o(self:Next()=="}")return r
end
function n:SkipWhiteSpace()local n=self:Peek()while n~=nil and e.find(n,"[%s/]")do
if n=='/'then
self:ReadComment()else
self:Next()end
n=self:Peek()end
end
function n:Peek()return self.reader:Peek()end
function n:Next()return self.reader:Next()end
function n:All()return self.reader:All()end
function encode(n)local e=t:New()e:Write(n)return e:ToString()end
function decode(e)local e=n:New(e)return e:Read()end
function Null()return Null
end
end)package.preload['asyncHttp']=(function(...)local e=require"socket"local n=require"dispatch"local d=require"socket.http"local i=require"ltn12"n.TIMEOUT=10
local t=Runtime
local s=table
local e=print
local e=coroutine
module(...)function request(c,u,o,e)local n=n.newhandler("coroutine")local r=true
n:start(function()local t,f=i.sink.table()local l,a
if e then
if e.headers then
l=e.headers
end
if e.body then
a=i.source.string(e.body)end
end
local i,n,e=d.request{url=c,method=u,create=n.tcp,sink=t,source=a,headers=l}if i then
o{statusCode=n,headers=e,response=s.concat(f),sink=t,isError=false}else
o{isError=true}end
r=false
end)local e={}function e.enterFrame()if r then
n:step()else
t:removeEventListener("enterFrame",e)end
end
function e:cancel()t:removeEventListener("enterFrame",self)n=nil
end
t:addEventListener("enterFrame",e)return e
end
end)package.preload['dispatch']=(function(...)local t=_G
local i=require("table")local r=require("socket")local n=require("coroutine")local a=type
module("dispatch")TIMEOUT=10
local l={}function newhandler(e)e=e or"coroutine"return l[e]()end
local function e(n,e)return e()end
function l.sequential()return{tcp=r.tcp,start=e}end
function r.protect(e)return function(...)local o=n.create(e)while true do
local e={n.resume(o,t.unpack(arg))}local i=i.remove(e,1)if not i then
if a(e[1])=='table'then
return nil,e[1][1]else t.error(e[1])end
end
if n.status(o)=="suspended"then
arg={n.yield(t.unpack(e))}else
return t.unpack(e)end
end
end
end
local function a()local e={}local n={}return t.setmetatable(n,{__index={insert=function(t,n)if not e[n]then
i.insert(t,n)e[n]=i.getn(t)end
end,remove=function(r,o)local t=e[o]if t then
e[o]=nil
local n=i.remove(r)if n~=o then
e[n]=t
r[t]=n
end
end
end}})end
local function s(i,e,o)if not e then return nil,o end
e:settimeout(0)local a={__index=function(i,n)i[n]=function(...)arg[1]=e
return e[n](t.unpack(arg))end
return i[n]end}local r=false
local o={}function o:settimeout(e,n)if e==0 then r=true
else r=false end
return 1
end
function o:send(a,t,l)t=(t or 1)-1
local r,o
while true do
if n.yield(i.sending,e)=="timeout"then
return nil,"timeout"end
r,o,t=e:send(a,t+1,l)if o~="timeout"then return r,o,t end
end
end
function o:receive(a,t)local o="timeout"local l
while true do
if n.yield(i.receiving,e)=="timeout"then
return nil,"timeout"end
l,o,t=e:receive(a,t)if(o~="timeout")or r then
return l,o,t
end
end
end
function o:connect(l,r)local o,t=e:connect(l,r)if t=="timeout"then
if n.yield(i.sending,e)=="timeout"then
return nil,"timeout"end
o,t=e:connect(l,r)if o or t=="already connected"then return 1
else return nil,"non-blocking connect failed"end
else return o,t end
end
function o:accept()while 1 do
if n.yield(i.receiving,e)=="timeout"then
return nil,"timeout"end
local n,e=e:accept()if e~="timeout"then
return s(i,n,e)end
end
end
function o:close()i.stamp[e]=nil
i.sending.set:remove(e)i.sending.cortn[e]=nil
i.receiving.set:remove(e)i.receiving.cortn[e]=nil
return e:close()end
return t.setmetatable(o,a)end
local i={__index={}}function schedule(i,o,e,n)if o then
if i and e then
e.set:insert(n)e.cortn[n]=i
e.stamp[n]=r.gettime()end
else t.error(e)end
end
function kick(e,n)e.cortn[n]=nil
e.set:remove(n)end
function wakeup(t,i)local e=t.cortn[i]if e then
kick(t,i)return e,n.resume(e)else
return nil,true
end
end
function abort(i,t)local e=i.cortn[t]if e then
kick(i,t)n.resume(e,"timeout")end
end
function i.__index:step()local e,n=r.select(self.receiving.set,self.sending.set,.1)for n,e in t.ipairs(e)do
schedule(wakeup(self.receiving,e))end
for n,e in t.ipairs(n)do
schedule(wakeup(self.sending,e))end
local i=r.gettime()for e,n in t.pairs(self.stamp)do
if e.class=="tcp{client}"and i-n>TIMEOUT then
abort(self.sending,e)abort(self.receiving,e)end
end
end
function i.__index:start(e)local e=n.create(e)schedule(e,n.resume(e))end
function l.coroutine()local e={}local e={stamp=e,sending={name="sending",set=a(),cortn={},stamp=e},receiving={name="receiving",set=a(),cortn={},stamp=e},}function e.tcp()return s(e,r.tcp())end
return t.setmetatable(e,i)end
end)package.preload['revmob_messages']=(function(...)REVMOB_MSG_NO_ADS="No ads for this device/country right now, or your App ID is paused."REVMOB_MSG_APP_IDLING="No ads because your App ID or Placement ID is idling."REVMOB_MSG_NO_SESSION="The method RevMob.startSession(REVMOB_IDS) has not been called."REVMOB_MSG_UNKNOWN_REASON="Ad was not received for an unknown reason: "REVMOB_MSG_UNKNOWN_REASON_CORONA="Ad was not received for an unknown reason. Is your internet connection working properly? Please, try again later. If this error persist, please contact us for more details."REVMOB_MSG_INVALID_DEVICE_ID="Device requirements not met."REVMOB_MSG_INVALID_APPID="App not recognized due to invalid App ID."REVMOB_MSG_INVALID_PLACEMENTID="No ads because you type an invalid Placement ID."REVMOB_MSG_OPEN_MARKET="Opening market"REVMOB_EVENT_AD_RECEIVED="adReceived"REVMOB_EVENT_AD_NOT_RECEIVED="adNotReceived"REVMOB_EVENT_AD_DISPLAYED="adDisplayed"REVMOB_EVENT_AD_CLICKED="adClicked"REVMOB_EVENT_AD_CLOSED="adClosed"REVMOB_EVENT_INSTALL_RECEIVED="installReceived"REVMOB_EVENT_INSTALL_NOT_RECEIVED="installNotReceived"end)package.preload['revmob_about']=(function(...)REVMOB_SDK={VERSION="3.5.0",DEBUG=false}local e=function()if"Android"==system.getInfo("platformName")then
return"corona-android"elseif"iPhone OS"==system.getInfo("platformName")then
return"corona-ios"else
return"corona"end
end
REVMOB_SDK.NAME=e()end)package.preload['revmob_client']=(function(...)local o=require('json')require('revmob_about')require('revmob_messages')require('revmob_utils')require('asyncHttp')require('session_manager')local n='https://api.bcfads.com'local e='9774d5f368157442'local t='4c6dbc5d000387f3679a53d76f6944211a7f2224'local i=e
local r=10
RevMobConnection={wifi=nil,wwan=nil,hasInternetConnection=function()return(not network.canDetectNetworkStatusChanges)or(RevMobConnection.wifi or RevMobConnection.wwan)end}function RevMobNetworkReachabilityListener(e)if e.isReachable then
log("Internet connection available.")else
log("Could not connect to RevMob site. No ads will be available.")end
RevMobConnection.wwan=e.isReachableViaCellular
RevMobConnection.wifi=e.isReachableViaWiFi
log("IsReachableViaCellular: "..tostring(e.isReachableViaCellular))log("IsReachableViaWiFi: "..tostring(e.isReachableViaWiFi))end
if network.canDetectNetworkStatusChanges then
network.setStatusListener("revmob.com",RevMobNetworkReachabilityListener)log("Listening network reachability.")end
RevMobDevice={identities=nil,country=nil,manufacturer=nil,model=nil,os_version=nil,connection_speed=nil,new=function(n,e)e=e or{}setmetatable(e,n)n.__index=n
e.identities=e:buildDeviceIdentifierAsTable()e.country=system.getPreference("locale","country")e.locale=system.getPreference("locale","language")e.manufacturer=e:getManufacturer()e.model=e:getModel()e.os_version=system.getInfo("platformVersion")if RevMobConnection.wifi then
e.connection_speed="wifi"elseif RevMobConnection.wwan then
e.connection_speed="wwan"else
e.connection_speed="other"end
return e
end,isSimulator=function(e)return"simulator"==system.getInfo("environment")or system.getInfo("name")==""or e:isIosSimulator()end,isIosSimulator=function(e)return system.getInfo("name")=="iPhone Simulator"or system.getInfo("name")=="iPad Simulator"end,isIPad=function(e)return"iPad"==system.getInfo("model")end,getDeviceId=function(e)if e:isIosSimulator()then
return t or system.getInfo("deviceID")elseif e:isSimulator()then
return i or system.getInfo("deviceID")end
return system.getInfo("deviceID")end,buildDeviceIdentifierAsTable=function(e)local e=e:getDeviceId()e=string.gsub(e,"-","")e=string.lower(e)if(string.len(e)==40)then
return{udid=e}elseif(string.len(e)==14 or string.len(e)==15 or string.len(e)==17 or string.len(e)==18)then
return{mobile_id=e}elseif(string.len(e)==16)then
return{android_id=e}else
log("WARNING: device not identified, no registration or ad unit will work")return nil
end
end,getManufacturer=function(e)local e=system.getInfo("platformName")if(e=="iPhone OS")then
return"Apple"end
return e
end,getModel=function(e)local e=e:getManufacturer()if(e=="Apple")then
return system.getInfo("architectureInfo")end
return system.getInfo("model")end}RevMobClient={payload={},adunit=nil,applicationId=nil,device=nil,placementID=nil,new=function(e,n,t)local n={adunit=n,device=RevMobDevice:new(),applicationId=RevMobSessionManager.appID,placementID=t}setmetatable(n,e)e.__index=e
return n
end,url=function(e)if e.placementID==nil then
return n.."/api/v4/mobile_apps/"..e.applicationId.."/"..e.adunit.."/fetch.json"else
return n.."/api/v4/mobile_apps/"..e.applicationId.."/placements/"..e.placementID.."/"..e.adunit.."/fetch.json"end
end,urlInstall=function(e)return n.."/api/v4/mobile_apps/"..e.applicationId.."/install.json"end,urlSession=function(e)return n.."/api/v4/mobile_apps/"..e.applicationId.."/sessions.json"end,payloadAsJsonString=function(e)if RevMobSessionManager.testMode~=nil then
log("TESTING MODE ACTIVE: "..tostring(RevMobSessionManager.testMode))local n={response=RevMobSessionManager.testMode}return o.encode({device=e.device,sdk={name=REVMOB_SDK["NAME"],version=REVMOB_SDK["VERSION"]},testing=n})end
return o.encode({device=e.device,sdk={name=REVMOB_SDK["NAME"],version=REVMOB_SDK["VERSION"]}})end,post=function(i,t,n)if t==nil then return end
logD("Request url:  "..i)logD("Request body: "..t)if not n then n=function(e)logTableD(e)end
end
local e={}e.body=t
if RevMobUtils.isAndroid()then
e.headers={["Content-Length"]=tostring(#t),["Content-Type"]="application/json"}asyncHttp.request(i,"POST",n,e)else
e.headers={["Content-Type"]="application/json"}e.timeout=r
network.request(i,"POST",n,e)end
end,postWithoutFollowRedirect=function(i,e,n)if e==nil then return end
logD("Request url:  "..i)logD("Request body: "..e)if not n then n=function(e)logTableD(e)end
end
local t={}t.body=e
t.headers={["Content-Length"]=tostring(#e),["Content-Type"]="application/json"}asyncHttp.request(i,"POST",n,t)end,fetch=function(e,n)if RevMobSessionManager.isSessionStarted()then
if e.placementID~=nil then
log("Ad registered with Placement ID "..e.placementID)end
RevMobClient.post(e:url(),e:payloadAsJsonString(),n)else
local e={statusCode=0,response={error="Session not started"},headers={}}if n then
n(e)end
end
end,install=function(e,n)RevMobClient.post(e:urlInstall(),e:payloadAsJsonString(),n)end,startSession=function(e)RevMobClient.post(e:urlSession(),e:payloadAsJsonString(),listener)end,theFetchSucceed=function(r,t,i)logTableD(t)local e=t.status or t.statusCode
if(e~=200 and e~=302 and e~=303)then
local n=nil
if e==204 then
n=REVMOB_MSG_NO_ADS
elseif e==404 then
n=REVMOB_MSG_INVALID_APPID
elseif e==409 then
n=REVMOB_MSG_INVALID_PLACEMENTID
elseif e==422 then
n=REVMOB_MSG_INVALID_DEVICE_ID
elseif e==423 then
n=REVMOB_MSG_APP_IDLING
elseif e==500 then
n=REVMOB_MSG_UNKNOWN_REASON.."Please, contact us for more details."end
if n==nil then
log(REVMOB_MSG_UNKNOWN_REASON_CORONA)else
log("Reason: "..tostring(n).." ("..tostring(e)..")")end
if i~=nil then i({type=REVMOB_EVENT_AD_NOT_RECEIVED,ad=r,reason=n})end
return false,nil
end
if e==302 or e==303 then
return true,nil
end
local n,e=pcall(o.decode,t.response)if(not n or e==nil)then
log("Reason: "..REVMOB_MSG_UNKNOWN_REASON..tostring(n).." / "..tostring(e))if i~=nil then i({type=REVMOB_EVENT_AD_NOT_RECEIVED,ad=r,reason=reason})end
return false,e
end
return n,e
end,getMarketURL=function(i,e)local t=require('socket.http')local n=require("ltn12")local o={}if e==nil then
e=""end
local n,e,o=t.request{method="POST",url=i,source=n.source.string(e),headers={["Content-Length"]=tostring(#e),["Content-Type"]="application/json"},sink=n.sink.table(o),}if(e==302 or e==303)then
local n="details%?id=[a-zA-Z0-9%.]+"local t="android%?p=[a-zA-Z0-9%.]+"local e=o['location']if(string.sub(e,1,string.len("market://"))=="market://")then
return e
elseif(string.match(e,n,1))then
local e=string.match(e,n,1)return"market://"..e
elseif(string.sub(e,1,string.len("amzn://"))=="amzn://")then
return e
elseif(string.match(e,t,1))then
local e=string.match(e,t,1)return"amzn://apps/"..e
else
return RevMobClient.getMarketURL(e)end
end
return i
end}end)package.preload['revmob_utils']=(function(...)require('revmob_about')function log(e)print("[RevMob] "..tostring(e))io.output():flush()end
function logD(e)if REVMOB_SDK.DEBUG then
print("[RevMob Debug] "..tostring(e))io.output():flush()end
end
function logTable(e)for n,e in pairs(e)do log(tostring(n)..': '..tostring(e))end
end
function logTableD(e)if REVMOB_SDK.DEBUG then
for e,n in pairs(e)do logD(tostring(e)..': '..tostring(n))end
end
end
RevMobUtils={isAndroid=function()return"Android"==system.getInfo("platformName")end,isIOS=function()return"iPhone OS"==system.getInfo("platformName")end,getLink=function(n,e)for t,e in ipairs(e)do
if e.rel==n then
return e.href
end
end
return nil
end,loadAsset=function(t,e,n)timer.performWithDelay(1,function()display.loadRemoteImage(t,"GET",e,n,system.TemporaryDirectory)end)end}RevMobScreen={left=function()return display.screenOriginX end,top=function()return display.screenOriginY end,right=function()return display.contentWidth-display.screenOriginX end,bottom=function()return display.contentHeight-display.screenOriginY end,width=function()return RevMobScreen.right()-RevMobScreen.left()end,height=function()return RevMobScreen.bottom()-RevMobScreen.top()end,}end)package.preload['fullscreen_web']=(function(...)require('revmob_messages')require('revmob_client')require('revmob_utils')local n="fullscreen"FullscreenWeb={autoshow=true,listener=nil,clickUrl=nil,htmlUrl=nil,new=function(e)local e=e or{}setmetatable(e,FullscreenWeb)return e
end,load=function(e,i)e.networkListener=function(t)local i,t=RevMobClient.theFetchSucceed(n,t,e.listener)if i then
local t=t['fullscreen']['links']e.clickUrl=RevMobUtils.getLink('clicks',t)e.htmlUrl=RevMobUtils.getLink('html',t)if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_RECEIVED,ad=n})end
if e.autoshow then
e:show()end
end
end
local n=RevMobClient:new("fullscreens",i)n:fetch(e.networkListener)end,isLoaded=function(e)return e.htmlUrl~=nil and e.clickUrl~=nil
end,hide=function(e)if not e:isLoaded()then e.autoshow=false end
end,show=function(e)if not e:isLoaded()then
log("Ad is not loaded yet to be shown")return
end
e.clickListener=function(t)if string.sub(t.url,-string.len("#close"))=="#close"then
if e.changeOrientationListener then
Runtime:removeEventListener("orientation",e.changeOrientationListener)end
if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_CLOSED,ad=n})end
return false
end
if string.sub(t.url,-string.len("#click"))=="#click"then
if e.changeOrientationListener then
Runtime:removeEventListener("orientation",e.changeOrientationListener)end
if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_CLICKED,ad=n})end
local e=RevMobClient.getMarketURL(e.clickUrl)log(REVMOB_MSG_OPEN_MARKET)if e then system.openURL(e)end
return false
end
if t.errorCode then
log("Error: "..tostring(t.errorMessage))end
return true
end
local t={hasBackground=false,autoCancel=true,urlRequest=e.clickListener}e.changeOrientationListener=function(n)native.cancelWebPopup()timer.performWithDelay(200,function()native.showWebPopup(e.htmlUrl,t)end)end
timer.performWithDelay(1,function()if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_DISPLAYED,ad=n})end
native.showWebPopup(e.htmlUrl,t)end)Runtime:addEventListener("orientation",e.changeOrientationListener)end,close=function(e)if e.changeOrientationListener then
Runtime:removeEventListener("orientation",e.changeOrientationListener)end
native.cancelWebPopup()end,}FullscreenWeb.__index=FullscreenWeb
end)package.preload['fullscreen_static']=(function(...)require('revmob_messages')require('revmob_client')require('revmob_utils')local n="fullscreen"FullscreenStatic={autoshow=true,listener=nil,clickUrl=nil,imageUrl=nil,closeButtonUrl=nil,component=nil,_clicked=false,_released=false,_updateAccordingToOrientation=nil,_loadCloseButtonListener=nil,_loadImageListener=nil,_networkListener=nil,_moveToFront=nil,new=function(e)local e=e or{}setmetatable(e,FullscreenStatic)e.component=display.newGroup()e.component.alpha=0
return e
end,load=function(e,i)e._networkListener=function(t)local t,n=RevMobClient.theFetchSucceed(n,t,e.listener)if t then
local n=n['fullscreen']['links']e.clickUrl=RevMobUtils.getLink('clicks',n)e.imageUrl=RevMobUtils.getLink('image',n)e.closeButtonUrl=RevMobUtils.getLink('close_button',n)e:loadImage()e:loadCloseButton()end
end
local n=RevMobClient:new("fullscreens",i)n:fetch(e._networkListener)end,loadImage=function(e)if e._released==true then log("Fullscreen was closed.")return end
e._loadImageListener=function(t)if e._released==true then if t.target then t.target:removeSelf()end log("Fullscreen was closed.")return end
if t.isError or t.target==nil or e.imageUrl==nil then
log("Fail to load ad image: "..tostring(e.imageUrl))if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_NOT_RECEIVED,ad=n})end
return
end
e.image=t.target
e:_configureDimensions()e.image.tap=function(t)if not e._clicked then
e._clicked=true
if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_CLICKED,ad=n})end
local n=RevMobClient.getMarketURL(e.clickUrl)log(REVMOB_MSG_OPEN_MARKET)if n then system.openURL(n)end
e:close()end
return true
end
e.image.touch=function(n)return true end
e.image:addEventListener("tap",e.image)e.image:addEventListener("touch",e.image)e.component:insert(1,e.image)e:_updateResourcesLoaded()end
RevMobUtils.loadAsset(e.imageUrl,e._loadImageListener,"fullscreen.jpg")end,loadCloseButton=function(e)if e._released==true then return end
e._loadCloseButtonListener=function(t)if e._released==true then if t.target then t.target:removeSelf()end return end
if t.isError or t.target==nil or e.closeButtonUrl==nil then
log("Fail to load close button image: "..tostring(e.closeButtonUrl))if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_NOT_RECEIVED,ad=n})end
return
end
e.closeButtonImage=t.target
e:_configureDimensions()e.closeButtonImage.tap=function(t)if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_CLOSED,ad=n})end
e:close()return true
end
e.closeButtonImage.touch=function(n)return true end
e.closeButtonImage:addEventListener("tap",e.closeButtonImage)e.closeButtonImage:addEventListener("touch",e.closeButtonImage)e.component:insert(2,e.closeButtonImage)e:_updateResourcesLoaded()end
RevMobUtils.loadAsset(e.closeButtonUrl,e._loadCloseButtonListener,"close_button.jpg")end,_updateResourcesLoaded=function(e)if e:isLoaded()then
if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_RECEIVED,ad=n})end
if e.autoshow then
e:show()end
end
end,_configureDimensions=function(e)if(e.image~=nil)then
e.image.x=display.contentWidth/2
e.image.y=display.contentHeight/2
e.image.width=RevMobScreen.width()e.image.height=RevMobScreen.height()end
if(e.closeButtonImage~=nil)then
e.closeButtonImage.x=display.contentWidth-45
e.closeButtonImage.y=40
e.closeButtonImage.width=RevMobDevice:isIPad()and 35 or 40
e.closeButtonImage.height=RevMobDevice:isIPad()and 35 or 40
end
end,isLoaded=function(e)return e.clickUrl~=nil and e.component~=nil and e.component.numChildren>=2
end,hide=function(e)if not e:isLoaded()then e.autoshow=false end
if e.component~=nil then e.component.alpha=0 end
end,show=function(e)if not e:isLoaded()then
log("Ad is not loaded yet to be shown")e.autoshow=true
return
end
if e.component~=nil then
e.component.alpha=1
e._moveToFront=function(n)if e.component~=nil then e.component:toFront()end end
Runtime:addEventListener("enterFrame",e._moveToFront)e._updateAccordingToOrientation=function(n)e:_configureDimensions()end
Runtime:addEventListener("orientation",e._updateAccordingToOrientation)if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_DISPLAYED,ad=n})end
end
end,close=function(e)e._released=true
e.autoshow=false
if e._moveToFront~=nil then Runtime:removeEventListener("enterFrame",e._moveToFront)end
if e._updateAccordingToOrientation~=nil then Runtime:removeEventListener("orientation",e._updateAccordingToOrientation)end
e._updateAccordingToOrientation=nil
e._loadCloseButtonListener=nil
e._loadImageListener=nil
e._networkListener=nil
e._moveToFront=nil
e.listener=nil
if e.image~=nil then
pcall(e.image.removeEventListener,e.image,"tap",e.image)pcall(e.image.removeEventListener,e.image,"touch",e.image)e.image:removeSelf()e.image=nil
end
if e.closeButtonImage~=nil then
pcall(e.closeButtonImage.removeEventListener,e.closeButtonImage,"tap",e.closeButtonImage)pcall(e.closeButtonImage.removeEventListener,e.closeButtonImage,"touch",e.closeButtonImage)e.closeButtonImage:removeSelf()e.closeButtonImage=nil
end
if e.component~=nil then e.component:removeSelf()e.component=nil end
e._clicked=false
log("Fullscreen closed")end,}FullscreenStatic.__index=FullscreenStatic
end)package.preload['fullscreen']=(function(...)require('revmob_messages')require('revmob_client')require('revmob_utils')require('fullscreen_static')require('fullscreen_web')local t="fullscreen"Fullscreen={params=nil,view=nil,listener=nil,placementID=nil,autoshow=true,new=function(n)local e=n or{}setmetatable(e,Fullscreen)e.params=n
return e
end,load=function(e)local n=function(n)local t,n=RevMobClient.theFetchSucceed(t,n,e.listener)if t then
local n=n['fullscreen']['links']local t=RevMobUtils.getLink('clicks',n)local i=RevMobUtils.getLink('html',n)local o=RevMobUtils.getLink('image',n)local n=RevMobUtils.getLink('close_button',n)if i then
log("Rich fullscreen")e.view=FullscreenWeb.new(e.params)e.view.htmlUrl=i
e.view.clickUrl=t
e.view.autoshow=e.autoshow
if e.autoshow==true then
e.view:show()end
else
log("Static fullscreen")e.view=FullscreenStatic.new(e.params)e.view.imageUrl=o
e.view.closeButtonUrl=n
e.view.clickUrl=t
e.view.autoshow=e.autoshow
e.view:loadImage()e.view:loadCloseButton()end
end
end
local e=RevMobClient:new("fullscreens",e.placementID)e:fetch(n)end,hide=function(e)e.autoshow=false
if e.view~=nil then e.view:hide()end
end,show=function(e)e.autoshow=true
if e.view~=nil then e.view:show()end
end,close=function(e)e.autoshow=false
if e.view~=nil then e.view:close()end
end}Fullscreen.__index=Fullscreen
end)package.preload['banner_web']=(function(...)require('revmob_messages')require('revmob_client')require('revmob_utils')local n="banner"BannerWeb={autoshow=true,listener=nil,clickUrl=nil,htmlUrl=nil,webView=nil,x=0,y=0,width=320,height=50,rotation=0,new=function(e)local e=e or{}setmetatable(e,BannerWeb)return e
end,load=function(e,i)e.networkListener=function(t)local t,i=RevMobClient.theFetchSucceed(n,t,e.listener)if t then
local t=i['banners'][1]['links']e.clickUrl=RevMobUtils.getLink('clicks',t)e.htmlUrl=RevMobUtils.getLink('html',t)if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_RECEIVED,ad=n})end
e:configWebView()if e.autoshow then
e:show()end
end
end
local n=RevMobClient:new("banners",i)n:fetch(e.networkListener)end,configWebView=function(e)e.clickListener=function(t)if string.sub(t.url,-string.len("#click"))=="#click"then
if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_CLICKED,ad=n})end
local n=RevMobClient.getMarketURL(e.clickUrl)log(REVMOB_MSG_OPEN_MARKET)if n then system.openURL(n)end
e:hide()end
if t.errorCode then
log("Error: "..tostring(t.errorMessage))end
return true
end
e.webView=native.newWebView(e.x,e.y,e.width,e.height)e.webView:addEventListener('urlRequest',e.clickListener)e:hide()e.webView.rotation=e.rotation
e.webView.canGoBack=false
e.webView.canGoForward=false
e.webView.hasBackground=true
e.webView:request(e.htmlUrl)e.clickListener2=function(n)return true end
e.webView.tap=e.clickListener2
e.webView.touch=e.clickListener2
e.webView:addEventListener("tap",e.webView)e.webView:addEventListener("touch",e.webView)end,isLoaded=function(e)return e.htmlUrl~=nil and e.clickUrl~=nil
end,show=function(e)if not e:isLoaded()then
log("Ad is not loaded yet to be shown")return
end
if e.webView~=nil then
timer.performWithDelay(1,function()if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_DISPLAYED,ad=n})end
e.webView.alpha=1
end)end
end,setPosition=function(e,t,n)if e.webView then
e.webView.x=t or e.webView.x
e.webView.y=n or e.webView.y
e.x=e.webView.x
e.y=e.webView.y
end
end,setDimension=function(e,n,t,i)if e.webView then
e.webView.width=n or e.webView.width
e.webView.height=t or e.webView.height
e.webView.rotation=i or e.webView.rotation
e.width=e.webView.width
e.height=e.webView.height
e.rotation=e.webView.rotation
end
end,update=function(e,o,n,i,t,r)e:setPosition(o,n)e:setDimension(i,t,r)end,release=function(e)if e.webView then
e.webView:removeEventListener("tap",e.webView)e.webView:removeEventListener("touch",e.webView)e.webView:removeSelf()e.webView=nil
end
end,hide=function(e)if e.webView~=nil then e.webView.alpha=0 end
end,}BannerWeb.__index=BannerWeb
end)package.preload['banner_static']=(function(...)require('revmob_messages')require('revmob_client')require('revmob_utils')local n="banner"BannerStatic={autoshow=true,listener=nil,clickUrl=nil,imageUrl=nil,component=nil,_clicked=false,_released=false,width=nil,height=nil,x=nil,y=nil,rotation=0,new=function(e)local e=e or{}setmetatable(e,BannerStatic)e.component=display.newGroup()e.component.alpha=0
return e
end,load=function(e,t)e.networkListener=function(t)local t,n=RevMobClient.theFetchSucceed(n,t,e.listener)if t then
local n=n['banners'][1]['links']e.clickUrl=RevMobUtils.getLink('clicks',n)e.imageUrl=RevMobUtils.getLink('image',n)e:loadImage()end
end
local n=RevMobClient:new("banners",t)n:fetch(e.networkListener)end,loadImage=function(e)if e._released==true then log("Banner was released.")return end
e._loadImageListener=function(t)if e._released==true then if t.target then t.target:removeSelf()end log("Banner was released.")return end
if t.isError or t.target==nil or e.imageUrl==nil then
log("Fail to load ad image: "..tostring(e.imageUrl))if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_NOT_RECEIVED,ad=n})end
return
end
e.image=t.target
local i=(RevMobScreen.width()>640)and 640 or RevMobScreen.width()local t=(RevMobDevice:isIPad()and 100 or 50*(RevMobScreen.bottom()-RevMobScreen.top())/display.contentHeight)local r=(RevMobScreen.left()+i/2)local o=(RevMobScreen.bottom()-t/2)e:setPosition(e.x or r,e.y or o)e:setDimension(e.width or i,e.height or t)e.image.tap=function(t)if not e._clicked then
e._clicked=true
if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_CLICKED,ad=n})end
local n=RevMobClient.getMarketURL(e.clickUrl)log(REVMOB_MSG_OPEN_MARKET)if n then system.openURL(n)end
e:release()end
return true
end
e.image.touch=function(n)return true end
e.image:addEventListener("tap",e.image)e.image:addEventListener("touch",e.image)e.component:insert(1,e.image)if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_RECEIVED,ad=n})end
if e.autoshow then
e:show()end
end
RevMobUtils.loadAsset(e.imageUrl,e._loadImageListener,"revmob_banner.jpg")end,isLoaded=function(e)return e.image~=nil and e.clickUrl~=nil and e.component~=nil
end,hide=function(e)if not e:isLoaded()then e.autoshow=false end
if e.component~=nil then e.component.alpha=0 end
end,show=function(e)if not e:isLoaded()then
log("Ad is not loaded yet to be shown")e.autoshow=true
return
end
if e.component~=nil then
e.component.alpha=1
if e.listener~=nil then e.listener({type=REVMOB_EVENT_AD_DISPLAYED,ad=n})end
end
end,setPosition=function(e,t,n)if e.image~=nil then
e.image.x=t or e.image.x
e.image.y=n or e.image.y
e.x=e.image.x
e.y=e.image.y
end
end,setDimension=function(e,n,t,i)if e.image~=nil then
e.image.width=n or e.image.width
e.image.height=t or e.image.height
e.image.rotation=i or e.image.rotation
e.width=e.image.width
e.height=e.image.height
e.rotation=e.image.rotation
end
end,release=function(e)e._released=true
e.autoshow=false
e.networkListener=nil
e._loadImageListener=nil
e.listener=nil
if e.image~=nil then
pcall(e.image.removeEventListener,e.image,"tap",e.image)pcall(e.image.removeEventListener,e.image,"touch",e.image)e.image:removeSelf()e.image=nil
end
if e.component~=nil then e.component:removeSelf()e.component=nil end
e._clicked=false
end,}BannerStatic.__index=BannerStatic
end)package.preload['banner']=(function(...)require('revmob_messages')require('revmob_client')require('revmob_utils')require('banner_static')require('banner_web')local t="banner"Banner={params=nil,view=nil,placementID=nil,listener=nil,autoshow=true,width=nil,height=nil,x=nil,y=nil,rotation=0,new=function(n)local e=n or{}setmetatable(e,Banner)e.params=n
return e
end,load=function(e)local n=function(n)local n,t=RevMobClient.theFetchSucceed(t,n,e.listener)if n then
local n=t['banners'][1]['links']local t=RevMobUtils.getLink('clicks',n)local i=RevMobUtils.getLink('image',n)local n=RevMobUtils.getLink('html',n)if n then
log("Rich banner")e.view=BannerWeb.new(e.params)e.view.htmlUrl=n
e.view.clickUrl=t
e.view.autoshow=e.autoshow
e:configWebView()if e.autoshow==true then
e.view:show()end
else
log("Static banner")e.view=BannerStatic.new(e.params)e.view.imageUrl=i
e.view.clickUrl=t
e.view.autoshow=e.autoshow
e.view:loadImage()end
end
end
local e=RevMobClient:new("banners",e.placementID)e:fetch(n)end,hide=function(e)e.autoshow=false
if e.view~=nil then e.view:hide()end
end,show=function(e)e.autoshow=true
if e.view~=nil then e.view:show()end
end,setPosition=function(e,n,t)if e.view~=nil then e.view:setPosition(n,t)end
e.x=n or e.view.x
e.y=t or e.view.y
end,setDimension=function(e,t,n,i)if e.view~=nil then e.view:setDimension(t,n,i)end
e.width=t or e.view.width
e.height=n or e.view.height
e.rotation=i or e.view.rotation
end,release=function(e)e.autoshow=false
if e.view~=nil then e.view:release()end
end}Banner.__index=Banner
end)package.preload['adlink']=(function(...)require('revmob_messages')require('revmob_client')require('revmob_utils')require('session_manager')local t="link"AdLink={open=function(e,i)if RevMobSessionManager.isSessionStarted()then
local n=function(n)local i,o=RevMobClient.theFetchSucceed(t,n,e)if i then
if(n.statusCode==302 or n.statusCode==303)then
local n=RevMobClient.getMarketURL(n.headers['location'])or n.headers['location']if n then
if e then e({type=REVMOB_EVENT_AD_RECEIVED,ad=t})end
log(REVMOB_MSG_OPEN_MARKET)system.openURL(n)else
local n=REVMOB_MSG_UNKNOWN_REASON.."No market url"log(n)if e then e({type=REVMOB_EVENT_AD_NOT_RECEIVED,ad=t,reason=n})end
end
end
end
end
local e=RevMobClient:new("links",i)e.postWithoutFollowRedirect(e:url(),e:payloadAsJsonString(),n)else
log(REVMOB_MSG_NO_SESSION)if e then e({type=REVMOB_EVENT_AD_NOT_RECEIVED,ad=t,reason=REVMOB_MSG_NO_SESSION})end
end
end,}end)package.preload['popup']=(function(...)require('revmob_messages')require('revmob_client')local n="popup"RevMobPopup={DELAYED_LOAD_IMAGE=10,YES_BUTTON_POSITION=2,message=nil,click_url=nil,adListener=nil,notifyAdListener=function(e)if RevMobPopup.adListener then
RevMobPopup.adListener(e)end
end,show=function(e,n)RevMobPopup.adListener=e
client=RevMobClient:new("pop_ups",n)client:fetch(RevMobPopup.networkListener)end,networkListener=function(e)local t,e=RevMobClient.theFetchSucceed(n,e,RevMobPopup.adListener)if t then
if RevMobPopup.isParseOk(e)then
RevMobPopup.message=e["pop_up"]["message"]RevMobPopup.click_url=e["pop_up"]["links"][1]["href"]timer.performWithDelay(RevMobPopup.DELAYED_LOAD_IMAGE,function()RevMobPopup.notifyAdListener({type=REVMOB_EVENT_AD_DISPLAYED,ad=n})local e=native.showAlert(RevMobPopup.message,"",{"No, thanks.","Yes, Sure!"},RevMobPopup.click)end)RevMobPopup.notifyAdListener({type=REVMOB_EVENT_AD_RECEIVED,ad=n})else
log(REVMOB_MSG_UNKNOWN_REASON)RevMobPopup.notifyAdListener({type=REVMOB_EVENT_AD_NOT_RECEIVED,ad=n,reason=REVMOB_MSG_UNKNOWN_REASON})end
end
end,isParseOk=function(e)if(e==nil)then
return false
elseif(e["pop_up"]==nil)then
return false
elseif(e["pop_up"]["message"]==nil)then
return false
elseif(e["pop_up"]["links"]==nil)then
return false
elseif(e["pop_up"]["links"][1]==nil)then
return false
elseif(e["pop_up"]["links"][1]["href"]==nil)then
return false
end
return true
end,click=function(e)if"clicked"==e.action then
if RevMobPopup.YES_BUTTON_POSITION==e.index then
RevMobPopup.notifyAdListener({type=REVMOB_EVENT_AD_CLICKED,ad=n})local e=RevMobClient.getMarketURL(RevMobPopup.click_url)log(REVMOB_MSG_OPEN_MARKET)if e then system.openURL(e)end
else
RevMobPopup.notifyAdListener({type=REVMOB_EVENT_AD_CLOSED,ad=n})end
end
end}end)package.preload['advertiser']=(function(...)local e=require('json')require('revmob_messages')require('revmob_client')require('revmob_utils')require('loadsave')Advertiser={registerInstall=function(t,e)local n=function(n)logTableD(n)if(n.statusCode==200)then
RevMobPrefs.addItem(t,true)RevMobPrefs.saveToFile()log("Install received.")if e~=nil then
e.notifyAdListener({type=REVMOB_EVENT_INSTALL_RECEIVED})end
else
log("Install not received: "..tostring(n.statusCode))if e~=nil then
e.notifyAdListener({type=REVMOB_EVENT_INSTALL_NOT_RECEIVED})end
end
end
local e=RevMobPrefs.loadFromFile()if not e then
RevMobPrefs.saveToFile()RevMobPrefs.loadFromFile()end
local e=RevMobPrefs.getItem(t)if e==true then
log("Install already registered in this device")else
local e=RevMobClient:new("")e:install(n)end
end}end)package.preload['loadsave']=(function(...)local t=require('json')RevMobPrefs={FILENAME="revmob_sdk.json",preferences={},getItem=function(e)return RevMobPrefs.preferences[e]or nil
end,addItem=function(e,n)RevMobPrefs.preferences[e]=n
end,saveToFile=function()local e=RevMobPrefs.getFileAbsolutePath()local e=io.open(e,"w")local n=t.encode(RevMobPrefs.preferences)e:write(n)io.close(e)end,getFileAbsolutePath=function()local e=system.pathForFile(RevMobPrefs.FILENAME,system.CachesDirectory)if not e then
e=system.pathForFile(RevMobPrefs.FILENAME,system.TemporaryDirectory)end
return e
end,loadFromFile=function()local n=RevMobPrefs.getFileAbsolutePath()local e=nil
if n then
e=io.open(n,"r")end
if e then
local n=e:read("*a")RevMobPrefs.preferences=t.decode(n)if RevMobPrefs.preferences==nil then
RevMobPrefs.preferences={}end
io.close(e)return true
end
return false
end}end)package.preload['session_manager']=(function(...)require("revmob_utils")RevMobSessionManager={TEST_WITH_ADS="with_ads",TEST_WITHOUT_ADS="without_ads",TEST_DISABLED=nil,listenersRegistered=false,appID=nil,sessionStarted=false,testMode=nil,isAppIdValid=function(e)return e and string.len(e)==24
end,startSession=function(e,n)if n~=nil then
RevMobSessionManager.setTestingMode(n)end
if RevMobSessionManager.isAppIdValid(e)then
if not RevMobSessionManager.sessionStarted then
RevMobSessionManager.appID=e
RevMobSessionManager.sessionStarted=true
local e=RevMobClient:new("")e:startSession()log("Session started for App ID: "..RevMobSessionManager.appID)else
log("Session has already been started for App ID: "..e)end
else
log("Invalid App ID: "..tostring(e))end
end,setTestingMode=function(e)if e==RevMobSessionManager.TEST_DISABLED or
e==RevMobSessionManager.TEST_WITH_ADS or
e==RevMobSessionManager.TEST_WITHOUT_ADS then
RevMobSessionManager.testMode=e
else
RevMobSessionManager.testMode=RevMobSessionManager.TEST_DISABLED
end
end,sessionManagement=function(e)if e.type=="applicationSuspend"then
RevMobSessionManager.sessionStarted=false
elseif e.type=="applicationResume"then
RevMobSessionManager.startSession(RevMobSessionManager.appID)end
end,isSessionStarted=function()return RevMobSessionManager.sessionStarted
end,}if RevMobSessionManager.listenersRegistered==false then
RevMobSessionManager.listenersRegistered=true
Runtime:removeEventListener("system",RevMobSessionManager.sessionManagement)Runtime:addEventListener("system",RevMobSessionManager.sessionManagement)end end)require('revmob_about')require('revmob_utils')require('revmob_client')require('revmob_messages')require('fullscreen_static')require('fullscreen_web')require('fullscreen')require('banner_static')require('banner_web')require('banner')require('adlink')require('popup')require('advertiser')require('session_manager')local e=5e3
RevMob={TEST_DISABLED=RevMobSessionManager.TEST_DISABLED,TEST_WITH_ADS=RevMobSessionManager.TEST_WITH_ADS,TEST_WITHOUT_ADS=RevMobSessionManager.TEST_WITHOUT_ADS,getRevMobIDAccordingToPlatform=function(n)if n==nil then return nil end
local e=n[system.getInfo("platformName")]if e==nil then
e=n["iPhone OS"]if RevMobSessionManager.isAppIdValid(e)then
log("Using iPhone App ID for simulator: "..tostring(e))else
e=n["Android"]log("Using Android App ID for simulator: "..tostring(e))end
end
return e
end,startSession=function(e,n)local e=RevMob.getRevMobIDAccordingToPlatform(e)RevMobSessionManager.startSession(e,n)Advertiser.registerInstall(e)end,setTestingMode=function(e)RevMobSessionManager.setTestingMode(e)end,showFullscreen=function(n,e)if not RevMobSessionManager.isSessionStarted()then return log(REVMOB_MSG_NO_SESSION)end
local e=RevMob.getRevMobIDAccordingToPlatform(e)local e=Fullscreen.new({listener=n,placementID=e})e:load()return e
end,openAdLink=function(e,n)if not RevMobSessionManager.isSessionStarted()then return log(REVMOB_MSG_NO_SESSION)end
local n=RevMob.getRevMobIDAccordingToPlatform(n)AdLink.open(e,n)end,createBanner=function(e,n)if not RevMobSessionManager.isSessionStarted()then return log(REVMOB_MSG_NO_SESSION)end
if e==nil then e={}end
local n=RevMob.getRevMobIDAccordingToPlatform(n)e["placementID"]=n
local e=Banner.new(e)e:load()return e
end,showPopup=function(n,e)if not RevMobSessionManager.isSessionStarted()then return log(REVMOB_MSG_NO_SESSION)end
local e=RevMob.getRevMobIDAccordingToPlatform(e)RevMobPopup.show(n,e)end,printEnvironmentInformation=function(e)log("==============================================")log("RevMob Corona SDK: "..REVMOB_SDK["NAME"].." - "..REVMOB_SDK["VERSION"])log("App ID in session: "..tostring(RevMobSessionManager.appID))if e then
log("User App ID for Android: "..tostring(e["Android"]))log("User App ID for iOS: "..tostring(e["iPhone OS"]))end
log("Device name: "..system.getInfo("name"))log("Model name: "..system.getInfo("model"))log("Device ID: "..system.getInfo("deviceID"))log("Environment: "..system.getInfo("environment"))log("Platform name: "..system.getInfo("platformName"))log("Platform version: "..system.getInfo("platformVersion"))log("Corona version: "..system.getInfo("version"))log("Corona build: "..system.getInfo("build"))log("Architecture: "..system.getInfo("architectureInfo"))log("Locale-Country: "..system.getPreference("locale","country"))log("Locale-Language: "..system.getPreference("locale","language"))end}