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

## Signal Description
| Name         | Direction | Width | Description                                                  |
| ----------   | --------- | ----- | ------------------------------------------------------------ |
| I_CLK        | Input     |   1   |  UART's Clock source                                         |
| I_RESET_N    | Input     |   1   |  Reset signal                                                |
| I_BAUDRATE   | Input     |   4   |  Choose baudrate: 0 = 9600, 1 = 19200, 2 = 38400, 3 = 115200 |
| I_BCLK_MODE  | Input     |   1   |  Choose sampling mode: 0 = x16, 1 = x13                      |
| I_CNT_EN     | Input     |   1   |  Enable UART operation                                       |
| I_CNT_LOAD   | Input     |   1   |  Load divisor                                                |
| I_WR_EN      | Input     |   1   |  Write to FIFO enable                                        |
| I_RD_EN      | Input     |   1   |  Read from FIFO enable                                       |
| I_WDATA      | Input     |   8   |  Write data                                                  |
| I_RX_IN      | Input     |   1   |  Reception RX                                                |
| O_TX_OUT     | Output    |   1   |  Transmission TX                                             |
| O_PRDATA     | Output    |   16  |  Read data from FIFO                                         |

## Features
- This UART design has 4 baudrate selection and 2 sampling modes, which can be configured by the input **I_BAUD_RATE** and **I_BCLK_MODE**.
- Parity Error Check mechanism included, to use this feature, enable **I_PARITY_EN** and choose **I_PARITY_TYPE**
- 2 Transmission and Reception FIFO used for speeding up the transfer process (FWFT).
- Use APB Protocol to configure the operation of the UART.

## Special function
- There are two special modules will help this UART transmitt or receive 32-bit data instead of 8-bit data, which will reduce the workload of the user.
  
# Block Diagram
## TRANS_SHIFT_REG Logic
<img width="9000" height="7000" alt="image" src="https://github.com/user-attachments/assets/c4899efe-dd23-40ea-8b83-91c9ffe17b24" />
<img width="12000" height="7000" alt="image" src="https://github.com/user-attachments/assets/9a11620b-abff-4e81-a7dc-50497f4434ec" />

## RECEIVER_SHIFT_REG Logic
<img width="9000" height="7000" alt="image" src="https://github.com/user-attachments/assets/0dbbf0e8-af64-4c42-ab3e-1b17a223bfbd" />
<img width="12000" height="7000" alt="image" src="https://github.com/user-attachments/assets/ed482961-060b-4133-91ff-73d4db95eefd" />

## Synchronous FIFO Diagram
<img width="9000" height="7000" alt="image" src="https://github.com/user-attachments/assets/3adba8b9-d281-4e1e-ba44-8b1df0d4cf36" />


## BAUD_GEN Diagram
<img width="9000" height="7000" alt="image" src="https://github.com/user-attachments/assets/7a9b3bc6-4f2b-4161-abc9-2aae4b23d69a" />

## Implement on FPGA (DE-10 Lite)
https://github.com/user-attachments/assets/f104c2a9-9b0e-42f0-8d22-30870cb2cfda

