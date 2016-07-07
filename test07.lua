--Range test between ESP 01 and 07 - 07 part
-- **************************************************************
cfg={}
cfg.ssid="ESP07"
--cfg.pwd=""
wifi.setmode(wifi.STATIONAP)
wifi.ap.config(cfg)

_,RID=node.bootreason()
ok  =0 --ESP01 question
question = "nothing"


-- read question
function Question()
    if ok == 1 then
        question = 'Communication succeeded'
    else question = 'no question'
    end
    print(question)
end
-- web server
function StartServer()
srv = net.createServer(net.TCP)
print("server crée, en attente du client")
srv:listen(30000, function (sck, pl)
            print(pl)
            print("je suis ici")
            sck:on("receive", function (sk,string)
                print(sk)
                print(string)
                if string == "ALLO" then ok=1
                else print("not the message expected")
                end
                sk:send("OK")
               -- sk:send(question)
            end)
            sck:on("sent", function(sck) print (sck) sck:close() end)
        end)
end

--main loop
tmr.alarm(0,1000,1,
    function()
            tmr.stop(0)
            print("Server start")
            StartServer()
            -- periodic reading of 07 and load buffer
            tmr.alarm(6,1000,1,
                function()
                    Question()
                    ipa,_,_=wifi.sta.getip()
                    print("Connected if IP ",ipa)
                end)
    end)
   
