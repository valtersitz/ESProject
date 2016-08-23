wifi.setmode(wifi.SOFTAP)    --turn on wifi

------------ Sensors Variables ----- 

pwm.setup(3,500,1023)
pwm.start(3)
pwm.setduty(3,1023)

gpio.mode(1, gpio.OUTPUT)
gpio.mode(2, gpio.OUTPUT)
gpio.mode(4, gpio.OUTPUT)
gpio.mode(5, gpio.OUTPUT)
gpio.mode(6, gpio.OUTPUT)
gpio.write(1, gpio.LOW)
gpio.write(2, gpio.LOW)
gpio.write(4, gpio.LOW)
gpio.write(5, gpio.LOW)
gpio.write(6, gpio.HIGH)

gpio.mode(0, gpio.INPUT, gpio.PULLUP)

ambiente, vermelho, verde, azul = 0,1,2,3
cor = 4
cont = 512
apro = 512
limite = 800
x, ok = 0,0

led_cor = {}

-------------------------------------------- 

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
  myString = myString..valueSensor1..":"..valueSensor2..":"..valueSensor3..":"..valueSensor4..":"..command
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


function adc_ler(media,x)   
    while(x < 833)do
        media = media + adc.read(0)
        tmr.delay(10)
        x = x + 1 
    end
    adc_valor = media/833
end

function updateMyValues()
    adc_ler(0,0)
    
    if(cor==ambiente)then
       limite = limite + adc_valor
       print("limite is "..limite)
       cor = vermelho
    end

    if(cor==vermelho)then
        gpio.write(1, gpio.LOW)
        gpio.write(2, gpio.LOW)
        gpio.write(4, gpio.HIGH)

        print("adc_valor red is "..adc_valor)
        if(adc_valor > limite and adc_valor < (limite+5))then
                 led_cor[vermelho] = pwm.getduty(3)
                 cor = verde
                 cont = 512
                 apro = 512
                 adc_valor = 0
                 pwm.setduty(3,1023)   
        elseif(adc_valor < limite)then
                 apro = apro - cont
                    if(apro == 0)then
                        apro = 512
                    end
                 pwm.setduty(3, apro)
                 cont = cont/2
        elseif(adc_valor > (limite+5))then
                 apro = apro + cont
                    if(apro == 1024)then
                        apro = 512
                    end
                 pwm.setduty(3, apro)
                 cont = cont/2
        end
    end
    
    if(cor==verde)then
        gpio.write(1, gpio.HIGH)
        gpio.write(2, gpio.LOW)
        gpio.write(4, gpio.LOW)

        print("adc_valor green is "..adc_valor)
        if(adc_valor > limite and adc_valor < (limite+5))then
                 led_cor[verde] = pwm.getduty(3)
                 cor = azul
                 cont = 512
                 apro = 512
                 adc_valor = 0
                 pwm.setduty(3,1023)   
        elseif(adc_valor < limite)then
                 apro = apro - cont
                    if(apro == 0)then
                        apro = 512
                    end
                 pwm.setduty(3, apro)
                 cont = cont/2
        elseif(adc_valor > (limite+5))then
                 apro = apro + cont
                    if(apro == 1024)then
                        apro = 512
                    end
                 pwm.setduty(3, apro)
                 cont = cont/2
        end
     end
     
     if(cor==azul)then
        gpio.write(1, gpio.LOW)
        gpio.write(2, gpio.HIGH)
        gpio.write(4, gpio.LOW)

        print("adc_valor blue is "..adc_valor)
        if(adc_valor > limite and adc_valor < (limite+5))then
                 led_cor[azul] = pwm.getduty(3)
                 cor = 4
                 cont = 512
                 apro = 512
                 adc_valor = 0
                 pwm.setduty(3,1023)   
        elseif(adc_valor < limite)then
                 apro = apro - cont
                    if(apro == 0)then
                        apro = 512
                    end
                 pwm.setduty(3,apro)
                 cont = cont/2
        elseif(adc_valor > (limite+5))then
                 apro = apro + cont
                    if(apro == 1023)then
                        apro = 512
                    end
                 pwm.setduty(3,apro)
                 cont = cont/2
        end
     end
     
     if(cor==4)then
        if(gpio.read(0) == 0)then
             if(ok==1)then
             -- Leitura de concentracao
                gpio.write(5, gpio.LOW)
                gpio.write(6, gpio.HIGH)

                adc_ler(0,0)
                led_cor[ambiente] = adc_valor
             
                gpio.write(1, gpio.LOW)
                gpio.write(2, gpio.LOW)
                gpio.write(4, gpio.HIGH)
                pwm.setduty(3, led_cor[vermelho])
                tmr.delay(10)
                adc_ler(0,0)
                adc_valor = adc_valor - led_cor[ambiente]
                print("adc_valor red is now "..adc_valor)
                valueSensor1=adc_valor
                
                gpio.write(1, gpio.HIGH)
                gpio.write(2, gpio.LOW)
                gpio.write(4, gpio.LOW)
                pwm.setduty(3, led_cor[verde])
                tmr.delay(10)
                adc_ler(0,0)
                adc_valor = adc_valor - led_cor[ambiente]
                print("adc_valor green is now "..adc_valor)
                valueSensor2 = adc_valor

                gpio.write(1, gpio.LOW)
                gpio.write(2, gpio.HIGH)
                gpio.write(4, gpio.LOW)
                pwm.setduty(3, led_cor[azul])
                tmr.delay(10)
                adc_ler(0,0)
                adc_valor = adc_valor - led_cor[ambiente]
                print("adc_valor blue is now "..adc_valor)
                valueSensor3 = adc_valor

                gpio.write(1, gpio.LOW)
                gpio.write(2, gpio.LOW)
                gpio.write(4, gpio.LOW)
                pwm.setduty(3, 1023)

             -- Leitura de temperatura
                gpio.write(5, gpio.HIGH)
                gpio.write(6, gpio.LOW)
            
                gpio.write(1, gpio.LOW)
                gpio.write(2, gpio.LOW)
                gpio.write(4, gpio.HIGH)
                pwm.setduty(3, 0)        
                tmr.delay(10)

                adc_ler(0,0)
                print("adc_valor Temp is now "..adc_valor)  
                valueSensor4 = adc_valor 
            end
            
            if(ok==0)then
             -- Calibracao
                gpio.write(5, gpio.LOW)
                gpio.write(6, gpio.HIGH)
                limite = 800
                cor = ambiente
                ok = ok + 1
            end
        end
     end
end


function printNodeData() 
  print("SV1 red is "..valueSensor1)
  print("SV2 green is "..valueSensor2)
  print("SV3 blue is "..valueSensor3)
  print("SV4 temp is "..valueSensor4)
  print(command)
end  
    




--main loop
tmr.alarm(0,10000,1, function() 
    print("Uploading data...")
    -- while the sensors are not ready we won't update the values
    while (valueSensor1 == nil or valueSensor2 == nil or valueSensor3 == nil or valueSensor4 == nil) do 
        --updateMyValues()
        valueSensor1 = 785642
        valueSensor2 = 79862
        valueSensor3 = 788652
        valueSensor4 = 775852
    end
    printNodeData()
    createDataMessage()
    tmr.stop(0)
    print("Server start")
    StartServer()
    tmr.alarm(1,8000,1,
        function()
            --updateMyValues()
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
