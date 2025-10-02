import paho.mqtt.client as mqtt
import os
import time
from datetime import datetime

# Create logs directory if it doesn't exist
os.makedirs('logs', exist_ok=True)

# Find the next sequential log file number
log_files = [f for f in os.listdir('logs') if f.startswith('mqtt_log_') and f.endswith('.txt')]
if log_files:
    # Extract numbers and find the highest
    numbers = []
    for f in log_files:
        try:
            num = int(f.replace('mqtt_log_', '').replace('.txt', ''))
            numbers.append(num)
        except ValueError:
            continue
    next_num = max(numbers) + 1 if numbers else 1
else:
    next_num = 1

log_filename = f'logs/mqtt_log_{next_num:03d}.txt'

def on_connect(client, userdata, flags, rc):
    print(f"Connected with result code {rc}")
    # Subscribe to all topics
    client.subscribe("#")

def on_message(client, userdata, msg):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    topic = msg.topic
    message = msg.payload.decode('utf-8', errors='ignore')
    
    log_line = f"[{timestamp}] {topic}: {message}\n"
    
    # Write to log file
    with open(log_filename, 'a', encoding='utf-8') as f:
        f.write(log_line)
    
    # Also print to console
    print(log_line.strip())

def on_disconnect(client, userdata, rc):
    print("Disconnected from MQTT broker")

# Create MQTT client
client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message
client.on_disconnect = on_disconnect

print(f"Starting MQTT logger - saving to {log_filename}")
print("Press Ctrl+C to stop")

try:
    # Connect to localhost:1883
    client.connect("localhost", 1883, 60)
    client.loop_forever()
except KeyboardInterrupt:
    print("\nStopping MQTT logger...")
    client.disconnect()
except Exception as e:
    print(f"Error: {e}")
