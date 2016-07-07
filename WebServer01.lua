--Range test between ESP 01 and 07
-- ******* WiFi configurations
sta_ssid ="ESP07" -- your router SSID you want to connect to
sta_pass = "" -- your router password you want to connect to
ap_ssid="ESP01" --this module ssid
ap_pass="" --this module password

wifi_cfg={}
ip_cfg={ip="192.168.2.1"}

wifi.setmode(wifi.STATIONAP)

wifi_cfg.ssid=ap_ssid --3 next lines to config module access point 
--wifi_cfg.pwd="" --uncomment if you want a password
wifi.ap.config(wifi_cfg)
wifi.ap.setip(ip_cfg) -- ip adress of ap needs to be different than others ESPs' in order to have several ESP in server at the same time

wifi.sta.config(sta_ssid, sta_pass) --config to connect to wifi station
wifi.sta.connect()

-- **************************************************************
_,RID=node.bootreason()

-- ******* Variables
myheap=0
cpt =0 --counter
ok  =0 --ESP07 answer
ans = "nothing"
pl2 = "je n y suis pas encore "

-- ******* Code

-- web page 
function LoadBuff()
local buff2 = '<!DOCTYPE HTML><html><head><meta charset="UTF-8"><meta http-equiv="refresh" content="10">\
<title>ESP Range test</title></head><body style="background:skyblue">\
Hi! This is a first Test to create a server using ESP8266! ESP 01 speaking. I am connected to an ESP 07 and pinging it every second. IPA:  Answer: '..ans..' Time(s:) '..cpt..'</body></html>'
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
-- seconds counter
function Counter()
    print("Counter :",cpt)
    cpt=cpt+1 
end
-- read answer
function Answer()
    if ok == 1 then
        ans = 'coucou toi'
    else ans = 'no answer... pourquoiiii tu marchesss paasss?'
    end
end
-- web server
function StartServer()
srv = net.createServer(net.TCP) --, 120) --120 = timeout
srv:listen(80, function (conn)
            conn:on("receive",
            function (sk, str)
                print(str)
                page = string.sub(str,5,10) 
                print(page)
                if page == "/page1" then 
                page1(sk)
                else 
                --print(str)
                sk:send(buff1)
                end
                collectgarbage()
            end)
            conn:on("sent", function(sk) sk:close() end)
            end)
end

--page1 du server 01
function page1(sk)
sk:send(buff3)
end


--Ping the ESP 07
function Pinging07()
conn=net.createConnection(net.TCP, 0) --security: , false)
conn:connect(30000,"192.168.4.1") 
print("je suis ici")
conn:on("connection", function(conn)
    print("connection to ESP07:")
    conn:send("ALLO")
    conn:on("sent", function(conn) print(conn) end)
end)
conn:on("receive", function(conn,string) 
    print(string)
    --print(conn)
    if string == "OK" then
        ok =1 
    else ok=0
    end
    print(ok)
    end)
end



--main loop
tmr.alarm(0,1000,1,
    function()
        if wifi.sta.getip()==nil
            then
            print("Wait for IP")
            else
            ipa,_,_=wifi.sta.getip()
            print("IP is ",ipa)
            tmr.stop(0)
            LoadBuff()
            print("Server start")
            StartServer()
            --Pinging07()
            -- periodic reading of 07 and load buffer
            tmr.alarm(6,1000,1,
                function()
                    LoadBuff()
                    Pinging07()
                    Answer()
                    Counter()
                    ok=0
                    string=nil
                end)
        end
end)
         
