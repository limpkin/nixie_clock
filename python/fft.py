import matplotlib.pyplot as plt
from scipy.io import wavfile
from scipy import signal
from array import array
import numpy as np
import pyaudio
import socket
import pylab
import time
import sys

# Number of packets / seconds we could achieve to the platform:
# 87
# 88
# 84
# 88
# 91
# 92
# 91
# 84
# 91
# 84
# 93
# 90
# 90
# 87
# 89
# 90
# 92
# 84
# 89

UDP_IP = "192.168.1.11"
UDP_PORT = 43210
min_tube_value = 2000
last_dfft_to_send = []

def get_packet_to_send_for_tube(tube_number, intensity):
	data = array('B')
	data.append(tube_number)
	data.append((intensity>>8) & 0x00FF)
	data.append(intensity & 0x00FF)
	return data

i=0
f,ax = plt.subplots(2)

# Prepare the Plotting Environment with random starting values
x = np.arange(10000)
y = np.random.randn(10000)

# Plot 0 is for raw audio data
li, = ax[0].plot(x, y)
ax[0].set_xlim(0,1000)
ax[0].set_ylim(-5000,5000)
ax[0].set_title("Raw Audio Signal")
# Plot 1 is for the FFT of the audio
li2, = ax[1].plot(x, y)
ax[1].set_xlim(0,60)
ax[1].set_ylim(0,16383)
ax[1].set_title("Fast Fourier Transform")
# Show the plot, but without blocking updates
plt.pause(0.01)
plt.tight_layout()

FORMAT = pyaudio.paInt16 # We use 16bit format per sample
CHANNELS = 1
RATE = 44100
CHUNK = 4096 # 1024bytes of data red from a buffer
RECORD_SECONDS = 0.1
WAVE_OUTPUT_FILENAME = "file.wav"

audio = pyaudio.PyAudio()
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# start Recording
stream = audio.open(format=FORMAT,
					channels=CHANNELS,
					rate=RATE,
					input=True)#,
					#frames_per_buffer=CHUNK)

keep_going = True
data = array('B')
for i in range(0, 244):
	data.append(0)
for k in range(0, 1):
	i = 1000
	while i < 16000:
		for j in range(0,60):
			data[4+j*4+2] = j
			data[4+j*4+1] = (i >> 8) & 0x00FF
			data[4+j*4] = (i) & 0x00FF
		sock.sendto(data, (UDP_IP, UDP_PORT))
		sock.recvfrom(10)
		i = i + 0x80
	while i > min_tube_value:
		for j in range(0,60):
			data[4+j*4+2] = j
			data[4+j*4+1] = (i >> 8) & 0x00FF
			data[4+j*4] = (i) & 0x00FF
		sock.sendto(data, (UDP_IP, UDP_PORT))
		sock.recvfrom(10)
		i = i - 0x80

def plot_data(in_data):
	global last_dfft_to_send
	
	# get and convert the data to float
	audio_data = np.frombuffer(in_data, np.int16)
	
	# Fast Fourier Transform, 10*log10(abs) is to scale it to dB
	# and make sure it's not imaginary
	#dfft = 10.*np.log10(abs(np.fft.rfft(audio_data)))
	dfft = 10.*np.log10(abs(np.fft.rfft(audio_data)))
	#print(np.average(dfft))
	#dfft -= np.average(dfft)
	dfft -= 30
	dfft = dfft[1:200]
	dfft = signal.resample(dfft, 60)
	dfft *= 400
	dfft[dfft < min_tube_value] = min_tube_value
	dfft[dfft > 16000] = 16000
	#print(dfft)
	
	if len(last_dfft_to_send) == 0:
		last_dfft_to_send = dfft
	
	data_to_send = []
	data_to_send = array('B')
	for i in range(0, 244):
		data_to_send.append(0)
			
	max_decrease_distance = 200
	for j in range(0,60):
		data_to_send[4+j*4+2] = j
		if last_dfft_to_send[j] > dfft[j] + max_decrease_distance:
			last_dfft_to_send[j] -= max_decrease_distance
			data_to_send[4+j*4+1] = (int(last_dfft_to_send[j]) >> 8) & 0x00FF
			data_to_send[4+j*4] = int(last_dfft_to_send[j]) & 0x00FF
		else:
			last_dfft_to_send[j] = dfft[j]
			data_to_send[4+j*4+1] = (int(last_dfft_to_send[j]) >> 8) & 0x00FF
			data_to_send[4+j*4] = (int(last_dfft_to_send[j])) & 0x00FF
			
	for i in range(1):
		sock.sendto(data_to_send, (UDP_IP, UDP_PORT))
		sock.recvfrom(10)
		
	#dfft = np.subtract(dfft, initial_measurement)	  
	#dfft = signal.resample(dfft[100:1900], 60)
	#dfft /= np.max(np.abs(dfft),axis=0)
	#dfft *= (16383.0/dfft.max())
	#print(dfft)

	if True:
		# Force the new data into the plot, but without redrawing axes.
		# If uses plt.draw(), axes are re-drawn every time
		#print audio_data[0:10]
		#print dfft[0:10]
		#print
		li.set_xdata(np.arange(len(audio_data)))
		li.set_ydata(audio_data)
		li2.set_xdata(np.arange(len(dfft)))
		#li2.set_ydata(dfft)
		li2.set_ydata(last_dfft_to_send)

		# Show the updated plot, but without blocking
		plt.pause(0.001)
		
	if keep_going:
		return True
	else:
		return False

# Open the connection and start streaming the data
stream.start_stream()
print("\n+---------------------------------+")
print("| Press Ctrl+C to Break Recording |")
print("+---------------------------------+\n")

# Loop so program doesn't end while the stream callback's
# itself for new data
plot_data(stream.read(CHUNK))
while keep_going:
	try:
		plot_data(stream.read(CHUNK))
	except KeyboardInterrupt:
		keep_going=False
	except:
		pass

# Close up shop (currently not used because KeyboardInterrupt
# is the only way to close)
stream.stop_stream()
stream.close()

audio.terminate()