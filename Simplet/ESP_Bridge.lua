wifi.setmode(wifi.STATIONAP)    --turn on wifi

----- AP SET-UP -----

ap_ssid="ESP_Bridge"
--ap_pass="" --this module password
wifi_cfg={}
ip_cfg={ip="192.168.99.1"}
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
httpRequest["/main.html"]="main.html";
httpRequest["/settings.php"]="settings.php";
httpRequest["/about.html"]="about.html";
httpRequest["/values.html"]="main.html";
httpRequest["/hi.php"]="hi.php";
httpRequest["/form.html"]="form.php";


local getContentType={};
getContentType["/web.html"]="text/html";
getContentType["/data.txt"]="text/txt";
getContentType["/main.html"]="text/html";
getContentType["/settings.php"]="text/html";
getContentType["/about.html"]="text/html";
getContentType["/hi.php"]="text/html";
getContentType["/form.html"]="text/html";

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
--writing the string into data.txt
    if file.open("data.txt", "a+") then
        if file.writeline(string) then
            file.close()
        else print("error writing the file")
        end
    else print("error opening the file")
    end
--writing the variables into the web interface
    local VS1Loc = string.find(string,"Data")+4
    local VS2Loc = string.find(string,":", VS1Loc+1)
    local VS3Loc = string.find(string,":", VS2Loc+1)
    local VS4Loc = string.find(string,":", VS3Loc+1)
    local COMMANDLoc = string.find(string,":", VS4Loc+1)
    
    SV1 = string.sub(string, VS1Loc, VS2Loc-1)
    SV2 = string.sub(string, VS2Loc+1, VS3Loc-1)
    SV3 = string.sub(string, VS3Loc+1, VS4Loc-1)
    SV4 = string.sub(string, VS4Loc+1, COMMANDLoc-1)
    COM = string.sub(string, COMMANDLoc+1, COMMANDLoc+2)
    print(SV1.."."..SV2.."."..SV3.."."..SV4.."."..COM)
    --[[if file.open("main.html", "a+") then
        local SV1Loc = 465
        local SV2Loc = SV1Loc + #SV1
        local SV3Loc = SV2Loc + #SV2
        local SV4Loc = SV3Loc + #SV3
        local COMLoc = SV4Loc + #SV4
        if file.seek("set", SV1Loc) then
            print(file.readline())
            if file.write(SV1) then
                print("successfully written SV1")
            else print("error writing SV1")
            end
        end
        if file.seek("set", SV2Loc) then
            print(file.readline())
            if file.write(SV2) then
                print("successfully written SV2")
            else print("error writing SV2")
            end
        end
        if file.seek("set", SV3Loc) then
            print(file.readline())
            if file.write(SV3) then
                print("successfully written SV3")
            else print("error writing SV3")
            end
        end
        if file.seek("set", SV4Loc) then
            print(file.readline())
            if file.write(SV4) then
                print("successfully written SV4")
                file.close()
            else print("error writing SV4")
            end
        end
        if file.seek("set", COMLoc) then
            if file.writeline(COM) then
                file.close()
            else print("error writing COM")
            end
        end
    else print("error opening the file")
    end]]
end

function loadBuff()
buff = '<!DOCTYPE HTML><html><head><meta charset="UTF-8"><meta http-equiv="refresh" content="10">\
<HEAD><TITLE>ESP8266 - Main</TITLE></HEAD><BODY><CENTER><FONT COLOR=BLUE SIZE=6>ESP8266 - Main</FONT></CENTER>\
<BR><TABLE><TR><TD WIDTH=100> <li> Main </li> </TD>\
<TD WIDTH=100> <li><a href="settings.html">Settings</a></li> </TD><TD WIDTH=100> <li><a href="about.html">About</a></li> </TD>\
</TR></TABLE><BR><TABLE BORDER=1><TR><TD></TD><TD>Temperature</TD><TD>Red</TD><TD>Blue</TD><TD>Green</TD></TR><TR>\
<TD>ESP01</TD><TD>'..SV1..'</TD><TD>'..SV2..'</TD><TD>'..SV3..'</TD><TD>'..SV4..'</TD><TR>\
<TD>ESP02</TD><TD></TD><TD></TD><TD></TD><TD></TD></TABLE>\
Last update: 3:54 PM, 03/08/16\
<li><a href="data.txt">Download</a></li></BODY></HTML>'

if file.open("main.html", "w") then
        if file.writeline(buff) then
            file.close()
        else print("error writing main")
        end
    else print("error opening main")
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
       sendingRequest()
       if (SV1 ~= nil and SV2 ~= nil and SV3 ~= nil and SV4 ~= nil and COM ~= nil) then 
        loadBuff()
        StartServer()
       else print("waiting for values...")
       end
    end
end)
