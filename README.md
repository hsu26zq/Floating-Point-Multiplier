# IEEE-754 Double-Precision Floating-Point Multiplier
Floating-point multiplier designed in a pipelined wallace tree architecture.

Completion Date: *2024-05*

## Architecture
![rsz_pic1](https://github.com/hsu26zq/fp-multiplier/assets/95536686/6b41fcfc-57c6-4ac1-b10e-929108656b3a)

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
    │       ├── UVM/                     # UVM Verification (unfinished)
    │       │   ├── my_driver.sv         # Driver
    │       │   ├── my_env.sv            # Environment
    │       │   ├── my_interface.sv      # Interface
    │       │   ├── my_monitor.sv        # Monitor
    │       │   ├── my_transaction.sv    # Transaction
    │       │   └── testbench.sv         # Testbench
    │       │
    │       ├── FP_MUL.v                 # Multiplier
    │       ├── FP_MUL_old.v             # Old design
    │       ├── TEST.v                   # RTL testbench
    │       ├── TEST_TREE.v              # Wallace tree testbench
    │       ├── TREE.v                   # Wallace tree
    │       ├── pattern.dat              # Test pattern
    │       └── pattern.py               # Test pattern generation
    │
    └── README.md
