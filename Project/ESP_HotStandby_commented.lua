--/****************************************************************************************************************************\
-- * ESP project "SimplESP" © Copyright
-- *
-- * This program is a software developped by Valentin Altersitz and Eduardo Ribeiro with the help of Vandir Junior as part of the GICS, UFPR R&D program directed by André Augusto Mariano.
-- * Contacts: valtersitz@enseirb-matmeca.fr or vandirfonseca.jr@gmail.com
-- * Additional information about licensing can be found at : mariano@eletrica.ufpr.br
--\*************************************************************************************************************************/


--Exact same file as ESP_Bridge 


SV1, SV2, SV3, SV4, COM = nil
TsetPoint="-273.15"
--myRequest="command"..0

timeout=0

dataFile="data1.txt"

--Data Files
function getDataFiles()
    dataFILES = {}
    sizedataFILES = {}
    listFile = file.list() 
    buffer = nil
    local minFile = 999999
    local lastFile 
    i = 0
    if buffer~= listFile then 
    buffer = listFile
    for k,v in pairs(listFile) do
        if string.find(k, "data") then 
           dataFILES[i] = k
           sizedataFILES[k] = v
           if sizedataFILES[k] < minFile then minFile = sizedataFILES[k]; dataFile=k end 
           i = i +1
        end
    end
    end
end


    

-- Server
function StartServer()
if srv then srv:close() srv=nil end
srv=net.createServer(net.TCP)

end



function createBuffer()
    buff = "<TD>"..SV1.."</TD><TD>"..SV2.."</TD><TD>"..SV3.."</TD><TD>"..SV4.."</TD><TD>"..COM.."</TD><TD>"..TsetPoint.."</TD><TD>"..TS.."</TD><TR></TABLE>" 
    if sizedataFILES[dataFILES[0]] then 
        for i = 0, #dataFILES do 
            buff=buff..'<li>  <a href="'..dataFILES[i]..'"> Download '..dataFILES[i]..' </a></li>'
        end
    end
    buff = buff.."</BODY></HTML>"
    return buff
end






function webInterface()


local httpRequest={}
httpRequest["/data1.txt"]="data1.txt";
httpRequest["/data2.txt"]="data2.txt";
httpRequest["/data3.txt"]="data3.txt";
httpRequest["/data4.txt"]="data4.txt";
httpRequest["/data5.txt"]="data5.txt";
httpRequest["/texte.txt"]="texte.txt";
httpRequest["/eraseData.html"]="eraseData.html";
httpRequest["/eraseSetPoints.html"]="eraseSetPoints.html";
httpRequest["/main.html"]="main.html";
httpRequest["/settings.html"]="settings.html";
httpRequest["/about.html"]="about.html";


local getContentType={};
getContentType["/data1.txt"]="text/txt";
getContentType["/data2.txt"]="text/txt";
getContentType["/data3.txt"]="text/txt";
getContentType["/data4.txt"]="text/txt";
getContentType["/data5.txt"]="text/txt";
getContentType["/data6.txt"]="text/txt";
getContentType["/texte.txt"]="text/txt";
getContentType["/eraseData.html"]="text/html";
getContentType["/eraseSetPoints.html"]="text/html";
getContentType["/main.html"]="text/html";
getContentType["/settings.html"]="text/html";
getContentType["/about.html"]="text/html";


local filePos = 0

srv:listen(80,function(conn)
    conn:on("receive", function(con,request)
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
                    local tsetPoint = formDATA[k]
                    if file.open("setPoints.txt", "w+") then
                        if file.writeline(tsetPoint) then
                            file.close()
                        else print("error writing the file")
                        end
                    else print("error opening the file")
                    end
                end
            end   
        end
    
        if getContentType[path] then
           requestFile=httpRequest[path];
           print("Sending file "..requestFile); 
           filePos=0
           con:send("HTTP/1.1 200 OK\r\nContent-Type: "..getContentType[path].."\r\n\r\n");
        else
           print("[File "..path.." not found]");
           con:send("HTTP/1.1 404 Not Found\r\n\r\n")
           con:close();
           collectgarbage();
        end
    end)
    conn:on("sent",function(con)
        if requestFile then
        if file.open(requestFile,"a+") then
           file.seek("set",filePos)
           local partial_data=file.read(617)
           file.close()
           if requestFile == "main.html" then partial_data=partial_data..createBuffer()  end
           if requestFile =="eraseData.html" then for i = 0, #dataFILES do file.remove(dataFILES[i]) end end
           if requestFile =="eraseSetPoints.html" then file.remove("setPoints.txt") end
           if partial_data then
              print(partial_data)
              print(#partial_data)
              filePos=filePos+#partial_data
              print("["..filePos.." bytes sent]")
              con:send(partial_data)
           end
           if (string.len(partial_data)==617) then
             return;
           end
        else
           print("[Error opening file"..requestFile.."]")
        end 
    end
   collectgarbage()
   print("[Connection closed]")   
   con:close()
   end)
end)
if path =="/eraseData" then file.remove("data.txt") end   
end

function sendingRequest()
    if file.open("setPoints.txt", "r") then
        TsetPoint=file.read()
        print("tsetpoint is ", TsetPoint)
        file.close()
    else print("no setPoint file")
         TsetPoint = "-273.15"
    end
    myRequest="command"
    if SV1 and (SV1 > TsetPoint) then 
        myRequest=myRequest..1
        if TsetPoint == "-273.15" then myRequest="command"..0 end
    else myRequest=myRequest..0 
    end -- if SV1 (temp) is greater than SetPoint, active command
    
    conn=net.createConnection(net.TCP, 0)
    local destPort = 30000 
    local ipa="192.168.0.1"
    print("connection to ESP_Sensors:")
    conn:on("connection", function(conn)
        print("connected to ESP_Sensors:")
        
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
    if sizedataFILES[dataFile] and (sizedataFILES[dataFile] > 80000) then 
        local dataFileNumber = string.match(dataFile, "%d")
        print("dataFileNumber ", dataFileNumber)
        dataFileNumber = tonumber(dataFileNumber) + 1
        dataFile="data"..dataFileNumber..".txt"
    end
        print("dataFile is ", dataFile)
    if file.open(dataFile, "a+") then
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
StartServer()
if wifi.sta.getip()~=nil then
    getDataFiles()
    sendingRequest()
    conn:send(myRequest)
end

tmr.alarm(0,300000,1, function() 
    if wifi.sta.getip()==nil then
       print("Wait for IP")
       timeout=timeout+1
       if timeout>10 then node.restart() end
    else
       getDataFiles()
       print("SV1 is ", SV1)
       sendingRequest()
       ipa,_,_=wifi.sta.getip()
       print("Sending Request...")
       conn:send(myRequest)    -- command value must be precised, otherwise command=0        
    end
    print("Heap is: "..node.heap())
end)

tmr.alarm(1,100,1, function()
    if (SV1 ~= nil and SV2 ~= nil and SV3 ~= nil and SV4 ~= nil and COM ~= nil) then 
        tmr.stop(1)
        webInterface()
    end
   
end)

