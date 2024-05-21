# IEEE-754 Double Precision Floating Point Multiplier

This is the final project of the course "Design of Digital Integrated Circuits and Systems" at CCU CS.

Completion Date: *2024-05*
## Folder Structure
    .
    ├── doc/
    │   └── fp_mul_report_ch.pdf         # Final Report of this Project Written in Chinese.
    │
    ├── src/
    │   ├── Netlist/                     # SPICE Netlist
    │   │   ├── FP_MUL_syn.v             # Digitally-Controlled Ocsillator
    │   │   └── TEST_gate.v              # Phase Frequency Detector
    │   │
    │   └── RTL/                         # Verilog RTL Code
    │       ├── FP_MUL.v                 # Controller
    │       ├── FP_MUL_old.v             # Digitally-Controlled Oscillator
    │       ├── TEST.v                   # Divider
    │       ├── TEST_TREE.v              # Phase Frequency Detector
    │       ├── TREE.v                   # Test module
    │       ├── pattern.dat              # Test module
    │       └── pattern.py               # Top module
    │
    └── README.md

## Output Waveform ( Reference Clock = 400MHz, Divisor = 7) 
![Screenshot 2024-05-08 000953](https://github.com/hsu26zq/game/assets/95536686/bac4c97c-5a88-4496-a7f9-e0c2931c96c3)


