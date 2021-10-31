-- INIT SPI AT 20MHZ
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 24, 4)

tube = 0
up_direction = true
top_pause = false
top_pause_counter = 0
value = 0
increment = 200

-- CLOCK TIMER
tmr.alarm(0,1,tmr.ALARM_AUTO,
	function()
		if up_direction then
			value = value + increment
			if value >= 16383 then
				value = 16383
				if top_pause then
					top_pause_counter = top_pause_counter + 1
					if top_pause_counter > 0 then
						up_direction = false
						top_pause_counter = 0
						top_pause = false
					end
				else
					top_pause = true
				end
			end
			spi.send(1, tube*65536+value)
		else
			if value > increment then
				value = value - increment
				spi.send(1, tube*65536+value)
			else
				spi.send(1, tube*65536+0)
				up_direction = true
				tube = tube + 1
				value = 0
				if tube == 60 then
					tube = 0
				end
			end
		end
	end
)