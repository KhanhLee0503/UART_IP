# UART_IP
This is a personal project designing an UART with Parity Bit Check, Configure by APB SFR and implementing it on DE-10 Lite FPGA

# Overview
## UART Protocol Frame Data
<img width="1000" height="500" alt="image" src="https://github.com/user-attachments/assets/e4e7dc19-f8d4-495d-95ee-69d11779ada0" />

### 1. The Data Frame Structure (Top Half)
The top waveform shows how a single package (frame) of data is transmitted over the physical wire.
- **Idle State (Before Start):** By default, when no data is being sent, the UART line is held at Logic 1 (HIGH).
  
- **START Bit:** The transmission begins with a High-to-Low transition. The line is pulled to Logic 0 for one bit duration. This sudden drop alerts the receiving module that a new frame is arriving.
  
- **Word Data (D0 to D7):** This is the actual payload you want to transmit (usually 8 bits, or 1 byte). In UART, the data is typically sent LSB (Least Significant Bit) first, starting from D0 and ending at D7.
  
- **Parity Bit (PB):** As noted in the diagram, this is (optional). An extra bit inserted after the data payload to check for errors (Even or Odd parity).
  
- **STOP Bit:** The frame must always conclude with at least one Stop bit, which is always Logic 1 (HIGH). This signals the end of the package and guarantees that the line returns to the idle state, ready for the next Start bit.

### 2. The Sampling Mechanism (Bottom Half)
The bottom part of the diagram illustrates the hidden magic of the RX (Receiver) FSM. Since UART is asynchronous (there is no shared clock line between the sender and receiver), the receiver has to figure out exactly when to read the data.

- **Start Detection:** The receiver constantly monitors the line. When it sees the transition from Logic 1 to Logic 0, it triggers its internal counter.

- **Sampling at the Center:** Notice how the sampling pulses (the little spikes) align perfectly with the middle of each data bit. The receiver's baud rate generator calculates the exact width of a bit. Instead of reading the data at the edges (where the signal might be noisy or transitioning), it waits half a bit-period to sample the "bit-pulse center". This ensures the most stable and accurate reading.

- **Stop Bit Sampling:** Finally, it samples the middle of the Stop bit. If it reads a 1, the frame is valid. If it reads a 0, a Framing Error occurs!

## Features
- This UART design has 4 baudrate selection and 2 sampling modes, which can be configured by the input **I_BAUD_RATE** and **I_BCLK_MODE**.
- Parity Error Check mechanism included, to use this feature, enable **I_PARITY_EN** and choose **I_PARITY_TYPE**
- 2 Transmission and Reception FIFO used for speeding up the transfer process (FWFT).
- Use APB Protocol to configure the operation of the UART.

## Signal Description
| Name         | Direction | Width | Description                                                  |
| ----------   | --------- | ----- | ------------------------------------------------------------ |
| I_CLK        | Input     |   1   |  UART's Clock source                                         |
| I_RESET_N    | Input     |   1   |  Reset signal                                                |
| I_BAUDRATE   | Input     |   4   |  Choose baudrate: 0 = 9600, 1 = 19200, 2 = 38400, 3 = 115200 |
| I_BCLK_MODE  | Input     |   1   |  Choose sampling mode: 0 = x16, 1 = x13                      |
| I_CNT_EN     | Input     |   1   |  Enable UART operation                                       |
| I_CNT_LOAD   | Input     |   1   |  Load divisor                                                |
| I_PARITY_EN  | Input     |   1   |  Enable Parity Error Checking Feature                        |
| I_PARITY_TYPE| Input     |   1   |  Parity Type (0: Even, 1: Odd)                               |
| I_WR_EN      | Input     |   1   |  Write to FIFO enable                                        |
| I_RD_EN      | Input     |   1   |  Read from FIFO enable                                       |
| I_WDATA      | Input     |   8   |  Write data                                                  |
| I_RX_IN      | Input     |   1   |  Reception RX                                                |
| O_TX_OUT     | Output    |   1   |  Transmission TX                                             |
| O_RX_FULL    | Output    |   1   |  Reception FIFO is full                                      |
| O_TX_EMPTY   | Output    |   1   |  Transmission FIFO is empty                                  |
| O_PARITY_ERR | Output    |   1   |  Parity Error in data Transfer                               |
| O_PRDATA     | Output    |   16  |  Read data from FIFO                                         |
  
# Block Diagram

## Architecture

<img width="9492" height="5212" alt="image" src="https://github.com/user-attachments/assets/361f7d49-bffb-4187-91f6-c831944c3682" />
<img width="6016" height="4012" alt="image" src="https://github.com/user-attachments/assets/08e57248-7da1-4a37-9ac9-facdc9f2487e" />


## TRANS_SHIFT_REG Logic

<img width="1075" height="715" alt="image" src="https://github.com/user-attachments/assets/1d7e9634-6c05-46b1-92a7-df8abf14da2b" />
<img width="5000" height="5556" alt="image" src="https://github.com/user-attachments/assets/7f3bf205-8e03-472c-bc0d-99e377eee295" />


## RECEIVER_SHIFT_REG Logic
<img width="10056" height="5976" alt="image" src="https://github.com/user-attachments/assets/0cc7194a-3356-4e74-ae87-dbe1cc506465" />
<img width="4504" height="5364" alt="image" src="https://github.com/user-attachments/assets/17d34963-9c6f-4e81-8554-ec71eb5764a4" />


## Synchronous FIFO Diagram
<img width="9000" height="7000" alt="image" src="https://github.com/user-attachments/assets/3adba8b9-d281-4e1e-ba44-8b1df0d4cf36" />


## Baud Generation Diagram
<img width="9000" height="7000" alt="image" src="https://github.com/user-attachments/assets/7a9b3bc6-4f2b-4161-abc9-2aae4b23d69a" />

## Parity Logic Diagram
<img width="5892" height="2852" alt="image" src="https://github.com/user-attachments/assets/6f02113e-c487-4d47-ba27-3a7ea37cb13c" />
<img width="3772" height="2012" alt="image" src="https://github.com/user-attachments/assets/19ced5cf-ba84-472a-9a72-acf6a3428627" />

# Implement on FPGA (DE-10 Lite)
- This is the implementation of UART module on DE-10 Lite FPGA kit, communicating with Laptop through Hercules.
### 1. Write to Laptop
- Write a random 8 bit number to the Laptop through Hercules.
### 2. Receive from Laptop
- Laptop will write 8 bit number for 16 times consecutively through Hercules, we expect the RX FIFO Full Flag will be asserted. Then, we will read 16 hex numbers value that have been received.
### 3. Parity Check Error
- We will configure our UART module to be Even parity mode, Laptop will be Odd parity mode. Then Laptop will transmit data to FPGA, we expect parity error flag will be asserted.

