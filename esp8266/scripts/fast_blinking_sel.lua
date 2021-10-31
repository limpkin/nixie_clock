-- this program is aimed at fixing tubes having the "small bar in the middle of the tube" issue
-- INIT SPI AT 20MHZ
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 24, 4)

counter = 0
tube_array = {}
tube_array_on = {}
tube_array_off = {}

tube_array[0] = 0
for i = 0, 60 do
	tube_array[i+1] = bit.lshift(i, 16) + 0
end
spi.send(1, tube_array)

tube_array_on[0] = 0
tube_array_off[0] = 0
selected_tubes = {3,5,6,11,13,14,15,16,19,20,21,22,27,28,29,35,42,48,51,52,56,59}
for i,val in ipairs(selected_tubes) do
	tube_array_on[i] = bit.lshift(val, 16) + 16383	
	tube_array_off[i] = bit.lshift(val, 16) + 0	
end

-- CLOCK TIMER
tmr.alarm(0,1,tmr.ALARM_AUTO,
	function()
		if counter == 1 then
			spi.send(1, tube_array_off)
		end
		counter = counter + 1
		if counter == 20 then
			counter = 0
			spi.send(1, tube_array_on)
		end
	end
)