wifi.setmode(wifi.STATIONAP)    --turn on wifi

----- AP SET-UP -----

ap_ssid="ESP_Bridge"
--ap_pass="" --this module password
wifi_cfg={}
ip_cfg={ip="192.168.1.1"}
wifi_cfg.ssid=ap_ssid --3 next lines to config module access point 
--wifi_cfg.pwd="" --uncomment if you want a password
wifi.ap.config(wifi_cfg)
wifi.ap.setip(ip_cfg) -- ip adress of ap needs to be different than others ESPs' in order to have several ESP in server at the same time


---- STA SET-UP -----

sta_ssid ="ESP_Sensors" -- your router SSID you want to connect to
sta_pass = "" -- your router password you want to connect to
wifi.sta.config(sta_ssid, sta_pass) --config to connect to wifi station
wifi.sta.connect()

-- Server
function StartServer()


local httpRequest={}
httpRequest["/web.html"]="web.html";
httpRequest["/data.txt"]="data.txt";

local getContentType={};
getContentType["/web.html"]="text/html";
getContentType["/data.txt"]="text/html";

local filePos=0;

tmr.alarm(1, 1000, 1, function() 
    if wifi.sta.getip() == nil then
        print("IP unavaiable, waiting...") 
    else 
        tmr.stop(1)
        print("Connected, IP is "..wifi.sta.getip());
    end 
end)

if srv then srv:close() srv=nil end
srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
    conn:on("receive", function(conn,request)
        print("New Request");
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil)then
         _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
         print("path is "..path)
         print("method is "..method)
        end
        local formDATA = {}
        if (vars ~= nil)then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                print("["..k.."="..v.."]");
                formDATA[k] = v
            end   
        end
        if getContentType[path] then
            requestFile=httpRequest[path];
            print("Sending file "..requestFile);            
            filePos=0;
            conn:send("HTTP/1.1 200 OK\r\nContent-Type: "..getContentType[path].."\r\n\r\n");            
        else
            print("[File "..path.." not found]");
            conn:send("HTTP/1.1 404 Not Found\r\n\r\n")
            conn:close();
            collectgarbage();
        end
    end)
    conn:on("sent",function(conn)
        if requestFile then
            if file.open(requestFile,r) then
                file.seek("set",filePos);
                local partial_data=file.read(512);
                file.close();
                if partial_data then
                    filePos=filePos+#partial_data;
                    print("["..filePos.." bytes sent]");
                    conn:send(partial_data);
                    if (string.len(partial_data)==512) then
                        return;
                    end
                   
                end
            else
                print("[Error opening file"..requestFile.."]");
            end
        end
        print("[Connection closed]");
        conn:close();
        collectgarbage();
    end)
end)
end

myRequest="command"..1 --for the test
function sendingRequest()
    conn=net.createConnection(net.TCP, 0)
    local destPort = 30000 
    local ipa="192.168.0.1"
    conn:connect(destPort,ipa) 
    conn:on("connection", function(conn)
        print("connection to ESP_Sensors:")
        conn:send(myRequest)    -- command value must be precised, otherwise command=0        
        conn:on("sent", function(conn) print(myRequest) end)
        print("sent")
    end)
    conn:on("receive", function(conn,string) 
        print("received is "..string)
        processMessage(string)
    end)
end

function processMessage(string)
    if file.open("data.txt", "a+") then
        if file.writeline(string) then
            file.close()
        else print("error writing the file")
        end
    else print("error opening the file")
    end
end




--main loop
tmr.alarm(0,30000,1, function() 
    if wifi.sta.getip()==nil then
       print("Wait for IP")
    else
       ipa,_,_=wifi.sta.getip()
       print("IP is ",ipa)
       print("Sending Request...")
       StartServer()
       sendingRequest()
    end
end)
