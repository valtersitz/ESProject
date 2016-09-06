--Return Infos
print(node.info())

wifi.setmode(wifi.STATIONAP)    --turn on wifi

----- AP SET-UP -----

ap_ssid="ESP_HotStandBy"
--ap_pass="" --this module password
wifi_cfg={}
ip_cfg={ip="192.168.98.1"}
wifi_cfg.ssid=ap_ssid --3 next lines to config module access point 
--wifi_cfg.pwd="" --uncomment if you want a password


---- STA SET-UP -----


sta_ssid ="ESP_Sensors" -- your router SSID you want to connect to
sta_pass = "" -- your router password you want to connect to
wifi.sta.config(sta_ssid, sta_pass) --config to connect to wifi station


function listap(t)
    for bssid,v in pairs(t) do
        local ssid, rssi, authmode, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]*)")
        --print(string.format("%32s",ssid).."\t"..bssid.."\t  "..rssi.."\t\t"..authmode.."\t\t\t"..channel)
        if (string.find(ssid,"ESP_Bridge")) then --if AP starting with "ESP", get the node number
           return 0
        end
     end
     return 1 --if "ESP_Bridge" is not found we dofile  
end

tmr.alarm(0,3600000,1, function()
    wifi.sta.getap(1, listap)
    if listap(t) then 
            wifi.ap.config(wifi_cfg)
            wifi.ap.setip(ip_cfg) -- ip adress of ap needs to be different than others ESPs' in order to have several ESP in server at the same time
            wifi.sta.connect()
            --Execute ESP_Bridge.lua
            dofile("ESP_HotStandby.lc")
            file.close()
     else node.dsleep(3598000000) --sleeping for an hour - 2s
     end
end)