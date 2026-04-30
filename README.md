# dual-core-RISC-V-pipeline
<br>
One of the instructions demonstrated, whose output is displayed through 7-segment display<br><br>We plan to utilise VGA for graphical implementation showing dual functionality as our next goal.<br><br>
<p>
<img width="1600" height="719" alt="WhatsApp Image 2026-04-20 at 6 47 23 PM" src="https://github.com/user-attachments/assets/b1915943-ca32-4cb9-a7d6-45902c7691da" />
<br></p>
<pre>
• Two independent 5-stage RISC-V pipeline cores <br>
• Clock divider (100 MHz → CPU clock + 7-seg refresh)<br>
• 8-digit 7-segment display driver <br>

  Switch / button mapping
  btnC          → synchronous reset for both cores
  sw[4:0]       → register index to inspect (0–31)
  sw[5]         → core select  (0 = Core 0, 1 = Core 1)
  sw[15:6]      → unused (reserved)

  LED mapping
  led[15:0]     → lower 16 bits of selected register value
                  (blinks MSB on write-back activity
  7-seg display
  All 8 digits show the selected register value in hex.
  Digit 7 (leftmost) = bits[31:28], digit 0 = bits[3:0].</pre>
