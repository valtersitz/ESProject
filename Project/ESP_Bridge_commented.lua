
--/****************************************************************************************************************************\
-- * ESP project "SimplESP" © Copyright
-- *
-- * This program is a software developped by Valentin Altersitz and Eduardo Ribeiro with the help of Vandir Junior as part of the GICS, UFPR R&D program directed by André Augusto Mariano.
-- * Contacts: valtersitz@enseirb-matmeca.fr or vandirfonseca.jr@gmail.com
-- * Additional information about licensing can be found at : mariano@eletrica.ufpr.br
--\*************************************************************************************************************************/

SAMPLE_TIME = 30000 --main loop time in seconds
SV1, SV2, SV3, SV4, COM = nil
TsetPoint="-273.15"
--myRequest="command"..0

timeout=0

dataFile="data1.txt" --by default we write in data1.txt

--Data Files
function getDataFiles() --function to know in which data.txt file we should write
    dataFILES = {} --store the list of data files
    sizedataFILES = {} --store their size
    listFile = file.list()  --scan the ROM to find the files
    buffer = nil
    local minFile = 999999
    local lastFile 
    i = 0
    if buffer~= listFile then 
    buffer = listFile
    for k,v in pairs(listFile) do
        if string.find(k, "data") then --all the files with "data" in their name are stored
           dataFILES[i] = k
           sizedataFILES[k] = v
           if sizedataFILES[k] < minFile then minFile = sizedataFILES[k]; dataFile=k end --the file with the smallest size is chosen
           i = i +1
        end
    end
    end
end


    

-- Server
function StartServer() -- to deal with the asynchronousity of the protocol 
if srv then srv:close() srv=nil end
srv=net.createServer(net.TCP)

end



function createBuffer() --this buffer is going to be added to main.html file to make the interface dynamic: we add the values and the data files available to download
    buff = "<TD>"..SV1.."</TD><TD>"..SV2.."</TD><TD>"..SV3.."</TD><TD>"..SV4.."</TD><TD>"..COM.."</TD><TD>"..TsetPoint.."</TD><TD>"..TS.."</TD><TR></TABLE>" 
    if sizedataFILES[dataFILES[0]] then 
        for i = 0, #dataFILES do 
            buff=buff..'<li>  <a href="'..dataFILES[i]..'"> Download '..dataFILES[i]..' </a></li>'
        end
    end
    buff = buff.."</BODY></HTML>"
    return buff
end






function webInterface() --


local httpRequest={}
httpRequest["/data1.txt"]="data1.txt";
httpRequest["/data2.txt"]="data2.txt";
httpRequest["/data3.txt"]="data3.txt";
httpRequest["/data4.txt"]="data4.txt";
httpRequest["/data5.txt"]="data5.txt";
httpRequest["/data6.txt"]="data6.txt";
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
getContentType["/eraseData.html"]="text/html";
getContentType["/eraseSetPoints.html"]="text/html";
getContentType["/main.html"]="text/html";
getContentType["/settings.html"]="text/html";
getContentType["/about.html"]="text/html";


local filePos = 0 -- use to limit the payload

srv:listen(80,function(conn)
    conn:on("receive", function(con,request)
        print("New Request")
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP") -- get the orders from the web browser and store them
        if(method == nil)then
         _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP")
         print("path is "..path)
         print("method is "..method)
        end
        formDATA = {}
        if (vars ~= nil)then --if we talk to the ESP from the web interface
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                print("["..k.."="..v.."]")
                formDATA[k] = v
                if k=='Tsetpoint'  then
                    local tsetPoint = formDATA[k]
                    if file.open("setPoints.txt", "w+") then --if the user requires a setpoint (only temperature for now), we write it in a txt file to keep it in the ROM memory. Otherwise the setpoint will be lost at reset or when browsing the interface
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
           requestFile=httpRequest[path]
           print("Sending file "..requestFile)
           filePos=0
           con:send("HTTP/1.1 200 OK\r\nContent-Type: "..getContentType[path].."\r\n\r\n") --talking to web browser 
        else
           print("[File "..path.." not found]");
           con:send("HTTP/1.1 404 Not Found\r\n\r\n")
           con:close();
           collectgarbage();
        end
    end)
    conn:on("sent",function(con) -- sending the files
        if requestFile then
        if file.open(requestFile,"a+") then
           file.seek("set",filePos)
           local partial_data=file.read(617) --we read 617 bytes of the file in a buffer. THE NUMBER OF BYTES MUST BE THE SIZE OF THE MAIN.HTML FILE
           file.close()
           if requestFile == "main.html" then partial_data=partial_data..createBuffer()  end --if main is requested we add the values
           if requestFile =="eraseData.html" then for i = 0, #dataFILES do file.remove(dataFILES[i]) end end -- if erase we erase 
           if requestFile =="eraseSetPoints.html" then file.remove("setPoints.txt") end
           if partial_data then
              print(partial_data)
              print(#partial_data)
              filePos=filePos+#partial_data -- we are then going to continue reading from where we stopped
              print("["..filePos.." bytes sent]")
              con:send(partial_data) --we send the buffer
           end
           if (string.len(partial_data)==617) then
             return 
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
end

function sendingRequest() --message we send to the ESP to ask for data and order the command
    if file.open("setPoints.txt", "r") then --if we have setpoints in memory we send them
        TsetPoint=file.read()
        print("tsetpoint is ", TsetPoint)
        file.close()
    else print("no setPoint file")
         TsetPoint = "-273.15" --this is a default value meaning no setpoint was asked
    end
    myRequest="command"
    if SV1 and (SV1 > TsetPoint) then  -- if temperature is greater than set point, we activate the command. I DECIDED TO USE THIS CONDITION ON TEMPERATURE. THIS HAS TO /CAN BE CHANGED ACCORDING TO THE CLIENT NEEDS
        myRequest=myRequest..1
        if TsetPoint == "-273.15" then myRequest="command"..0 end
    else myRequest=myRequest..0 
    end -- if SV1 (temp) is greater than SetPoint, active command
    
    conn=net.createConnection(net.TCP, 0) --sending the request
    local destPort = 30000 
    local ipa="192.168.0.1" --if you change the Sensors'ip please change it here too (same for port)
    print("connection to ESP_Sensors:")
    conn:on("connection", function(conn)
        print("connected to ESP_Sensors:")
        
        conn:on("sent", function(conn) print(myRequest) end)
        print("sent")
        
        collectgarbage()
    end)
    conn:on("receive", function(conn,string) 
        print("received is "..string)
        processMessage(string) --once we received the answer we decrypt it
        collectgarbage()
    end)
    conn:on("disconnection", function(conn, string)
        print("Disconnected")
        conn:close()
    end)
    conn:connect(destPort,ipa) --because of asynchronousity
end

function processMessage(string) --decrypting the Sensors message and saving it into memory
--writing the string into data.txt
    if sizedataFILES[dataFile] and (sizedataFILES[dataFile] > 80000) then --if the data.txt file is bigger than 80kB we create a new one and write into it
        local dataFileNumber = string.match(dataFile, "%d")
        print("dataFileNumber ", dataFileNumber)
        dataFileNumber = tonumber(dataFileNumber) + 1
        dataFile="data"..dataFileNumber..".txt"
    end
        print("dataFile is ", dataFile)
    if file.open(dataFile, "a+") then
        if file.writeline(string) then --writing in data file
            file.close()
        else print("error writing the file")
        end
    else print("error opening the file")
    end

-- decrypting the message and storing values into variables

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
StartServer() --first time outside the loop to allow web interface asap (not successfull every time because of asynchronousity)
if wifi.sta.getip()~=nil then
    getDataFiles()
    sendingRequest()
    conn:send(myRequest)
end

tmr.alarm(0,SAMPLE_TIME,1, function() --if the Bridge doesn't get answer from Sensors for 3 times, a reset is done (it happens that the module doesn't work on first start)
    if wifi.sta.getip()==nil then
       print("Wait for IP")
       timeout=timeout+1
       if timeout>3 then node.restart() end
    else
       getDataFiles()
       print("SV1 is ", SV1) --is different than nil it means the interface can be printed
       sendingRequest()
       ipa,_,_=wifi.sta.getip()
       print("Sending Request...")
       conn:send(myRequest)    -- command value must be precised, otherwise command=0        
    end
    print("Heap is: "..node.heap())
end)

tmr.alarm(1,100,1, function() --fast sampling time to make it fast and available anytime
    if (SV1 ~= nil and SV2 ~= nil and SV3 ~= nil and SV4 ~= nil and COM ~= nil) then --once we have the data we can add the values to the main file and use the web interface
        tmr.stop(1)
        webInterface()
    end
   
end)

