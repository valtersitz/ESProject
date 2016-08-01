wifi.setmode(wifi.SOFTAP)    --turn on wifi


-- Message Processing Variables

valueSensor1= nil -- tab to store sensor's values
valueSensor2= nil 
valueSensor3= nil
valueSensor4= nil
command= 0


--Message Parsing Variables
myNodeString = "" -- message to be sent

myNode=0

----- AP SET-UP -----

ap_ssid="ESP_Sensors"
--ap_pass="" --this module password
wifi_cfg={}
ip_cfg={ip="192.168.0.1"}
wifi_cfg.ssid=ap_ssid --3 next lines to config module access point 
--wifi_cfg.pwd="" --uncomment if you want a password
wifi.ap.config(wifi_cfg)
wifi.ap.setip(ip_cfg) -- ip adress of ap needs to be different than others ESPs' in order to have several ESP in server at the same time


-- Server
function StartServer()
    if srv then srv:close() srv=nil end -- close running server
    srv = net.createServer(net.TCP) --, 120) --120 = timeout
    local myPort=30000    
    srv:listen(myPort, function (sck)   -- to access web interface: IPadress:NodePort/web
                sck:on("receive", 
                    function (sk,string) 
                        print(string)
                        print("Processing Request...") 
                        processRequest(string)
                        print("sending String...")
                        sk:send(myString)
                        print(myString)
                        collectgarbage()
                    end)
                sck:on("sent", function(sk) print ("String Sent") sk:close() end)
            end)
            
    end

function processRequest(string)
    local request = string.find(string,"command")
    if request then
       command = string.sub(string,request+7,request+8)
       print("Command is "..command)
    end
    updateCommand(command)
end


function createDataMessage() --  create data string
  myString = "Time"..tmr.time().."_Data"
  myString = myString..valueSensor1..valueSensor2..valueSensor3..valueSensor4..command
  print("My String is: "..myString)
  return myString
end  


function updateCommand(command)
  gpio.mode(6,gpio.OUTPUT) -- GPIO12 output
  if command then
    gpio.write(6, gpio.HIGH)
  else gpio.write(6, gpio.LOW)
  end
end


function updateMyValues() --sensors - be sure to adc.force_init_mode(adc.INIT_ADC) in init.lua
  gpio.mode(5,gpio.OUTPUT) -- GPIO14 output
  gpio.mode(0,gpio.OUTPUT) -- GPIO16 output
  --set ADC
  gpio.write(5, gpio.LOW)
  gpio.write(0, gpio.LOW)
  valueSensor1 = adc.read(0)  --read adc entry. ADC RETURNS 10 BITS, SHOULD BE CORRECTED
  print("VS1 "..valueSensor1)
  tmr.delay(10)                     --next tmr - MUST be improve! make de proc busy for 10us, not te best option
  gpio.write(5, gpio.HIGH)
  gpio.write(0, gpio.LOW)
  valueSensor2 = adc.read(0) 
  print("VS2 "..valueSensor2) 
  tmr.delay(10)--next tmr
  gpio.write(5, gpio.LOW)
  gpio.write(0, gpio.HIGH)
  valueSensor3 = adc.read(0)  
  print("VS3 "..valueSensor3)
  tmr.delay(10)--next tmr
  gpio.write(5, gpio.HIGH)
  gpio.write(0, gpio.HIGH)
  valueSensor4 = adc.read(0) 
  print("VS4 "..valueSensor4)
  tmr.delay(10) 
end

function printNodeData() 
  print(valueSensor1)
  print(valueSensor2)
  print(valueSensor3)
  print(valueSensor4)
  print(command)
end  
    




--main loop
tmr.alarm(0,10000,1, function() 
    print("Uploading data...")
    updateMyValues()
    createDataMessage()
    tmr.stop(0)
    print("Server start")
    StartServer()
    tmr.alarm(1,8000,1,
        function()
            updateMyValues()
            createDataMessage()
            printNodeData()
            for mac,ip in pairs(wifi.ap.getclient()) do
                print(mac,ip)
            end
            if ip ~= nil  then
               print("Client Connected")
            else
               print("waiting...")
            end
         end)
end)
