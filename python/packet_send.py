from array import array
import socket
import time
import sys

UDP_IP = "192.168.1.19"
UDP_PORT = 43210

def get_packet_to_send_for_tube(tube_number, intensity):
	data = array('B')
	data.append(tube_number)
	data.append((intensity>>8) & 0x00FF)
	data.append(intensity & 0x00FF)
	return data

if __name__ == "__main__":
	# Socket to platform
	sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
		
	#data[42*2] = 0x30
	#sock.sendto(data, (UDP_IP, UDP_PORT))
	#print data
	#sys.exit(0)
	
	#data = array('B')
	#data.append(1)
	#data.append(2)
	#data.append(3)
	#data.append(4)
	#data.append(1)
	#data.append(2)
	#data.append(3)
	#data.append(4)
	#sock.sendto(data, (UDP_IP, UDP_PORT))
	#print data
	#sys.exit(0)
	
	choice = input("0 set val, 1 anim: ")
	
	# 4*60 bytes for pwm data (LITTLE ENDIAN)
	data = array('B')
	for i in range(0, 240):
		data.append(0)
	if choice == "0":
		while True:
			full_val = int(raw_input("new value: "), 16)
			for j in range(0,60):
				data[j*4+2] = j
				data[j*4+1] = (full_val >> 8) & 0x00FF
				data[j*4] = (full_val) & 0x00FF
			sock.sendto(data, (UDP_IP, UDP_PORT))
	elif choice == "1":
		while True:
			i = 0
			while i < 16000:
				for j in range(0,60):
					data[j*4+2] = j
					data[j*4+1] = (i >> 8) & 0x00FF
					data[j*4] = (i) & 0x00FF
				sock.sendto(data, (UDP_IP, UDP_PORT))
				i = i + 0x80
				time.sleep(0.01)
				print(i)
			while i > 0:
				for j in range(0,60):
					data[j*4+2] = j
					data[j*4+1] = (i >> 8) & 0x00FF
					data[j*4] = (i) & 0x00FF
				sock.sendto(data, (UDP_IP, UDP_PORT))
				i = i - 0x80
				time.sleep(0.01)
				print(i)
		
	sys.exit(0)	
	
	if False:
		data = array('B')
		data.append(1)
		data.append(0)
		data.append(0)
		data.append(0)
		while True:
			i = 0
			while i < 0x3A00:
				data[1] = 0x2A
				data[2] = (i >> 8) & 0x00FF
				data[3] = (i) & 0x00FF
				sock.sendto(data, (UDP_IP, UDP_PORT))
				i = i + 0x80
				time.sleep(.01)
				print(i)
	
	# Create buffer of empty data
	data = array('B')
	for i in range(0, 121):
		data.append(0)
		
	while True:
		i = 0
		while i < 0x3A00:
			data[42*2+1] = (i >> 8) & 0x00FF
			data[42*2+2] = (i) & 0x00FF
			sock.sendto(data, (UDP_IP, UDP_PORT))
			i = i + 0x80
			time.sleep(.01)
			print(i)