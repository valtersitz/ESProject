
SV1, SV2, SV3, SV4, COM = nil
TsetPoint="-1"
--myRequest="command"..0

timeout=0

-- Server
function StartServer()


local httpRequest={}
httpRequest["/web.html"]="web.html";
httpRequest["/data.txt"]="data.txt";
httpRequest["/eraseData"]="data.txt";
httpRequest["/main.html"]="main.html";
httpRequest["/settings.html"]="settings.html";
httpRequest["/about.html"]="about.html";

httpRequest["/hi.php"]="hi.php";


local getContentType={};
getContentType["/web.html"]="text/html";
getContentType["/data.txt"]="text/txt";
getContentType["/eraseData"]="text/txt";
getContentType["/main.html"]="text/html";
getContentType["/settings.html"]="text/html";
getContentType["/about.html"]="text/html";


getContentType["/hi.php"]="script/html";

local filePos=0;

--[[tmr.alarm(1, 1000, 1, function() 
    if wifi.sta.getip() == nil then
        print("IP unavaiable, waiting...") 
    else 
        tmr.stop(1)
        print("Connected, IP is "..wifi.sta.getip());
    end 
end)]]

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
        formDATA = {}
        if (vars ~= nil)then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                print("["..k.."="..v.."]");
                formDATA[k] = v
                if k=='Tsetpoint'  then
                    TsetPoint = formDATA[k]
                end
            end   
        end
        if getContentType[path] then
           requestFile=httpRequest[path];
           print("Sending file "..requestFile);            
           filePos=0;
           conn:send("HTTP/1.1 200 OK\r\nContent-Type: "..getContentType[path].."\r\n\r\n");
           if path =="/eraseData" then file.remove("data.txt") end            
        else
           print("[File "..path.." not found]");
           conn:send("HTTP/1.1 404 Not Found\r\n\r\n")
           conn:close();
           collectgarbage();
        end
    end)
    conn:on("sent",function(conn)
        if requestFile then
            if file.open(requestFile,"a+") then
                file.seek("set",filePos);
                local partial_data=file.read(655);
                file.close();
                if requestFile == "main.html" then partial_data=partial_data.."<TD>"..SV1.."</TD><TD>"..SV2.."</TD><TD>"..SV3.."</TD><TD>"..SV4.."</TD><TD>"..COM.."</TD><TD>"..TsetPoint.."</TD><TD>"..TS.."</TD><TR></TABLE></BODY></HTML>" end
                if partial_data then
                    print(partial_data)
                    print(#partial_data)
                    filePos=filePos+#partial_data;
                    print("["..filePos.." bytes sent]");
                    conn:send(partial_data);
                    if (string.len(partial_data)==655) then
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



function sendingRequest(TsetPoint)
    local myRequest="command"
    if SV1 and (tonumber(SV1) > tonumber(TsetPoint)) then 
        myRequest=myRequest..1 
    else myRequest=myRequest..0 
    end -- if SV1 (temp) is greater than SetPoint, active command
    
    conn=net.createConnection(net.TCP, 0)
    local destPort = 30000 
    local ipa="192.168.0.1"
    print("connection to ESP_Sensors:")
    conn:on("connection", function(conn)
        print("connected to ESP_Sensors:")
        conn:send(myRequest)    -- command value must be precised, otherwise command=0        
        conn:on("sent", function(conn) print(myRequest) end)
        print("sent")
        
        collectgarbage()
    end)
    conn:on("receive", function(conn,string) 
        print("received is "..string)
        processMessage(string)
        collectgarbage()
    end)
    conn:on("disconnection", function(conn, string)
        print("Disconnected")
        conn:close()
    end)
    conn:connect(destPort,ipa) 
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
    local TSLoc = string.find(string,"Time")
    
    SV1 = string.sub(string, VS1Loc, VS2Loc-1)
    SV2 = string.sub(string, VS2Loc+1, VS3Loc-1)
    SV3 = string.sub(string, VS3Loc+1, VS4Loc-1)
    SV4 = string.sub(string, VS4Loc+1, COMMANDLoc-1)
    COM = string.sub(string, COMMANDLoc+1, COMMANDLoc+2)
    TS = string.sub(string, TSLoc+4, VS1Loc-6)
    
end


--main loop
tmr.alarm(0,30000,1, function() 
    if wifi.sta.getip()==nil then
       print("Wait for IP")
       timeout=timeout+1
       if timeout>10 then node.restart() end
    else
       ipa,_,_=wifi.sta.getip()
       print("IP is ",ipa)
       print("Sending Request...")
       sendingRequest(TsetPoint)
       if (SV1 ~= nil and SV2 ~= nil and SV3 ~= nil and SV4 ~= nil and COM ~= nil) then 
        --loadBuff()
        StartServer()
       else print("waiting for values...")
       end
    end
    print("Heap is: "..node.heap())
end)



