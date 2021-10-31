-- INIT SPI AT 20MHZ
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 24, 4)

up_direction = true
top_pause = false
top_pause_counter = 0
value = 0
increment = 500

tube_array = {}
for i = 0, 61 do
	tube_array[i] = bit.lshift(i, 16) + 0
end

function fill_tube_array_with_value(value)
	tube_array[0] = 0
	indexes = {7}
	for i,val in ipairs(indexes) do
		tube_array[val] = bit.lshift(val, 16) + value	
	end
end

-- CLOCK TIMER
tmr.alarm(0,20,tmr.ALARM_AUTO,
	function()
		if up_direction then
			value = value + increment
			if value >= 16383 then
				value = 16383
				if top_pause then
					top_pause_counter = top_pause_counter + 1
					if top_pause_counter > 10000 then
						up_direction = false
						top_pause_counter = 0
						top_pause = false
					end
				else
					top_pause = true
				end
			end
			fill_tube_array_with_value(value)
			spi.send(1, tube_array)
		else
			if value > increment then
				value = value - increment
				fill_tube_array_with_value(value)
				spi.send(1, tube_array)
			else
				fill_tube_array_with_value(0)
				spi.send(1, tube_array)
				up_direction = true
				value = 0
			end
		end
	end
)