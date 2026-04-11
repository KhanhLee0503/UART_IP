# UART_IP
This is a personal project designing an UART Module and implementing it on DE-10 Lite FPGA
# Overview of the Design
## TSR Interface
<img width="1000" height="283" alt="image" src="https://github.com/user-attachments/assets/ca604850-c894-4999-a9a2-291f6cd02a07" />
## RSR Interface
<img width="1000" height="386" alt="image" src="https://github.com/user-attachments/assets/d83278a3-db82-4b92-81b3-28355a22f45b" />

# Block Diagram
## TSR Logic
<img width="1000" height="733" alt="image" src="https://github.com/user-attachments/assets/eafd2545-58c7-4610-9b73-5965f836efe4" />

### Counter
<img width="1000" height="461" alt="image" src="https://github.com/user-attachments/assets/f747bbf8-ba0e-4f09-a7e9-1b1667c35317" />

### Parity Logic 
<img width="1316" height="436" alt="image" src="https://github.com/user-attachments/assets/3ddd6916-95a8-45e8-bd88-89e8088b9e93" />

### Transmit Logic 
<img width="1000" height="449" alt="image" src="https://github.com/user-attachments/assets/005b917d-c515-418b-a6ca-3cfa98071b48" />
<img width="1000" height="462" alt="image" src="https://github.com/user-attachments/assets/eb340d11-2d75-4c3a-b8c2-74b055d490d1" />

## RSR Logic
### Read Data Register
<img width="1000" height="536" alt="image" src="https://github.com/user-attachments/assets/466e2ec0-4d3c-470c-9db5-8d1b2da0bcff" />

### Sample Counter
<img width="1000" height="609" alt="image" src="https://github.com/user-attachments/assets/322e53bf-242d-4f9b-8ffd-21f21d45e068" />

### Sample Logic
<img width="1000" height="773" alt="image" src="https://github.com/user-attachments/assets/c8303fa2-d9fc-4d9f-b8f3-c37f18a6a6c7" />
<img width="1000" height="226" alt="image" src="https://github.com/user-attachments/assets/32adc4e7-1874-443d-b7bb-ddb98eec64d9" />

### Parity Logic
<img width="1000" height="655" alt="image" src="https://github.com/user-attachments/assets/c5d705c2-29c3-4335-b140-bb56dc1adac9" />

### FSM Diagram
<img width="1814" height="1057" alt="image" src="https://github.com/user-attachments/assets/cb4d99ea-b24d-4f4a-b799-517fb872fc68" />
