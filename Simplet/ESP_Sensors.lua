


-- Message Processing Variables


command= 0


--Message Parsing Variables
myNodeString = "" -- message to be sent

myNode=0
-------------------------------------------- 

--tmr.delay(1000)

print("heap2 is: "..node.heap())

function adc_ler(media,x)   
    while(x < 27)do
        media = media + adc.read(0)
        x = x + 1 
    end
        adc_valor = media/27
end

function ler()
        print("inicio leitura")
    -- Leitura de concentra��o
       gpio.write(5, gpio.LOW)
       gpio.write(6, gpio.HIGH)

       tmr.delay(1000000)
       adc_ler(0,0)
       luz_ambiente = adc_valor
             
       gpio.write(1, gpio.LOW)
       gpio.write(2, gpio.LOW)
       gpio.write(4, gpio.HIGH)
       pwm.setduty(3, led_cor[vermelho])
       tmr.delay(1000000)
       adc_ler(0,0)
       adc_valor = adc_valor - luz_ambiente
       adc_valor = string.format("%.2f", adc_valor) 
       print("adc_vermelho = ",adc_valor)
       valueSensor2 = adc_valor
       print("pwm_vermelho = ",led_cor[vermelho])

       gpio.write(1, gpio.HIGH)
       gpio.write(2, gpio.LOW)
       gpio.write(4, gpio.LOW)
       pwm.setduty(3, led_cor[verde])
       tmr.delay(1000000)
       adc_ler(0,0)
       adc_valor = adc_valor - luz_ambiente
       adc_valor = string.format("%.2f", adc_valor) 
       print("adc_verde = ",adc_valor)
       valueSensor3 = adc_valor
       print("pwm_verde = ",led_cor[verde])
       
       gpio.write(1, gpio.LOW)
       gpio.write(2, gpio.HIGH)
       gpio.write(4, gpio.LOW)
       pwm.setduty(3, led_cor[azul])
       tmr.delay(1000000)
       adc_ler(0,0)
       adc_valor = adc_valor - luz_ambiente
       adc_valor = string.format("%.2f", adc_valor) 
       print("adc_azul = ",adc_valor)
       valueSensor4 = adc_valor
       print("pwm_azul = ",led_cor[azul])

       gpio.write(1, gpio.LOW)
       gpio.write(2, gpio.LOW)
       gpio.write(4, gpio.LOW)
       pwm.setduty(3, 1023)
    
    -- Leitura de temperatura
     
       gpio.write(5, gpio.HIGH)
       gpio.write(6, gpio.LOW)
       
       tmr.delay(1000000)
       adc_ler(0,0)
       temp = 23 + (((3.3/1024)*adc_valor - (3.3/1024)*151)/-0.002)
       temp = math.floor(temp) 
       valueSensor1 = temp
    
   print("temperatura = ",temp)       
       print("fim leitura")
end


---------------------------------------------------------------------------
--------------------------------------------------------------------------



   

function processRequest(string)
    local request = string.find(string,"command")
    if request then
       command = string.sub(string,request+7,request+8)
       print("Command is "..command)
    end
    updateCommand(command)
end


function updateCommand(command)
  gpio.mode(7,gpio.OUTPUT) -- GPIO12 output
  if command then
    gpio.write(7, gpio.HIGH)
  else gpio.write(7, gpio.LOW)
  end
end


-----------------------------------------------------------------------------
-----------------------------------------------------------------------------





function createDataMessage() --  create data string
  myString = "Time"..tmr.time().."_Data"
  myString = myString..valueSensor1..":"..valueSensor2..":"..valueSensor3..":"..valueSensor4..":"..command
  print("My String is: "..myString)
end  

function sendDataMessage()
print("sending String...")
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

function printNodeData() 
  print("SV1 temp is "..valueSensor1)
  print("SV2 red is "..valueSensor2)
  print("SV3 greenis "..valueSensor3)
  print("SV4 blue is "..valueSensor4)
  print(command)
end  

----------------------------------------------------------------
--                      Start Server
----------------------------------------------------------------


-- Server
function StartServer()
print("heap4 is: "..node.heap())
    if srv then srv:close() srv=nil end -- close running server
    srv = net.createServer(net.TCP) --, 120) --120 = timeout
    print("heap5 is: "..node.heap())
end



--main loop
StartServer()
print("heap6 is: "..node.heap())
if (valueSensor1 == nil or valueSensor2 == nil or valueSensor3 == nil or valueSensor4 == nil) then
   ler()
   print("heap7 is: "..node.heap())
end
tmr.alarm(0,10000,1, function() 
    printNodeData()
    createDataMessage()
    print("heap11 is: "..node.heap())
    sendDataMessage()
    tmr.stop(0)
    print("heap9 is: "..node.heap())
    tmr.alarm(1,10000,1,
        function()
            print("updating Values")
            print("heap10 is: "..node.heap())
            ler()
            createDataMessage()
            printNodeData()
            print("heap12 is: "..node.heap())
            for mac,ip in pairs(wifi.ap.getclient()) do
                print(mac,ip)
            end
            if ip ~= nil  then
               print("Client Connected")
            else
               print("waiting...")
            end
            print("heap12 is: "..node.heap())
         end)
end)
