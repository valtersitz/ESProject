

function sendingMessage(nearestNode, myNodeString)



    conn=net.createConnection(net.TCP, 0) --security: , false)
    local destPort = 30000+nearestNode 
    print("destPort is "..destPort) 
    local ipa="192.168."..nearestNode..".1"
    print(ipa)
    conn:connect(30000,"192.168.0.1") 
    print("ici")
    conn:on("connection", function(conn)
        print("connection to nearest ESP:")
        print(myNodeString)
        conn:send(myNodeString)        
        conn:on("sent", function(conn) print(conn) end)
        collectgarbage()
        print("sent")
    end)
    print("here")
    conn:on("receive", function(conn,string) 
        print("received is "..string)
        if string == "OK" then
            print("The Message was successfully passed on")
        else print("An error occured during the communication")
        end
    end)
    nearestNode=nil
end




--dofile("test000.lua")
wifi.sta.connect()

print("connecting....")
ip = wifi.sta.getip()
print(ip)
if ip ~= nil then
tmr.alarm(5,5000,1, function()
sendingMessage(nearestNode, myNodeString)
end)
else print("fuck it")
end


