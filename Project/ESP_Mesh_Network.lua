--***********************************************************************
--                           MESH NETWORK
--***********************************************************************




--*****************************************************
--     NETWORK ROUTINE       
--*****************************************************

-- main loop

wifi.setmode(wifi.STATIONAP)    --turn on wifi

numberNodes = 0  -- number of ESPs in the network, up to 99 for now, setting in the webinterface
numAvNode = 0 --number of available nodes around
avNode={} --available nodes around
newNode = 0 --notification of new node in the network


function listap(t)
    --print("\n\t\t\tSSID\t\t\t\t\tBSSID\t\t\t  RSSI\t\tAUTHMODE\t\tCHANNEL")
    for bssid,v in pairs(t) do
        local ssid, rssi, authmode, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]*)")
        --print(string.format("%32s",ssid).."\t"..bssid.."\t  "..rssi.."\t\t"..authmode.."\t\t\t"..channel)
        if string.find(ssid,"ESP") then --if AP starting with "ESP", get the node number
            numAvNode=numNode+1
            avNode[numNode] = string.sub(ssid,4,2) -- give the node ID back
            numberNodes=string.sub(ssid,7) -- give back the size of the network - SSID = ESPXX_YY
            newNode = 1  -- tag to know we will need to change suffixe of ssid
        end
     end
end

wifi.sta.getap(1, listap) --do it every 10s to detect new and dead nodes around

if numAvNode==0 then
    print("No nodes availables around")
end



--[[ to print the available nodes
tmr.alarm(0,1000,1, function() 
    for i=1,numAvNode,1 do 
     print(avNode[i])
    end
end)
]]
     

--*****************************************************
--      PARSING MESSAGE
--*****************************************************

myNode = 0 --my node number, get this from settings page 
nodeTime = 0


-- global variables, keeps the stack small and more predictable if all variables are global
timeCentral = 0xFFFFF800 -- synchronise with node 0, as can't reset the millis counter. start high so can spot rollover errors (otherwise every 49 days)
--timeOffset  = 0xFFFFF800 -- offset from my local millis counter - numbers set so if program node 0, it does a refresh immediately
valueSensor1{} -- tab to store sensor's values
valueSensor2{} 
valueSensor3{} 
valueSensor4{} 
command{}
nodeTimestamps{} -- timestamps for each value
lowestNode = 255 -- 0 to 15, 255 is false, 0-15 is node last got a time sync signal from, actually the "main node"

receivedString= "" -- message received
myNodeString = "" -- message to be sent
--prevNode = nil -- node from which we got the message
destNode = 0 --node we want to send the message to
nearestNode = 0 -- node we are going to send the message to

function  processReceivedString(receivedString) -- returns the location of infos in the message
  --if (radioString.startsWith("SSID=")) { processSSID();} // parse commands
   if (timeLoc = strfind(receivedString,"Time")) then { processTimeSignal(timeLoc)} end -- parse command
   if (dataLoc = strfind(receivedString, ("Data")) then { processDataMessage(dataLoc)} end -- node,sample,timestamp
   --if (radioString.startsWith("Pack=")) { processPacket();} // all data in one large packet - too large somewhere around 100 bytes starts to error
   --and now delete the receivedstring
   --receivedString = ""; 
   createDataMessage()
end  
  
--this function get centralTime from the message, synchronize nodeTime to current loop and change centralTime when in main ESP
function processTimeSignal(timeLoc) -- Synchronize all nodes to the first running node ("main"). pass Time03FFFFFFFF where 03 is the previous node and the rest is the number of ms in hexa
 s = strsub (receivedString,timeLoc+4,timeLoc+14);
  --[[   INTENT TO ADAPT INSTRUCTABLE CODE BUT CAN'T SEE THE USE
 messageFrom = strsub(s,1,2)
 if ((messageFrom <= lowestNode) && (myNode != 0))then --  current time slot is less or equal than the last node update number, so refresh time, so minimum number of hops
   nodetime = tmr.now()
   centraltime = strsub(s,3) -- time received with the message, number of ms since system started, up to 49 days
   --centraltime = centraltime + 250; -- probably not usefull offset to allow for delay with transmission, determined by trial and error, if slow, then add more
   timeOffset = centraltime-nodetime --delay 
   lowestNode = messageFrom -- update with the new current time and the lowest node number (ie "main" node)
 end  
end]]
 centraltime = strsub(s,3)
 if tmr.now() < centraltime then        -- if late
    nodetime = centraltime              -- get the right time, synchronization of the system
 else 
    centralTime = tmr.now()             -- update the system time every time we pass through Main ESP
    --comTime = centralTime-centraltime   -- get the communication time between ESPs 
    lowestNode = strsub(s,1,2)          -- previous main must have stop and hotstandby becomes Main
 end 
 --transmitTime(ReceivedString) -- done in create message
end -- issue to solve: every 49 days centralTime must be reset   

--[[{       INTRUCTABLE CODE -- can't understand the point of this
 void processTimeSignal() // pass Time=03 00000000 where 03 is the node this came from
{String s;
 unsigned long centraltime;
 unsigned long mytime;
 int messageFrom;
 s = stringMid(radioString,6,2);
 s = "000000" + s;
 messageFrom = (int) hexToUlong(s);
 s = radioString;
 s = stringMid(s,9,8);
 lnprintlcd("Time msg from ");
 printlcdstring((String) messageFrom);
 if ((messageFrom <= lowestNode) && (myNode != 0)) // current time slot is less or equal than the last node update number, so refresh time, so minimum number of hops
 {
   mytime = (unsigned long) millis();
   centraltime = hexToUlong(s); // convert back to a number
   centraltime = centraltime + 250; // offset to allow for delay with transmission, determined by trial and error, if slow, then add more
   timeOffset = centraltime - mytime;
   lnprintlcd("New ");
   displayTime();
   lowestNode = messageFrom; // update with the new current lowest node number
 }  
}]]



--[[void refreshTime()
{
  timeCentral = ((unsigned long) millis()) + timeOffset;
}]]
 
--[[not usefull
function transmitTime(receivedString) -- send my local time, will converge on the lowest node number's time
  newMessage = strsub (receivedString,timeLoc+4,timeLoc+14)..mynode..centralTime..strsub (receivedString,timeLoc+24)
  return newMessage --send 
end ]]

function processDataMessage(dataLoc) -- Data0312AAAAAAAACBBBBBBBBcrlf where 03 is from, 12 is node (hex), AAAA is integer data, C command, BBBBBBBB is the time stamp
  for i = 0, numberNodes-1, 1 do 
    destNode = strsub(receivedString, dataLoc+4, dataLoc+6)    
    node = strsub(receivedString, dataLoc+6 + i*19, dataLoc+6 + i*19 + 2)   -- 1 data = 2 hexa char, 5 data per node (node and sensors) + 1 command + 8 hexa for timeStamp = 19 char
    nodeTimeStamps[i]=strsub(receivedString, dataLoc+6 + i*19 + 13, dataLoc+6 + i*19 + 21)
    if (nodeTimeStamps[i] > nodeTime) then -- /!\ myNode DATA MUST BE UPLOAD AFTER THIS FUNCTION, OTHERWISE DATA WILL BE ERASED - saving latest data (ie of the current loop) to communicate the data through
        valueSensor1[i]=strsub(receivedString, dataLoc+6 + i*19 + 2, dataLoc+6 + i*19 + 4)
        valueSensor2[i]=strsub(receivedString, dataLoc+6 + i*19 + 4, dataLoc+6 + i*19 + 6)
        valueSensor3[i]=strsub(receivedString, dataLoc+6 + i*19 + 6, dataLoc+6 + i*19+ 8)
        valueSensor4[i]=strsub(receivedString, dataLoc+6 + i*19 + 8, dataLoc+6 + i*19+ 10)
        command[i]=strsub(receivedString, dataLoc+6 + i*19 + 10, dataLoc+4 + i*19 + 11)
    end
    print(i) -- test: i should = node 
    print(node)
   end
   if destNode == myNode then   -- deal with the ROUTING PROCESS! a destNode is assigned at the beginning of the message. If reached, destNode incremented or reset, if not send to closest lower node
    if myNode~=numberNodes-1 then
        destNode=myNode+1
    else destNode=0
    end
   end
   updateCommand()
   updateMyValues() --read sensors and update myNode values
   printmyData()
   receivedString = "" --reset received message
end  

function createDataMessage() -- (read sensors) and create data string
  myNodeString = "Time"..centralTime.."Data".. destNode -- to the destination node
  --delay(150); // for any previous message to go through
  for i=0, numberNodes, 1 do
    myNodeString = myNodeString..i..valueSensor1[i]..valueSensor2[i]..valueSensor3[i]..valueSensor4[i]..command[i]..nodeTimeStamps[i]
    -- send -altSerial.println(buildMessage); // transmit via radio
    --delay(150); // errors on 75, ok on 100
  end
end  

--*********************************************************************
--              ANALOG ROUTINE
--*********************************************************************


function updateCommand()
  gpio.mode(6,gpio.OUTPUT) -- GPIO12 output
  if command[myNode] then
    gpio.write(6, gpio.HIGH)
  else gpio.write(6, gpio.LOW)
  end
end

function updateMyValue() --sensors - be sure to adc.force_init_mode(adc.INIT_ADC) in init.lua
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
end

--[[ SHOULD NOT USE IT IF COMMUNICATION WITH ALGORITHM  - here a node send data to all other by radio and upload its data when on its timeslot. Our message goes through one node at a time
void NodeTimeSlot() // takes 100ms at beginning of slot so don't tx during this time.
// time slots are 4096 milliseconds - easier to work with binary maths
{
  unsigned long t;
  unsigned long remainder;
  int timeSlot = 0;
  refreshTime(); // update timeCentral
  t = timeCentral >> 12; // 4096ms counter
  t = t << 12; // round
  remainder = timeCentral - t;
  if (( remainder >=0) && (remainder < 100)) // beginning of a 4096ms time slot
  {
     digitalWrite(13,HIGH);
     //printlcdstring("Slot ");
     timeSlot = getTimeSlot();
     lnprintlcd((String) timeSlot);
     printlcdstring(" ");
     //printPartnerNode(); // print my partner's value
     printNode(timeSlot); // print the value of this node
     //printHeapStack(); // heap should always be less than stack
     if ( timeSlot == 0) { lowestNode = 255; } // reset if nod zero get time from the lowest node number, 0 to 15 and if 255 then has been reset
     delay(110);
     digitalWrite(13,LOW);
     if (timeSlot == myNode) // transmit if in my time slot
     {
       lnprintlcd("Sending my data"); // all nodes transmit central time, when listening, take the lowest number and ignore others
       transmitTime();
       digitalWrite(13,HIGH); // led on while tx long data message
       createDataMessage(); // send out all my local data via radio
       outputRS232(); // send out all the node values via RS232 port (eg to a PC)
       digitalWrite(13,LOW); // led off
       //buildPacket(); - too large, deleted this
       //printPartnerNode(); // print my partner's value
      }
  }  
}  

int getTimeSlot() // find out which time slot we are in
{
  int n;
  unsigned long x;
  refreshTime();
  x = timeCentral >> 12; // divide by 4096
  x = x & 0x0000000F; // mask so one of 16
  n = (int) x;
  return n;
}  

//void printPartnerNode() // can output partner node's values or do other things
//{
//  printlcdstring("Mate ");
//  printlcdstring((String) partnerNode);
//  printlcdstring("=");
//  printlcdstring((String) nodeValuesA0[partnerNode]);
//  printlcdstring(",");
//  printlcdstring((String) nodeValuesA1[partnerNode]);
//}  
]]

function printNodeData() 
  print(receivedString)
  print(myNode)
  print(valueSensor1[myNode])
  print(valueSensor2[myNode])
  print(valueSensor3[myNode])
  print(valueSensor4[myNode])
  print(nodeTimeStamps[myNode])
  print(centralTime)
end  
  
--[[/* This function places the current value of the heap and stack pointers in the
 * variables. You can call it from any place in your code and save the data for
 * outputting or displaying later. This allows you to check at different parts of
 * your program flow.
 * The stack pointer starts at the top of RAM and grows downwards. The heap pointer
 * starts just above the static variables etc. and grows upwards. SP should always
 * be larger than HP or you'll be in big trouble! The smaller the gap, the more
 * careful you need to be. Julian Gall 6-Feb-2009.
 */
uint8_t * heapptr, * stackptr;
void check_mem() {
  stackptr = (uint8_t *)malloc(4);          // use stackptr temporarily
  heapptr = stackptr;                     // save value of heap pointer
  free(stackptr);      // free up the memory again (sets stackptr to 0)
  stackptr =  (uint8_t *)(SP);           // save value of stack pointer
}

void printHeapStack()
{
  int n;
  check_mem();
  printlcdstring("Heap/Stack=");
  n = (int) heapptr;
  printlcdstring((String) n);
  printlcdstring(",");
  n = (int) stackptr;
  printlcdstring((String) n);
}    

]]


--***********************************************
--          SENDING ROUTINE
--***********************************************

function sendTo()   --to get the nest node to send the data
 for i=1,numAvNode do 
    if avNode[i] == destNode then
        nearestNode=destNode
        break
    else
        local min
        if avNode[i]-destNode < min then    -- nearestNode sera celle la plus proche de destNode dans l'ordre numerique
           avNode[i]-destNode = min         -- min < 0 si nearestNode précède destNode, min > 0 si suivant
        end
        nearestNode = destNode + min
    end
 end
end

--*************************************************
--              WEB SERVER
--*************************************************



-- **************************************************************
_,RID=node.bootreason()

-- ******* Variables
myheap=0
cpt =0 --counter
ok  =0 --ESPs answer
ans = "nothing"
pl2 = "je n y suis pas encore "

-- ******* Code


-- ******* WiFi configurations

myNode=numberNodes          -- if network size is 3, there is ESP 0, 1 and 2, so new one is 3
numberNodes=numberNodes+1   -- and the size increases
ap_ssid="ESP"..myNode.."_"..numberNodes --this module ssid as ESPXX_YY, XX=nodeID, YY=network size
ap_pass="" --this module password

wifi_cfg={}
ip_cfg={ip="192.168."..myNode..".1"}
wifi_cfg.ssid=ap_ssid --3 next lines to config module access point 
--wifi_cfg.pwd="" --uncomment if you want a password
wifi.ap.config(wifi_cfg)
wifi.ap.setip(ip_cfg) -- ip adress of ap needs to be different than others ESPs' in order to have several ESP in server at the same time


-- web page 
function LoadBuff()
local buff2 = '<!DOCTYPE HTML><html><head><meta charset="UTF-8"><meta http-equiv="refresh" content="10">\
<title>MESH NETWORK</title></head><body style="background:skyblue">\
Hi! This is a first Test to create a MESH NETWORK server using ESP8266! ESP'..myNode..' speaking. I am connected to ESP '..avNode[1]..' among others and sending a very long message to one of them. IPA:  Answer: '..ans..' Time(s:) '..cpt..'</body></html>'
lenght= #buff2

buff1 = 'HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n'..
'Content-Length: '.. lenght ..'\r\n'..
'Cache-Control: max-age=120\r\n'..
'Connection: Keep-Alive\r\n\r\n'..buff2
buff2=nil

local buff4 = '<!DOCTYPE HTML><html><head><meta charset="UTF-8"><meta http-equiv="refresh" content="10">\
<title>PAGE 1</title></head><body style="background:grey">\
Welcome on the 1st page of this server'
lenght4= #buff4
buff3 = 'HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n'..
'Content-Length: '.. lenght4 ..'\r\n'..
'Cache-Control: max-age=120\r\n'..
'Connection: Keep-Alive\r\n\r\n'..buff4
buff4=nil

collectgarbage()
end



-- Server
function StartServer()
srv = net.createServer(net.TCP) --, 120) --120 = timeout
local myPort=30000+myNode

--listening to other nodes
srv:listen(myPort, function (conn) 
            conn:on("receive",
            function (sk, str)
                print(str)
                if str ~= nil then
                    sk:send("OK")
                end
                receivedString = str        
                processReceivedString(receivedString)
                collectgarbage()
            end)
            conn:on("sent", function(sk) sk:close() end)
            end)

--listening to Web request
srv:listen(80, function (sck, pl) 
            sck:on("receive", 
            function (sk,string)  
            -- deal with web interface here
                sk:send(buff1)
                end
            collectgarbage()
            end)
            sck:on("sent", function(sck) print (sck) sck:close() end)
        end)
end



--Sending to nearestNode

function sendingMessage()

    sta_ssid = "ESP"..nearestNode.."_"..numberNodes -- your router SSID you want to connect to
    sta_pass = "" -- your router password you want to connect to
    wifi.sta.config(sta_ssid, sta_pass) --config to connect to wifi station
    wifi.sta.connect()

    conn=net.createConnection(net.TCP, 0) --security: , false)
    local destPort = 30000+nearestNode 
    conn:connect(destPort,"192.168."..nearestNode..".1") 
    conn:on("connection", function(conn)
        print("connection to nearest ESP:")
        conn:send(myNodeString)
        conn:on("sent", function(conn) print(conn) end)
    end)
    conn:on("receive", function(conn,string) 
        print(string)
        if string == "OK" then
            print("The Message was successfully passed on")
        else print("An error occured during the communication")
        end
    end)
end



--main loop
tmr.alarm(0,100,1,
    function()
        if newNode ==1 then --if a new Node appeared we need to change the ssid of myNode ('cause the size is shown in it)
            numberNodes = numberNodes+1
            ap_ssid = "ESP"..myNode.."_"..numberNodes 
            wifi_cfg.ssid=ap_ssid --3 next lines to config module access point 
            wifi.ap.config(wifi_cfg)
            newNode = 0
        end 
        tmr.stop(0)
        print("Server start")
        StartServer()
        --LoadBuff()
        tmr.alarm(1,1000,1,
            function()
                LoadBuff()
                if wifi.sta.getip()==nil
                then
                print("Wait for Destination Node 's IP")
                else
                ipa,_,_=wifi.sta.getip()
                print("Destination Node's IP is ",ipa)
                tmr.stop(1)
                sendingMessage()
                end
             end) 
end)
         


