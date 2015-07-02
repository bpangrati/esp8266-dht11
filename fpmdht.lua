--    Demo http server for sensors DHT11/22
--    Tested with Lua NodeMCU 0.9.5 build 20150127 floating point !!!
-- 1. Flash Lua NodeMCU to ESP module.
-- 2. Set in program fpmdht.lua sensor type. This is parameter typeSensor="dht11" or "dht22".
-- 3. You can rename the program fpmdht.lua to init.lua
-- 4. Load program fpmdht.lua and dht.lua to ESP8266 with LuaLoader
-- 5. HW reset module
-- 6. Login module to your AP - wifi.setmode(wifi.STATION),wifi.sta.config("yourSSID","yourPASSWORD")
-- 7. Run program fpmdht.lua - dofile(fpmdht.lua)
-- 8. Test IP address - wifi.sta.getip()
-- 9. Test it with your browser and true IP address of module.
--10. The sensor is repeatedly read every minute.
--11. The pictures on page are external.
--12. The length of html code is limited to 1460 characters including header.
--    The author of the program module dht.lua for reading DHT sensor is Javier Yanez
					--*******************************
sensorType="dht11" 	-- set sensor type dht11 or dht22
					--*******************************
	humi="XX"
	temp="XX"
	fare="XX"
	count=1
	PIN = 1 --  data pin, GPIO5
-- GPIO0= 3  GPIO2= 4 GPIO5= 1
--load DHT module and read sensor

function ReadDHT()
	dht=require("dht22")

	dht.read(PIN)
     c = 0
     while (dht.getHumidity() == nil and c < 10) do
          print("Error reading from DHT. retry "..c)
          c = c + 1
          tmr.delay(10000000) -- 10 seconds
          dht.read(PIN)
     end

     if (c == 10) then
          printf("Cannot read from DHT 10 times. Sleep time")
     else
     	if sensorType=="dht11"then
     	     humi=dht.getHumidity()/256
	          temp=dht.getTemperature()/256
	     else
     	humi=dht.getHumidity()/10
	     temp=dht.getTemperature()/10
     	end
	     fare=(temp*9/5+32)
	     print("Humidity:    "..humi.."%")
	     print("Temperature: "..temp.." deg C")
	     print("Temperature: "..fare.." deg F")
	     -- release module
	     dht=nil
	     package.loaded["dht"]=nil
     end
end

function updateData()
print("Sending data to thingspeak.com "..thingspeak_key)
conn=net.createConnection(net.TCP, 0) 
conn:on("receive", function(conn, payload) print(payload) end)
-- api.thingspeak.com 184.106.153.149
conn:connect(80,'184.106.153.149')
conn:send("GET /update?key="..thingspeak_key.."&field1="..temp.."&field2="..humi.." HTTP/1.1\r\n")
conn:send("Host: api.thingspeak.com\r\n") 
conn:send("Accept: */*\r\n") 
conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
conn:send("\r\n")
conn:on("sent",function(conn)
                      print("Closing connection")
                      conn:close()
                      node.dsleep(300000000) -- 300seconds or 5 minutes
                      --attempt to make this ESP-01 compatible
                      --wifi.sleeptype(wifi.LIGHT_SLEEP)
                      --tmr.delay(300000000) -- 300seconds or 5 minutes
                      --wifi.sleeptype(wifi.NONE_SLEEP)
                  end)
conn:on("disconnection", function(conn)
                      print("Got disconnection...")
end)
end

tmr.alarm(1,5000,1,function()ReadDHT() updateData() count=count+1 if count==5 then count=0 wifi.sta.connect()print("Reconnect")end end)
