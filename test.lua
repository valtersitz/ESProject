
--Barometer Glass & Brass V1.2 with three hourly trend pressure
-- **************************************************************
ssid = "EMJEL" -- your router SSID
pass = "zazarainhadodeserto42" -- your router password

-- **************************************************************
wifi.setmode(wifi.STATION)
wifi.sta.config(ssid, pass,1)
sec = 0 
con = "not connected yet"

-- web page - barometer face with included parameters
function LoadBuff()
local buff2 = '<!DOCTYPE HTML><html><head><meta charset="UTF-8"><meta http-equiv="refresh" content="1">\
<title>ESP TEST</title></head><body style="background:skyblue">\
Range Test ESP Seconds: '..sec..' Connection '..con..'</body></html>'
lenght= #buff2
buff1 = 'HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n'..
'Content-Length: '.. lenght ..'\r\n'..
'Cache-Control: max-age=120\r\n'..
'Connection: Keep-Alive\r\n\r\n'..buff2
buff2=nil
collectgarbage()
end

-- web server
function StartServer()
srv = net.createServer(net.TCP)
srv:listen(80, function (conn)
            conn:on("receive",
            function (client, request)
                if string.find(request, "GET / HTTP/1.1") ~= nil then
                    client:send(buff1)
                    con = "connected"
                    collectgarbage()
                    else
                    client:send('HTTP/1.1 404 Not found\r\n'..
                    'Content-Type: text/html\r\n'..
                    'Content-Length: 25\r\n'..
                    'Connection: close\r\n\r\n'..
                    '<h1>Page not found !</h1>')
                    con = "connectioon error"
                    client:close()
                end
            end)
        end)
end

function Counter()
    print("Counter :",sec)
    sec=sec+1 
end
-- main loop
tmr.alarm(0,1000,1,
    function()
        if wifi.sta.getip()==nil
            then
            print("Wait for IP")
            else
            tmr.stop(0)
            print("Server start")
            StartServer()
            -- periodic reading of sensors and load buffer
            tmr.alarm(1,1000,1,
                function()
                    print("Connection:", con)
                    ipa,_,_=wifi.sta.getip()
                    print("IP is ",ipa)
                    Counter()
                    LoadBuff()
                end)
            
        end
    end)
