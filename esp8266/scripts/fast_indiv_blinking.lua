-- this program is aimed at fixing tubes having the "small bar in the middle of the tube" issue
-- INIT SPI AT 20MHZ
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 24, 4)

current_tube = 0
tube_on = false
tube_count = 0
max_val = 16383
tube_array = {}
nb_go_and_back = 3000
for i = 0, 61 do
	tube_array[i] = 0
end

function fill_tube_array_with_value(value)
	tube_array[0] = value
	for i = 0, 60 do
		tube_array[i+1] = bit.lshift(i, 16) + value	
	end
end
spi.send(1, tube_array)

-- CLOCK TIMER
tmr.alarm(0,2,tmr.ALARM_AUTO,
	function()
		if tube_on then
			spi.send(1, bit.lshift(current_tube, 16) + 0)
			tube_on = false
		else
			if tube_count == nb_go_and_back then
				tube_count = 0
				current_tube = current_tube + 1
				print(current_tube)
				if current_tube >= 60 then
					current_tube = 0
				end
			end
			spi.send(1, bit.lshift(current_tube, 16) + max_val)
			tube_count = tube_count + 1
			tube_on = true
		end
	end
)