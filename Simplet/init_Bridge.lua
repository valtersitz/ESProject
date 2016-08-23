--Return Infos
print(node.info())

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
--Execute ESP_Bridge.lua
dofile("ESP_Bridge.lc")
file.close()
