-- Open the file for writing
--file.open("init.lua","w")
-- Write a simple text message that will be echoed to the terminal
--file.writeline([[print("Some simple message")]])
-- Set the mode to SOFTAP
--file.writeline([[wifi.setmode(wifi.SOFTAP)]])
-- Get the new mode and print it
--file.writeline([[print("ESP8266 mode is: " .. wifi.getmode())]])
print("ESP8266 mode is: " .. wifi.getmode())
--Return Infos
print(node.info())
--Execute baro.lua
dofile("test01.lua")
file.close()
