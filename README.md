# UART_IP
This is a personal project designing an UART Module and implementing it on DE-10 Lite FPGA

# Overview of the Design
| Name       | Direction | Width | Description    |
| ---------- | --------- | ------ | -------------- |
| I_CLK      | Input     |  1    |  Clock source  |
| I_RESET_N  | Input     | 1     |  Reset signal  |
# Block Diagram
## TRANS_SHIFT_REG Logic
<img width="9000" height="5976" alt="image" src="https://github.com/user-attachments/assets/d05b1143-c3a5-4773-a5d2-99b761a3f005" />
<img width="9000" height="4364" alt="image" src="https://github.com/user-attachments/assets/9a11620b-abff-4e81-a7dc-50497f4434ec" />

## RECEIVER_SHIFT_REG Logic
<img width="9000" height="5856" alt="image" src="https://github.com/user-attachments/assets/6637b7b6-38e3-4ab9-85b9-d48f84a05f37" />
<img width="9000" height="4052" alt="image" src="https://github.com/user-attachments/assets/ed482961-060b-4133-91ff-73d4db95eefd" />

## Synchronous FIFO Diagram
<img width="9000" height="4052" alt="image" src="https://github.com/user-attachments/assets/d52d515c-6e4d-4b8c-901d-4884609b1b9f" />

## BAUD_GEN Diagram
<img width="9000" height="3936" alt="image" src="https://github.com/user-attachments/assets/7a9b3bc6-4f2b-4161-abc9-2aae4b23d69a" />

## Implement on FPGA (DE-10 Lite)
https://github.com/user-attachments/assets/f104c2a9-9b0e-42f0-8d22-30870cb2cfda

