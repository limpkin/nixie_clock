--nixie_clock.lua
-- PWM ADDRs for SEGMENTS:
--	   8
--	  --
-- 6 |	| 9
--	  --  5
-- 4 |	| 2
--	  --  . 7
--	  3
-- minus starting addr (2):
--	   6
--	  --
-- 4 |	| 7
--	  --  3
-- 2 |	| 0
--	  --  . 5
--	  1

-- Below: for each number (0->9) a boolean array specifying if we should set a non zero value into the pwm register, following the PCA9624 pwm register order
number_to_reg_val = {{1,1,1,0,1,0,1,1},{1,0,0,0,0,0,0,1},{0,1,1,1,0,0,1,1},{1,1,0,1,0,0,1,1},{1,0,0,1,1,0,0,1},{1,1,0,1,1,0,1,0},{1,1,1,1,1,0,1,0},{1,0,0,0,0,0,1,1},{1,1,1,1,1,0,1,1},{1,1,0,1,1,0,1,1}}
digit_addresses = {0x08, 0x09, 0x0a, 0x0b}
displayed_digits = {0, 0, 0, 0}
start_digit_reg_addr = 2
dot_shown = false
sda, scl = 1, 2
led_noe = 4
-- Below: variables related to time getting
timeZone = 0 -- GMT+1 hours
hour = 0
minute = 0
second = 0
day = 0
month = 0
year = 0

tube_array = {}
max_tube_intensity_dist = 120
for i = 0, 61 do
	tube_array[i] = 0
end

-- returns the hour, minute, second, day, month and year from the ESP8266 RTC seconds count (corrected to local time by tz)
-- credit to kieranc in esp8266.com
function getRTCtime(tz)

	-- returns 2 if a given year is a leap year, else returns 1
	local function isleapyear(y)
	   if ((y%4)==0) or (((y%100)==0) and ((y%400)==0)) then
			return 2 
	   else 
			return 1 
	   end
	end
   
	-- returns 366 is a given year is a leap year else returns 365
	local function daysperyear(y)
	   if isleapyear(y)==2 then 
			return 366 
	   else 
			return 365 
	   end
	end		   

	-- determines whether Daylight Saving Time is in effect for a given hour, day, month and year
	local function isDST(hour,day,month,year)

		-- returns the date for Nth day of the month.
		-- for example: nthDate(2016,3,0,2) will return the date of the 2nd Sunday in March 2016 (the 13th) when DST begins
		--				nthDate(2016,11,0,1) will return the date of the 1st Sunday in November 2016 (the 6th) when DST ends
		local function nthDate(year,month,DOW,week)
		
			-- returns a number corresponding to the day of the week (0-7 is Sunday to Saturday)
			local function dow(year,month,day)
				local t={0,3,2,5,0,3,5,1,4,6,2,4}
				if month<3 then
					year=year-1
				end
				return (year + year/4 - year/100 + year/400 + t[month] + day) % 7
			end -- function dow
		
			targetDate=1
			firstDOW = dow(year,month,targetDate);
			while (firstDOW ~= DOW) do
				firstDOW = (firstDOW+1)%7
				targetDate=targetDate+1
			end
			targetDate = targetDate+(week-1)*7
			return targetDate
		end -- function nthDate
	
		local startDate=nthDate(year,3,0,2) -- day when DST starts this year (2nd Sunday in March)
		local endDate=nthDate(year,11,0,1)	-- day when DST ends this year (1st Sunday in November)
		if ((month>3) and (month<11)) or						-- is the date between April and October?
			((month==3) and (day>startDate)) or				  	-- is the date in March but after the 2nd Sunday in March?
			((month==3) and (day==startDate) and (hour>1)) or	-- is it after 2AM on the 2nd Sunday in March? 
			((month==11) and (day<endDate)) or					-- is the date in November but before the 1st Sunday?
			((month==11) and (day==endDate) and (hour<2)) then	-- is it before 2AM on the 1st Sunday in November?
			return true
		else
			return false
		end
	end -- function isDST
   
	local monthtable = {{31,28,31,30,31,30,31,31,30,31,30,31},{31,29,31,30,31,30,31,31,30,31,30,31}} -- days in each month
	local secs=rtctime.get()
	local d=secs/86400
	local y=1970   
	local m=1
	while (d>=daysperyear(y)) do d=d-daysperyear(y) y=y+1 end	-- subtract the number of seconds in a year
	while (d>=monthtable[isleapyear(y)][m]) do d=d-monthtable[isleapyear(y)][m] m=m+1 end -- subtract the number of days in a month
	secs=secs-1104494400-1104494400+(tz*3600) -- convert from NTP to Unix (01/01/1900 to 01/01/1970) 
	local hr=(secs%86400)/3600	 -- hours
	local mn=(secs%3600)/60		 -- minutes
	local sc=secs%60			 -- seconds
	local mo=m					 -- month
	local dy=d+1				 -- day
	local yr=y					 -- year
	if isDST(hr,dy,mo,yr) then hr=hr+1 end -- Daylight Saving Time is in effect, add one hour
	return hr,mn,sc,mo,dy,yr
end -- function getRTCtime

-- see if all the LED controllers are here
function check_led_controllers()
	result = true

	for i=1,4 do
		i2c.start(0)											-- start i2c
		c = i2c.address(0, digit_addresses[i], i2c.TRANSMITTER)	-- see if something answers
		i2c.stop(0)												-- stop i2c
		if c == false then
			result = false
		end
	end

	return result
end

-- write a register contents in a PCA
function write_reg_PCA(digit_addr, reg, val)
  i2c.start(0)
  i2c.address(0, digit_addr, i2c.TRANSMITTER)
  i2c.write(0, reg)
  i2c.write(0, val)
  i2c.stop(0)
end

-- update all segment registers inside a pca
function update_segment_registers(digit_addr, reg_bool_array, pwm_value)
	i2c.start(0)
	i2c.address(0, digit_addr, i2c.TRANSMITTER)
	i2c.write(0, start_digit_reg_addr + 128)
	for i=1,8 do
		if reg_bool_array[i] == 0 then
			i2c.write(0, 0)
		else
			i2c.write(0, pwm_value)
		end
	end
  i2c.stop(0)
end

-- display the number array on the 7 segments digits
function display_number_array()
	for i=1,4 do
		number = displayed_digits[i]
		-- don't display a 0 first digit
		if i == 1 and number == 0 then
			i = 2
			number = displayed_digits[i]
		end
		-- display dot or not
		if i == 2 and dot_shown == true then
			number_to_reg_val[number+1][6] = 1
		end
		update_segment_registers(digit_addresses[i], number_to_reg_val[number+1], 0x10)
		number_to_reg_val[number+1][6] = 0
	end
end

-- UDP Server Data receive
function on_udp_packet_receive(srv, payload, port, ip)
	-- Here we receive a 1 (empty) + 60 bytes array of int32_t, little endian
	-- We simply unpack the values and send them as is to the FPGA
	-- The SPI driver is set to 24 bits send
	-- The FPGA expect one byte MSB for tube addr, then one byte for PWM MSB, then one byte for PWM LSB
	--gpio.write(led_noe, gpio.HIGH)	
	if string.len(payload) == 244 then
		-- complete buffer update, timed at 5.8ms
		data_to_send = {struct.unpack("<!4iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii", payload)}
		-- delete last byte which contains parsing index
		data_to_send[62] = nil
		spi.send(1, data_to_send)	
		tube_array = data_to_send
	elseif string.len(payload) == 3 then
		-- single tube update 
		data_to_send = payload:byte(1)*65536 + payload:byte(2)*256 + payload:byte(3)
		spi.send(1, data_to_send)
	end
	--gpio.write(led_noe, gpio.LOW)
	srv:send(port, ip, "ACK")
end

-------------------------
-- NIXIE CLOCK PROGRAM --
-------------------------
-- IO INIT
gpio.mode(led_noe, gpio.OUTPUT)						-- Led output enable
gpio.write(led_noe, gpio.LOW)						-- Enable output
i2c.setup(0, sda, scl, i2c.SLOW)					-- init i2c

-- CHECK LED CONTROLLERS
res = check_led_controllers()
if res == true then
	print("LED controllers here!")
else
	print("Device not found !!")
end

-- INIT LED CONTROLLERS SETTINGS
for i=1,4 do
	-- Register auto-increment, normal mode, responds to all call
	write_reg_PCA(digit_addresses[i], 0x00, 0x81)
	-- LED driver 0->7 individual brightness and group dimming/blinking can be controlled through its PWMx register and the GRPPWM registers.
	write_reg_PCA(digit_addresses[i], 0x0C, 0xFF)
	write_reg_PCA(digit_addresses[i], 0x0D, 0xFF)
end

-- INIT SNTP
sntp.sync("2.ch.pool.ntp.org")

-- INIT SPI AT 20MHZ
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 24, 4)

-- UDP SERVER
srv=net.createUDPSocket()
srv:on("receive", on_udp_packet_receive)
srv:listen(43210)

-- CLOCK TIMER
tmr.alarm(0,1000,tmr.ALARM_AUTO,
	function()
		-- get the hour, minute, second, day, month and year from the ESP8266 RTC
		hour,minute,second,month,day,year = getRTCtime(timeZone)
		-- display time
		displayed_digits[1] = hour/10
		displayed_digits[2] = hour%10
		displayed_digits[3] = minute/10
		displayed_digits[4] = minute%10	
		display_number_array()
		-- flip dot
		if dot_shown == true then
			dot_shown = false
		else
			dot_shown = true
		end
		--if year ~= 0 then
		--	-- format and print the hour, minute second, month, day and year retrieved from the ESP8266 RTC
		--	print(string.format("%02d:%02d:%02d	 %02d/%02d/%04d",hour,minute,second,month,day,year))
		--else
		--	print("Unable to get time and date from the NTP server.")
		--end
	end
)