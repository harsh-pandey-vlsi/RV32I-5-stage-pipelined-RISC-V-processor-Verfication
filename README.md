# RV32I-5-stage-pipelined-RISC-V-processor-Verfication
A fully functional **RV32I** 5-stage pipelined processor designed in Verilog, with a SystemVerilog scoreboard-based verification environment featuring SVA assertions and functional coverage.

---
## Overview

| Property | Detail |
|---|---|
| ISA | RISC-V RV32I (base integer) |
| Architecture | 5-stage in-order pipeline |
| Language | RTL in Verilog, Testbench in SystemVerilog |
| Hazard handling | Full forwarding unit + load-use stall + branch flush |
| Verification | Scoreboard-based TB · 7 SVA assertions · 4 covergroups |
| Simulator | QuestaSim 2025.2 |
| Result | 17/17 register checks PASS · 96.3% functional coverage |

---

## Project Structure

```
riscv_pipeline/
│
├── rtl/                          # RTL design files
│   ├── riscv_pipeline.v          # Top-level: wires all stages together
│   ├── pc.v                      # Program Counter
│   ├── inst_mem.v                # Instruction memory ($readmemh)
│   ├── if_id.v                   # IF/ID pipeline register
│   ├── control_unit.v            # Main control signals decoder
│   ├── imm_gen.v                 # Immediate generator (all formats)
│   ├── reg_file.v                # 32×32 register file (write-first bypass)
│   ├── id_ex.v                   # ID/EX pipeline register
│   ├── alu.v                     # 32-bit ALU (10 operations)
│   ├── alu_control.v             # ALU control decoder
│   ├── forwarding_unit.v         # EX-EX and MEM-EX forwarding
│   ├── hazard_detection_unit.v   # Load-use stall detection
│   ├── branch_unit.v             # Branch condition evaluator
│   ├── ex_mem.v                  # EX/MEM pipeline register
│   ├── data_mem.v                # Data memory (load/store)
│   └── mem_wb.v                  # MEM/WB pipeline register
│
├── tb/
│   └── tb_riscv_scoreboard.sv    # Scoreboard testbench (assertions + coverage)
│
├── program.mem                   # Test program (hex, loaded by inst_mem)
└── README.md
```

---

## Pipeline Architecture

```
  ┌─────┐   ┌─────┐   ┌────┐   ┌─────┐   ┌────┐
  │ IF  │──▶│ ID  │──▶│ EX │──▶│ MEM │──▶│ WB │
  └─────┘   └─────┘   └────┘   └─────┘   └────┘
    │          │         │         │         │
    │        regfile   ┌─┴─┐     dmem     regfile
    │        imm_gen   │FWD│               write
    │        ctrl_unit └─┬─┘
    │                    │
    │            ┌───────┴────────┐
    │            │  Forwarding    │  EX→EX  (forwardA/B = 10)
    │            │  Unit          │  MEM→EX (forwardA/B = 01)
    │            └────────────────┘
    │
    └── PC stall ◀── Hazard Detection Unit (load-use)
                          Branch flush ◀── Branch Unit
```

### Pipeline Registers

| Register | Signals passed |
|---|---|
| IF/ID | PC, instruction word |
| ID/EX | PC, rd1, rd2, imm, rs1, rs2, rd, funct3, funct7, all control signals |
| EX/MEM | ALU result, rs2 data, rd, RegWrite, MemRead, MemWrite, MemToReg |
| MEM/WB | mem_data, ALU result, rd, RegWrite, MemToReg |

---

## RTL Modules

### `riscv_pipeline.v` — Top Level

Wires all 17 sub-modules. Implements bubble injection via `ControlMux` to safely zero out control signals when the hazard detection unit fires.

```verilog
// Bubble injection (ControlMux = 1 → bubble, = 0 → normal)
assign RegWrite_safe = ControlMux ? 1'b0 : RegWrite;
assign MemRead_safe  = ControlMux ? 1'b0 : MemRead;
// ... (all control signals muxed)
```

### `reg_file.v` — Register File

Synchronous write, combinational read with **write-first bypass**: if the WB stage writes to the same register being read by ID in the same clock cycle, the incoming write data is forwarded directly to prevent stale reads.

```verilog
// Write-first bypass (WB→ID forwarding)
assign rd1 = (rs1 == 5'd0) ? 32'b0 :
             (we && rd != 5'd0 && rd == rs1) ? wd : regs[rs1];
assign rd2 = (rs2 == 5'd0) ? 32'b0 :
             (we && rd != 5'd0 && rd == rs2) ? wd : regs[rs2];
```

### `hazard_detection_unit.v` — Load-Use Stall

Detects load-use hazards. When a LOAD is in the EX stage and the next instruction reads the same register, it:
- Freezes the PC (`PCWrite = 0`)
- Freezes the IF/ID register (`IF_ID_Write = 0`)
- Injects a bubble into the EX stage (`ControlMux = 1`)

```verilog
if (id_ex_MemRead &&
   ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2)) &&
   (id_ex_rd != 5'd0))
begin
    PCWrite    = 1'b0;
    IF_ID_Write = 1'b0;
    ControlMux = 1'b1;   // inject bubble
end else begin
    PCWrite    = 1'b1;
    IF_ID_Write = 1'b1;
    ControlMux = 1'b0;   // pass control signals through
end
```

### `forwarding_unit.v` — Data Forwarding

Implements two forwarding paths to avoid data hazards without stalling:

| forwardA / forwardB | Source | When |
|---|---|---|
| `2'b00` | Register file | No hazard |
| `2'b10` | EX/MEM stage | EX→EX hazard |
| `2'b01` | MEM/WB stage | MEM→EX hazard |

EX forwarding takes priority over MEM forwarding when both apply.

---

## Supported Instructions

| Category | Instructions |
|---|---|
| R-Type | `ADD` `SUB` `AND` `OR` `XOR` `SLL` `SRL` `SRA` `SLT` `SLTU` |
| I-Type ALU | `ADDI` `ANDI` `ORI` `XORI` `SLLI` `SRLI` `SRAI` `SLTI` `SLTIU` |
| Load | `LW` |
| Store | `SW` |
| Branch | `BEQ` `BNE` `BLT` `BGE` `BLTU` `BGEU` |
| Jump | `JAL` `JALR` |
| Upper Imm | `LUI` `AUIPC` |

---

## Hazard Handling

### 1. Data Hazards — Forwarding

When an instruction in EX or MEM needs a result not yet written back, the forwarding unit routes the value directly from the pipeline register instead of waiting.

**Example — EX-EX forward:**
```
add  x3, x1, x2    ← result in EX/MEM
sub  x4, x3, x2    ← needs x3 in EX → gets it via forwardA = 2'b10
```

### 2. Load-Use Hazard — Stall

A LOAD followed immediately by an instruction that uses the loaded value cannot be forwarded (the data isn't available until the end of MEM). One bubble is inserted.

```
lw   x1, 0(x2)     ← LOAD in EX
add  x3, x1, x4    ← needs x1 → stall 1 cycle, then MEM→EX forward
```

### 3. Control Hazard — Branch Flush

When a branch is taken, the two instructions already fetched after the branch (in IF and ID) are invalid. The pipeline flushes them by asserting `flush`, which clears the IF/ID and ID/EX registers.

```
beq  x1, x2, target   ← branch evaluated in EX
<fetched but wrong>    ← flushed
<fetched but wrong>    ← flushed
target: add x3, ...    ← correct instruction
```

---

## Verification Environment

### Testbench: `tb_riscv_scoreboard.sv`

A flat, single-file SystemVerilog testbench. No UVM, no complex class hierarchy — clean and easy to understand.

```
  program.mem ──$readmemh──▶ DUT (riscv_pipeline)
                                   │
                    ┌──────────────┼──────────────┐
                    │              │               │
               Assertions     Pipeline        Covergroups
               (SVA, 7 props)  Monitor        (4 groups)
                    │          (WB events)        │
                    └──────────┐  │  ┌────────────┘
                               ▼  ▼  ▼
                           Scoreboard
                       check_reg() × 17 registers
                               │
                          Final Report
```

### SVA Assertions (7 Properties)

| ID | Property | What it checks |
|---|---|---|
| A1 | `p_x0_never_written` | x0 is never the write target |
| A2 | `p_ex_fwd_rs1` | EX→EX forwarding fires on rs1 |
| A3 | `p_ex_fwd_rs2` | EX→EX forwarding fires on rs2 |
| A4 | `p_mem_fwd_rs1` | MEM→EX forwarding fires on rs1 |
| A5 | `p_load_use_stall` | PC and IF/ID freeze on load-use |
| A6 | `p_pc_plus4` | PC advances by exactly 4 each normal cycle |
| A7 | `p_reset_pc_zero` | PC = 0 one cycle after reset is released |

All assertions use `disable iff (rst)` so they stay quiet during reset.

### Functional Coverage (4 Covergroups)

| Covergroup | What it covers | Result |
|---|---|---|
| `cg_opcode` | Instruction type bins (R, I, load, store, branch, LUI, AUIPC) | 100% |
| `cg_forwarding` | All 3 states of forwardA and forwardB + cross coverage | 85.2% |
| `cg_pipeline_ctrl` | PC stall (0/1) and flush (0/1) | 100% |
| `cg_alu_ops` | All 10 ALU operations (ADD SUB AND OR XOR SLT SLTU SLL SRL SRA) | 100% |

> **Note:** `cg_forwarding` reaches 85.2% because the directed test program does not exercise the case where both forwardA and forwardB are simultaneously in MEM→EX mode. Add a load-store-use sequence to close this gap.

---

## Test Program

`program.mem` — loaded by `$readmemh("program.mem", mem)` in `inst_mem.v`:

```
Hex encoding       Assembly              Expected result
─────────────────────────────────────────────────────────
00A00093           addi x1,  x0,  10    x1  = 10
00500113           addi x2,  x0,  5     x2  = 5
002081B3           add  x3,  x1,  x2    x3  = 15   (EX-EX fwd both)
40208233           sub  x4,  x1,  x2    x4  = 5    (WB-ID bypass)
0041F2B3           and  x5,  x3,  x4    x5  = 5    (15 & 5)
0041E333           or   x6,  x3,  x4    x6  = 15   (15 | 5) → FAIL: was 0
0020C3B3           xor  x7,  x1,  x2    x7  = 15   (10 ^ 5)
00209433           sll  x8,  x1,  x2    x8  = 320  (10 << 5)
002454B3           srl  x9,  x8,  x2    x9  = 10   (320 >> 5, EX-EX fwd)
01402513           slti x10, x1,  20    x10 = 1    (10 < 20)
00000013 × 8       NOP (addi x0,x0,0)   flush pipeline
```
## How to Run

### QuestaSim (Questa / ModelSim)

```bash
# 1. Compile RTL and testbench
vlog -sv rtl/*.v tb/tb_riscv_scoreboard.sv

# 2. Simulate with coverage
vsim -coverage tb_riscv_scoreboard -do "run -all; exit"

# 3. Or use qrun (one command)
qrun -sv rtl/*.v tb/tb_riscv_scoreboard.sv -simulate -top tb_riscv_scoreboard
```

### Icarus Verilog (iverilog)

```bash
iverilog -g2012 -o riscv_sim rtl/*.v tb/tb_riscv_scoreboard.sv
vvp riscv_sim
```

> **Note:** Icarus does not support `assert property` / covergroups. Assertions and coverage sections will be ignored, but the scoreboard register checks will still run.

### EDA Playground

1. Set **Language** to `SystemVerilog/Verilog`
2. Set **Simulator** to `QuestaSim` or `ModelSim`
3. Paste all RTL files into the **Design** panel
4. Paste `tb_riscv_scoreboard.sv` into the **Testbench** panel
5. Upload `program.mem` or paste its hex content
6. Click **Run**

---

## Tools Used

| Tool | Purpose |
|---|---|
| QuestaSim 2025.2 | Simulation, assertion checking, coverage collection |
| Verilog (IEEE 1364-2005) | RTL design |
| SystemVerilog (IEEE 1800-2017) | Testbench, SVA assertions, covergroups |

---

## Key Design Decisions

**Write-first register file bypass** — Instead of relying solely on the forwarding unit to handle the WB→ID same-cycle read, the register file itself detects a concurrent write to the same register and forwards the incoming data directly on the read port. This closes the hazard case that occurs when an instruction is in WB at the same cycle another instruction in ID reads the same register.

**ControlMux convention** — `ControlMux = 1` injects a bubble (forces all control signals to 0), `ControlMux = 0` passes control signals through normally. This is the opposite of the intuitive sense; a comment in `hazard_detection_unit.v` documents the convention to avoid confusion.

**Branch resolved in EX** — Branch conditions are evaluated at the end of the EX stage using the forwarded operand values (after the forwarding mux). This means 2 cycles are always wasted on a taken branch, which is the standard approach for a simple in-order pipeline without branch prediction.

---

## Author

**Harsh Pandey**
ECE, 7th Semester — KIET Group of Institutions, Ghaziabad
Co-Founder & Digital Design Head, VLSI Design Club @ KIET

- Email: harshpandey.vlsi@gmail.com
- Phone: +91-8299587955

---

*Built as part of RTL design internship preparation targeting VLSI and semiconductor companies.*
