wifi.setmode(wifi.STATIONAP)    --turn on wifi

myNode = 0 --my node number, get this from settings page 
nodeTime = 0

-- Message Processing Variables
timeCentral = 0xFFFFF800 -- synchronise with node 0, as can't reset the millis counter. start high so can spot rollover errors (otherwise every 49 days)
--timeOffset  = 0xFFFFF800 -- offset from my local millis counter - numbers set so if program node 0, it does a refresh immediately
nodeID =0
valueSensor1={} -- tab to store sensor's values
valueSensor2={} 
valueSensor3={} 
valueSensor4={} 
command={}
nodeTimeStamps={} -- timestamps for each value
lowestNode = 255 -- 0 to 15, 255 is false, 0-15 is node last got a time sync signal from, actually the "main node"

--Message Parsing Variables
--receivedString= "" -- message received
myNodeString = "" -- message to be sent
--prevNode = nil -- node from which we got the message
--destNode = 0 --node we want to send the message to
nearestNode = nil -- node we are going to send the message to

-- Mesh Network Variables

myNode=0
numberNodes = 0  -- number of ESPs in the network, up to 99 for now, setting in the webinterface
numAvNode = 0 --number of available nodes around
avNode={} --available nodes around
newNode = 0 --notification of new node in the network


ok  =0 --ESPs answer


function configAP()
   
              -- if network size is 3, there is ESP 0, 1 and 2, so new one is 3
    ap_ssid="ESP"..myNode.."_"..numberNodes --this module ssid as ESPXX_YY, XX=nodeID, YY=network size
    --ap_pass="" --this module password
    wifi_cfg={}
    ip_cfg={ip="192.168."..myNode..".1"}
    print(ip_cfg.ip)

    wifi_cfg.ssid=ap_ssid --3 next lines to config module access point 
    --wifi_cfg.pwd="" --uncomment if you want a password
    wifi.ap.config(wifi_cfg)
    wifi.ap.setip(ip_cfg) -- ip adress of ap needs to be different than others ESPs' in order to have several ESP in server at the same time
end

-- Server
function StartServer()
srv = net.createServer(net.TCP) --, 120) --120 = timeout
local myPort=30000+myNode

srv:listen(myPort, function (sck)   -- to access web interface: IPadress:NodePort/web
            sck:on("receive", 
                function (sk,string)  
                    webInterface(sk, string)
                    collectgarbage()
                end)
            sck:on("sent", function(sk) print (sk) sk:close() end)
        end)
        
end

function webInterface(socket, string)   -- send to ESP or to WEB Interface according to request

    if string.sub(string,6,8) == "web" then 
         socket:send(buff1)
    else print("processing received message")
         print(string)
    end
    socket:send("OK")
end

--Sending to nearestNode
 nearestNode=0
 function configSTA()

end

--[[function sendingMessage(nearestNode, myNodeString)

   
    print("esp ssid"..sta_ssid)
    
    --local sssid=wifi.sta.gethostname()
    --print("connected to "..sssid)


    conn=net.createConnection(net.TCP, 0) --security: , false)
    local destPort = 30000+nearestNode 
    print("destPort is "..destPort) 
    local ipa="192.168."..nearestNode..".1"
    print(ipa)
    conn:connect(30000,"192.168.0.1") 
    print("ici")
    conn:on("connection", function(conn)
        print("connection to nearest ESP:")
        print(myNodeString)
        conn:send(myNodeString)        
        conn:on("sent", function(conn) print(conn) end)
        collectgarbage()
        print("sent")
    end)
    print("here")
    conn:on("receive", function(conn,string) 
        print("received is "..string)
        if string == "OK" then
            print("The Message was successfully passed on")
        else print("An error occured during the communication")
        end
    end)
    nearestNode=nil
end
]]


function listap(t)
    --print("\n\t\t\tSSID\t\t\t\t\tBSSID\t\t\t  RSSI\t\tAUTHMODE\t\tCHANNEL")
    for bssid,v in pairs(t) do
        local ssid, rssi, authmode, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]*)")
        --print(string.format("%32s",ssid))
        if string.find(ssid,"ESP") then --if AP starting with "ESP", get the node number
            numAvNode=numAvNode+1
            avNode[numAvNode] = string.sub(ssid,4,4) -- for the test
            --avNode[numAvNode] = string.sub(ssid,4,2) -- give the node ID back
            numberNodes=string.sub(ssid,6) -- give back the size of the network - SSID = ESPXX_YY
            newNode = 1  -- tag to know we will need to change suffixe of ssid
        end
    end
end


function  processReceivedString(receivedString) -- returns the location of infos in the message
   --print(receivedString)
   if (string.find(receivedString,"Time")) then  
       local timeLoc = string.find(receivedString,"Time") 
       local time = processTimeSignal(timeLoc+4, receivedString)
       if (string.find(receivedString, "Data")) then  
            local dataLoc = string.find(receivedString,"Data")
            local destinationNode = processDataMessage(dataLoc+4, receivedString, time)
            print("destNode is "..destinationNode)
            myNodeString = createDataMessage(time, destinationNode)
            nearestNode = sendTo(destinationNode)
       else print("The message did not return Data") 
       end -- node,sample,timestamp
   else print("The message did not return Time") 
   end -- parse command
   collectgarbage()
end  

  
  

function processTimeSignal(timeLoc, receivedString) -- Synchronize all nodes to the first running node ("main"). pass Time03FFFFFFFF where 03 is the previous node and the rest is the number of ms in hexa
 local nodeTime = ""
 endoftime = string.find(receivedString,"_")
 s = string.sub(receivedString,timeLoc,endoftime-1) --20/07/16 test with time only (no previousnode), delete once done
 lowestNode = string.sub(s,1,1)
 centraltime = string.sub(s,2)
 if tmr.time() < tonumber(centraltime) then        -- if late
    nodeTime = centraltime              -- get the right time, synchronization of the system
 else 
    nodeTime = nodeTime..tmr.time()             -- update the system time every time we pass through Main ESP
    lowestNode = myNode --string.sub(s,1,2)          -- previous main must have stop and hotstandby becomes Main
 end 
 return nodeTime
end -- issue to solve: every 49 days centralTime must be reset   

--[[function nextNode(destNode)
   if destNode == myNode then   -- deal with the ROUTING PROCESS! a destNode is assigned at the beginning of the message. If reached, destNode incremented or reset, if not send to closest lower node
    if myNode~=numberNodes-1 then
        destNode=myNode+1
    else destNode=0
    end
   end
   return destNode
end]]

-- cette fonction doit etre adaptée: lorsque plusieurs node, 
-- je dois trouver un moyen de signalé qu'on passe à la node suivante, 
-- puisque tmr.time() change de taille
function processDataMessage(dataLoc, receivedString, time) -- Data0312AAAAAAAACBBBBBBBBcrlf where 03 is from, 12 is node (hex), AAAA is integer data, C command, BBBBBBBB is the time stamp
   local s = string.sub(receivedString, dataLoc) 
   local destNode = string.sub(s,1,2)
   print("dest node here is ".. destNode)
   for i = 0, numberNodes-1 do   
        --nodeID = string.sub(s, dataLoc+2 + i*19, dataLoc+6 + i*19 + 2)   -- 1 data = 2 hexa char, 5 data per node (node and sensors) + 1 command + 8 hexa for timeStamp = 19 char
        nodeID = string.sub(s, 3 + i*15, 3 + i*15 + 1)   -- 1 data = 2 hexa char, 5 data per node (node and sensors) + 1 command + 8 hexa for timeStamp = 19 char
        --nodeTimeStamps[i]=string.sub(s, dataLoc+6 + i*19 + 13, dataLoc+6 + i*19 + 21)
        nodeTimeStamps[i]=string.sub(s, 15 + i*15, 15 + i*15 + 16)
        print("nodeTimestamp"..i.." is = "..nodeTimeStamps[i])
        print("time is "..time) 
        if (nodeTimeStamps[i] < time) then -- /!\ myNode DATA MUST BE UPLOAD AFTER THIS FUNCTION, OTHERWISE DATA WILL BE ERASED - saving latest data (ie of the current loop) to communicate the data through
            valueSensor1[i]=string.sub(s, 5 + i*15, 5 + i*15 + 1)
            valueSensor2[i]=string.sub(s, 7 + i*15, 7 + i*15+ 1)
            valueSensor3[i]=string.sub(s, 9 + i*15, 9 + i*15+ 1)
            valueSensor4[i]=string.sub(s, 11 + i*15, 11 + i*15+ 1)
            command[i]=string.sub(s, 13 + i*15, 13 + i*15 + 1)
        end
   end
   if destNode == myNode then   -- deal with the ROUTING PROCESS! a destNode is assigned at the beginning of the message. If reached, destNode incremented or reset, if not send to closest lower node
        if myNode~=numberNodes-1 then
            destNode=myNode+1
        else destNode=0
        end
   end
   return destNode
end
   --next = nextNode(destNode)
   --return next
   --print("Next Node is: "..next)
   --updateCommand()
   --updateMyValues() --read sensors and update myNode values
   --printmyData()
   --receivedString = "" --reset received message
 


function createDataMessage(time, destinationNode) -- (read sensors) and create data string
  local myString = "Time"..time.."_Data"..destinationNode -- should be nodeTime, no? to the destination node
  for i=0, numberNodes-1, 1 do --change back to numberNodes when sensors are actives
    myString = myString..i..valueSensor1[i]..valueSensor2[i]..valueSensor3[i]..valueSensor4[i]..command[i]..nodeTimeStamps[i]
  end
  print("My String is: "..myString)
  return myString
end  

--[[function updateCommand()
  gpio.mode(6,gpio.OUTPUT) -- GPIO12 output
  if command[myNode] then
    gpio.write(6, gpio.HIGH)
  else gpio.write(6, gpio.LOW)
  end
end]]

--[[function updateMyValue() --sensors - be sure to adc.force_init_mode(adc.INIT_ADC) in init.lua
  gpio.mode(5,gpio.OUTPUT) -- GPIO14 output
  gpio.mode(0,gpio.OUTPUT) -- GPIO16 output
  --set ADC
  gpio.write(5, gpio.LOW)
  gpio.write(0, gpio.LOW)
  valueSensor1[myNode] = adc.read(0)  --read adc entry. ADC RETURNS 10 BITS, SHOULD BE CORRECTED
  tmr.delay(10)                     --next tmr - MUST be improve! make de proc busy for 10us, not te best option
  gpio.write(5, gpio.HIGH)
  gpio.write(0, gpio.LOW)
  valueSensor2[myNode] = adc.read(0)  
  tmr.delay(10)--next tmr
  gpio.write(5, gpio.LOW)
  gpio.write(0, gpio.HIGH)
  valueSensor3[myNode] = adc.read(0)  
  tmr.delay(10)--next tmr
  gpio.write(5, gpio.HIGH)
  gpio.write(0, gpio.HIGH)
  valueSensor4[myNode] = adc.read(0) 
  tmr.delay(10) 
  nodeTimestamps[myNode] = timeCentral --this was updated now
end]]

function printNodeData() 
  --print(receivedString)
  print(nodeID[0])
  print(valueSensor1[0])
  print(valueSensor2[0])
  print(valueSensor3[0])
  print(valueSensor4[0])
  print(nodeTimeStamps[0])
  --print(centralTime)
end  

function sendTo(destinationNode)   --to get the nest node to send the data
 local nearNode=0
 local destNode = tonumber(destinationNode)
 print("dest node there is ".. destNode)
 for i=1,numAvNode do 
    if avNode[i] == destNode then
        nearNode = destNode
        return nearNode
    else    
        local min = 99
        if (avNode[i]-destNode) < min then    -- nearestNode sera celle la plus proche de destNode dans l'ordre numerique
           min = avNode[i]-destNode         -- min < 0 si nearestNode précède destNode, min > 0 si suivant
        end
        nearNode = destNode + min
        print("nearNOde "..nearNode)
    end
 end
 return nearNode
end


function configAP()
   
    myNode=numberNodes          -- if network size is 3, there is ESP 0, 1 and 2, so new one is 3
    ap_ssid="ESP"..myNode.."_"..numberNodes --this module ssid as ESPXX_YY, XX=nodeID, YY=network size
    --ap_pass="" --this module password
    wifi_cfg={}
    ip_cfg={ip="192.168."..myNode..".1"}

    if newNode ==1 then --if a new Node appeared we need to change the ssid of myNode ('cause the size is shown in it)
      numberNodes = numberNodes +1
      ap_ssid = "ESP"..myNode.."_"..numberNodes 
      newNode = 0
    end 
    wifi_cfg.ssid=ap_ssid --3 next lines to config module access point 
    --wifi_cfg.pwd="" --uncomment if you want a password
    wifi.ap.config(wifi_cfg)
    wifi.ap.setip(ip_cfg) -- ip adress of ap needs to be different than others ESPs' in order to have several ESP in server at the same time
end

-- web page 
function LoadBuff()
local buff2 = '<!DOCTYPE HTML><html><head><meta charset="UTF-8"><meta http-equiv="refresh" content="10">\
<title>MESH NETWORK</title></head><body style="background:skyblue">\
Hi! This is a first Test to create a MESH NETWORK server using ESP8266! ESP'..myNode..' speaking. I am connected to ESP '..avNode[1]..' among others and sending a very long message to one of them.</body></html>'
lenght= #buff2
buff1 = 'HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n'..
'Content-Length: '.. lenght ..'\r\n'..
'Cache-Control: max-age=120\r\n'..
'Connection: Keep-Alive\r\n\r\n'..buff2
buff2=nil
collectgarbage()
end



-- Server
function StartServer()
srv = net.createServer(net.TCP) --, 120) --120 = timeout
local myPort=30000+myNode

srv:listen(myPort, function (sck)   -- to access web interface: IPadress:NodePort/web
            sck:on("receive", 
                function (sk,string)  
                    webInterface(sk, string)
                    collectgarbage()
                end)
            sck:on("sent", function(sk) print (sk) sk:close() end)
        end)
        
end

function webInterface(socket, string)   -- send to ESP or to WEB Interface according to request

    if string.sub(string,6,8) == "web" then 
         socket:send(buff1)
    else print("processing received message")
         processReceivedString(string)
    end
    socket:send("OK")
end

--Config STA

--[[function configSTA()--nearestNode)
    --local forthetest = 1
    --sta_ssid = "ESP"..nearestNode.."_"..forthetest --numberNodes -- your router SSID you want to connect to
    local sta_ssid = "ESP0_1" --numberNodes -- your router SSID you want to connect to
    local sta_pass = "" -- your router password you want to connect to
    wifi.sta.config(sta_ssid, sta_pass) --config to connect to wifi station
    wifi.sta.connect()
                        
end]]
--Sending to nearestNode

--[[function sendingMessage(nearestNode, myNodeString)

    
    conn=net.createConnection(net.TCP, 0) --security: , false)
    local destPort = 30000+nearestNode 
    print("destPort is "..destPort) 
    local ipa="192.168."..nearestNode..".1"
    --print(ipa)
    conn:connect(destPort,ipa) 
    print("ici")
    conn:on("connection", function(conn)
        print("connection to nearest ESP:")
        conn:send(myNodeString)        
        conn:on("sent", function(conn) print(conn) end)
        print("sent")
    end)
    print("here")
    conn:on("receive", function(conn,string) 
        print("received is "..string)
        if string == "OK" then
            print("The Message was successfully passed on")
        else print("An error occured during the communication")
        end
    end)
    nearestNode=nil
end]]
           




--main loop
tmr.alarm(4,10000,1, function() 
    wifi.sta.getap(1, listap) --do it every 10s to detect new and dead nodes around
    if numAvNode==0 then
        print("No nodes availables around")
        avNode[1] = "no Node around"  -- not to haev error in the buffer. delete this line when the WI is ready
    else 
        print(numAvNode.." nodes have been detected")
        numAvNode=0
        configAP()
        tmr.stop(4)--0)
        print("Server start")
        LoadBuff()
        StartServer()
        tmr.alarm(1,8000,1,
                function()
                    LoadBuff()
                    if nearestNode==nil then
                        print("Waiting")
                    else
                        print("entering hell")
                        sta_ssid = "ESP"..nearestNode.."_"..numberNodes -- your router SSID you want to connect to
                        sta_pass = "" -- your router password you want to connect to
                        print(sta_ssid)
                    end
                 end)
    end
end)
