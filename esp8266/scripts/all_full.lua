-- INIT SPI AT 20MHZ
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 24, 4)

up_direction = true
top_pause = false
top_pause_counter = 0
value = 0
increment = 20

tube_array = {}
for i = 0, 61 do
	tube_array[i] = 0
end

function set_array_to_value(value)
	tube_array[0] = value
	for i = 0, 60 do
		tube_array[i+1] = bit.lshift(i, 16) + value	
	end
	spi.send(1, tube_array)
end

set_array_to_value(0)
tmr.delay(100000)
set_array_to_value(3333)
tmr.delay(1000000)
set_array_to_value(16383)