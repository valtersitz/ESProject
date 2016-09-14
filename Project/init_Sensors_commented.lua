--/****************************************************************************************************************************\
-- * ESP project "SimplESP" © Copyright
-- *
-- * This program is a software developped by Valentin Altersitz and Eduardo Ribeiro with the help of Vandir Junior as part of the GICS, UFPR R&D program directed by André Augusto Mariano.
-- * Contacts: valtersitz@enseirb-matmeca.fr or vandirfonseca.jr@gmail.com
-- * Additional information about licensing can be found at : mariano@eletrica.ufpr.br
--\*************************************************************************************************************************/

----- AP SET-UP -----
wifi.setmode(wifi.SOFTAP)    --turn on wifi as access point only (save some battery)




ap_ssid="ESP_Sensors"
--ap_pass="" --this module password
wifi_cfg={}
ip_cfg={ip="192.168.0.1"} --must be changed according to client's network
wifi_cfg.ssid=ap_ssid --3 next lines to config module access point 
--wifi_cfg.pwd="" --uncomment if you want a password
wifi.ap.config(wifi_cfg)
wifi.ap.setip(ip_cfg) -- ip adress of ap needs to be different than others ESPs' in order to have several ESP in server at the same time


valueSensor1 = nil -- tab to store sensor's values
valueSensor2 = nil 
valueSensor3 = nil
valueSensor4 = nil

ok = 0 -- check if calibartion is done


-------------------------Eduardo's-----------------------------------

print("heap1 is: "..node.heap())


pwm.setup(3,1000,1023)
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

ambiente, vermelho, verde, azul, leitura = 0,1,2,3,4
cor = 4
cont = 256
apro = 512
limite = 800
x, temp, cont_tempo = 0,0,0

led_cor = {}

------------------------------------------------------------
--                      Calibration
------------------------------------------------------------


function adc_ler(media,x)   
    while(x < 27)do
        media = media + adc.read(0)
        x = x + 1 
    end
        adc_valor = media/27
end


function calibra()
    print("inicio calibracao")
    gpio.write(5, gpio.LOW)
    gpio.write(6, gpio.HIGH)
    limite = 800
    cor = ambiente
    tmr.delay(1000000)

    if(cor==ambiente)then
       adc_ler(0,0)
       led_cor[ambiente] = adc_valor
       limite = limite + adc_valor
       print(limite)
       cor = vermelho
    end
    
    if(cor==vermelho)then
        gpio.write(1, gpio.LOW)
        gpio.write(2, gpio.LOW)
        gpio.write(4, gpio.HIGH)
        cont = 256
        apro = 512
        pwm.setduty(3, apro)
        j=0
        
          for i=0,9,1 do
              tmr.delay(300000)
              adc_ler(0,0)
              if(adc_valor > limite)then
                  apro = apro + cont
              elseif(adc_valor < limite)then
                  apro = apro - cont 
              end
              cont=cont/2
              pwm.setduty(3, apro)
              if(i==9)then
                  j=9
              end
          end
          if(j==9)then
              adc_ler(0,0)
              adc_vermelho = adc_valor - led_cor[ambiente]
              adc_vermelho = math.floor(adc_vermelho)
              print(adc_vermelho)
              led_cor[vermelho] = pwm.getduty(3)
              cor=verde
          end
    end
    
    if(cor==verde)then
        gpio.write(1, gpio.HIGH)
        gpio.write(2, gpio.LOW)
        gpio.write(4, gpio.LOW)
        cont = 256
        apro = 512
        pwm.setduty(3, apro)
        j=0

          for i=0,9,1 do
              tmr.delay(300000)
              adc_ler(0,0)
              if(adc_valor > limite)then
                  apro = apro + cont
              elseif(adc_valor < limite)then
                  apro = apro - cont 
              end
              cont=cont/2
              pwm.setduty(3, apro)
              if(i==9)then
                  j=9
              end
          end
          if(j==9)then
              adc_ler(0,0)
              adc_verde = adc_valor - led_cor[ambiente]
              adc_verde = math.floor(adc_verde)
              print(adc_verde)
              led_cor[verde] = pwm.getduty(3)
              cor=azul
          end
    end
     
     if(cor==azul)then
        gpio.write(1, gpio.LOW)
        gpio.write(2, gpio.HIGH)
        gpio.write(4, gpio.LOW)
        cont = 256
        apro = 512
        pwm.setduty(3, apro)
        j=0

          for i=0,9,1 do
              tmr.delay(300000)
              adc_ler(0,0)
              if(adc_valor > limite)then
                  apro = apro + cont
              elseif(adc_valor < limite)then
                  apro = apro - cont
              end
              cont=cont/2
              pwm.setduty(3, apro)
              if(i==9)then
                  j=9
              end
          end
          if(j==9)then
              adc_ler(0,0)
              adc_azul = adc_valor - led_cor[ambiente]
              adc_azul = math.floor(adc_azul)
              print(adc_azul)
              led_cor[azul] = pwm.getduty(3) 
              cor=leitura

              gpio.write(1, gpio.LOW)
              gpio.write(2, gpio.LOW)
              gpio.write(4, gpio.LOW)
              pwm.setduty(3, 1023)
          end
     end
     print("fim calibracao")
     if file.open("calibration.txt", "w+") then
        if file.writeline(led_cor[vermelho]) then
            if file.writeline(led_cor[verde]) then
                if file.writeline(led_cor[azul]) then
                    file.close()
                else print("error writing blue calib value")
                end
             else print("error writing green calib value")
             end
         else print("error writing red calib value")
         end
     else print("error opening the calibration file")
     end
     
end

----------------------------------------------------------------
--                      Starting Routine
----------------------------------------------------------------




if file.open("calibration.txt") then --a calibration file is created to keep the values of calibration in ROM memory in case of power off or reset
   file.close()
   tmr.delay(5000000) --5seconds to do a new calibration. Otherwise the previous calibration is used
   if(gpio.read(0) == 0)then
         -- Calibra��o
            tmr.delay(10000000)
            calibra()
            ok = ok + 1
   else 
       if file.open("calibration.txt", "r") then
            led_cor[vermelho] = file.readline()
            led_cor[verde] = file.readline()
            led_cor[azul] = file.readline()
            file.close()
        else print("can not open calibration file")
        end
   end
   dofile("ESP_Sensors.lc")
   file.close()
else
    print("Please Calibrate")
    while (ok==0) do
         tmr.delay(1000)
         if(gpio.read(0) == 0)then
             -- Calibra��o
                tmr.delay(10000000)
                calibra()
                ok = ok + 1
         end
    end
end 

dofile("ESP_Sensors.lc") --don't forget to compile the lua file
file.close()



