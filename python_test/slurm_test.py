import socket
from datetime import datetime
import time

def get_computer_name():
    return socket.gethostname()
num_test=1
while True:
    computer_name = get_computer_name()
    current_time = datetime.now().strftime("%H:%M:%S")

    # Print to console for debugging
    print(f"{current_time} - Computer Name: {computer_name}")

    # Open the file in append mode and write the computer name
    with open(f'/storage/result{computer_name}.log', 'a') as file:
        file.write(f"{current_time} - Computer Name: {computer_name}\n")
        file.write(f"Number of test tests: {num_test}")

    time.sleep(3)  # 5 seconds delay
 