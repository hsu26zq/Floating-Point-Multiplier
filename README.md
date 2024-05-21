# IEEE-754 Double Precision Floating Point Multiplier

This is the final project of the course "Design of Digital Integrated Circuits and Systems" at CCU CS.

Completion Date: *2024-05*
## Folder Structure
    .
    ├── doc/
    │   └── fp_mul_report_ch.pdf         # Final Report of this Project Written in Chinese.
    │
    ├── src/
    │   ├── Netlist/                     # Synthesis result
    │   │   ├── FP_MUL_syn.v             # Synthesized netlist
    │   │   └── TEST_gate.v              # Gate-Level testbench
    │   │
    │   └── RTL/                         # Verilog RTL Code
    │       ├── FP_MUL.v                 # Multiplier
    │       ├── FP_MUL_old.v             # Old design
    │       ├── TEST.v                   # RTL testbench
    │       ├── TEST_TREE.v              # Wallace tree testbench
    │       ├── TREE.v                   # Wallace tree
    │       ├── pattern.dat              # Test pattern
    │       └── pattern.py               # Test pattern generation
    │
    └── README.md

## Output Waveform ( Reference Clock = 400MHz, Divisor = 7) 
![Screenshot 2024-05-08 000953](https://github.com/hsu26zq/game/assets/95536686/bac4c97c-5a88-4496-a7f9-e0c2931c96c3)


