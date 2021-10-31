-- INIT SPI AT 20MHZ
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 24, 4)


max_tube_index = 0
decrement = 230

-- tube array
tube_min_pwm = 3333
tube_array = {}
for i = 0, 61 do
	tube_array[i] = 0
end

function flush_array_to_fpga()
	spi.send(1, tube_array)
end

function set_array_to_value(value)
	tube_array[0] = 0
	for i = 0, 60 do
		tube_array[i+1] = bit.lshift(i, 16) + value	
	end
end

function update_tube(tube_index, value)
	tube_array[tube_index+1] = bit.lshift(tube_index, 16) + value	
end

function tube_rampup(increment, delay)
	pwm_value = tube_min_pwm
	while pwm_value < 16383 do
		set_array_to_value(pwm_value)
		flush_array_to_fpga()
		tmr.delay(delay)
		pwm_value = pwm_value + increment
	end
	set_array_to_value(16383)
	flush_array_to_fpga()
	tmr.delay(delay)
end

function tube_rampdown(increment, delay)
	pwm_value = 16383
	while pwm_value > tube_min_pwm do
		set_array_to_value(pwm_value)
		flush_array_to_fpga()
		tmr.delay(delay)
		pwm_value = pwm_value - increment
	end
	set_array_to_value(tube_min_pwm)
	flush_array_to_fpga()
	tmr.delay(delay)
end

function tube_init_sequence()
	set_array_to_value(0)
	flush_array_to_fpga()
	tmr.delay(1000000)
	for i = 0, 60 do
		update_tube(i, tube_min_pwm)
		flush_array_to_fpga()
		tmr.delay(100000)
	end
	tube_rampup(300, 100)
	tmr.delay(2000000)
	tube_rampdown(200, 100)
end

function update_array()
	for i = 0, 60 do
		tube_array[i+1] = bit.lshift(i, 16) + node.random(tube_min_pwm, 16383)
	end
end

tube_init_sequence()

-- CLOCK TIMER
tmr.alarm(0,100,tmr.ALARM_AUTO,
	function()
		update_array()
		spi.send(1, tube_array)
	end
)