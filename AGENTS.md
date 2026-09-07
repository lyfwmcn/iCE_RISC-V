# AGENTS.md

Chinese Verilog project: a pipelined RV32I + Zicsr RISC-V core (M/S/U privilege, CSR, traps/exceptions, paging) for Lattice ECP5/iCE40 (iCESugar-Pro/iCESugar). Course-style, simulation-first. `README.md` (Chinese) is the authoritative design spec for instruction encodings, CSR layout, and exception/interrupt priority & detection order.

## Commands

- Everything is simulation-only. `make` compiles `asm/test.s`, links at 0x0, objcopies to binary, then `tools/bin2hex.py` splits it into `bin/mem0.hex` + `bin/mem1.hex` (EBR lane words, 4KB zero-padded). iverilog (`-f filelist.f`) runs, then `bin/sim` executes. No test framework, lint, or CI.
- Must run from the repo root: `SystemBus.v` `$readmemh`s the hex files and `tb.v` dumps VCD to `./bin/wave.vcd` via relative paths.
- The sim binary rebuilds whenever any `filelist.f` source changes (Makefile lists `SRCS` from it) or the program/hex change.
- `make clean` removes artifacts (incl. sim and the hex files).
- Toolchain: `riscv64-unknown-elf-{gcc,ld,objcopy}` + `iverilog`. Assembly is built with `-march=rv32i_zicsr -mabi=ilp32`.
- New `src/*.v` files must be appended to `filelist.f` or iverilog won't see them.
- Synthesis resource sanity check (stat only, no P&R): `bash synth/analyze.sh`. It reads all `src/*.v` **except `tb.v`** (this yosys rejects tb's `forever #5`); ECP5 is the active target; iCESugar/ice40 lines are commented.
- ECP5 board toolchain (Arch): `yosys` + `nextpnr-ecp5` + `ecppack`. Install `prjtrellis prjtrellis-db` (extra). If your nextpnr is the archlinuxcn `-git` build, install `prjtrellis-db-git` instead — the release db makes ecppack crash with `row_bias` on nextpnr-git output.

## Running a categorized test

- The DUT program is always `asm/test.s`. Samples live as `tests/<Category>/test.s` (R, S, B, Load, J, Jalr, ArithmeticI, CSR). Copy one to `asm/test.s`, then `make`.
- Programs conventionally end with an infinite `flag: j flag` loop. `tb.v` is fixed: prints mem bytes + `CPU.RegFile.regs[*]` at t=1000ns then `$finish`. Verify via stdout and `bin/wave.vcd`.

## Microarchitecture (wiring lives in `CPU.v`)

- Pipeline is `IF → ID → EX → M1 → M2 → WB`; both M1 and M2 are memory stages (request originates in M1, bus response is consumed in M2 with alignment/fault checks).
- Cross-cutting hazard/forwarding units instantiated in `CPU.v`: `RegByPass` (GPR forwarding + `RegWait` stall), `CSRHazard` (CSR RAW hazard → `CSRWait`), `TrapCSRByPass` (forwards a CSR being written in WB into the same-cycle trap-entry logic). Global controls: stall `RegWait|CSRWait|MemWait`, flush `ActualJump|PredJump|Trap|Ret`.
- `SystemBus` provides the 4KB memory. It is written for ECP5 EBR (words split across 9-bit byte lanes, true dual-port: A=data, B=instr fetch). **Program bytes reach memory via `$readmemh("bin/mem0.hex"/"bin/mem1.hex")`** — this runs in simulation and, under yosys, becomes EBR INIT so the same hex is burned into the bitstream for real hardware. A byte-view `mem` mirror exists under `synthesis translate_off` for simulation, rebuilt from the lane arrays at time 0 (so `tb.v` can print bytes). Access is aligned and within 0x0–0xFFF only; misaligned/out-of-range accesses fault and stores are dropped.

## Trap-handler gotcha

- `linker.ld` puts `.text` at 0x0 and `.text.system` at 0x200. Put handler code in a `.text.system` section (e.g. `csrw mtvec` in a test expecting traps to reach 0x200).
- `mtvec` resets to 0x0 and has no default handler — it must be written by software first.

## FPGA board flow (`fpga/`, iCESugar-Pro ECP5)

- Board facts: ECP5 **LFE5U-25F CABGA256**, clk **P6 = 25 MHz**, RGB LED {A11,A12,B11} (measured: A12=blue), UART **TX=B9 → iCELink USB-CDC** `/dev/ttyACM0` @115200. Those pins share an IO bank: use **LVCMOS33** for A11/A12/B11 and B9 together, or nextpnr rejects mixed bank voltages.
- Board program is `fpga/prog.s` (decoupled from sim's `asm/test.s`). Build & pack: `make -C fpga top.bit` (run from the repo root so SystemBus `$readmemh` finds `bin/mem*.hex`).
- Program the board: mount the iCELink drive (`udisksctl mount -b /dev/sda` → `/run/media/$USER/iCELink`), copy `top.bit` onto it (DAPLink drag-drop), wait until the file is consumed; if the new config doesn't start by itself, **replug USB** to reload from SPI flash.
- **GOTCHA (silent wrong-program burn):** repo-root `make` overwrites `bin/mem0.hex`/`mem1.hex` from `asm/test.s`. `fpga/Makefile`'s `hexgen` is **phony** and regenerates those hex files from `prog.s` before every synth, so `top.bit` always embeds `prog.s`. Keep that dependency — otherwise the last `make`'s program (which may never write the 0xF00 mailbox) gets burned and the board shows PASS-LED blink with **no serial output**.
- Harness: `top.v` = CPU + SystemBus + `report.v` + `uart_tx.v` + `rst_gen.v` (internal reset; the board has no reset button). `report.v` taps the data-bus request ports: aligned stores to the report window **0xE00–0xE7F (32 words)** are snapshotted; a store to the mailbox **0xF00** triggers a UART dump (8 hex + **CRLF** per word, then `PASS`), repeated every ~1 s. LEDs: 001=dumping, 111=PASS (steady), blink=FAIL (timeout: mailbox never written). `fpga/prog.s` stores result regs at 0xE00.. then `sw x0,0xF00`.
- Read output: `picocom -b 115200 /dev/ttyACM0` (host baud must equal the FPGA's 115200). CRLF is already handled; bare LF makes terminals staircase. ModemManager may steal the port and eat automated captures — a manual terminal usually still works.

## Long-run regression (branch/flush history)

- `tb.v` samples only at t=1000 ns (~100 cycles) and is **not** a correctness oracle. A real bug (taken-branch redirect left stale in-flight prefetch in `InstrBufferUnit.v`; fixed) made the CPU fall off into the zero-padded tail and trap-loop to `mtvec=0`, which rewrote registers to identical values and masked the fault.
- Fast detector: sentinel pattern in `asm/test.s` — `j loop` immediately followed by `addi/sw` writing `mem[104]`; the sentinel runs only if the branch fails to redirect. Correct CPU: `104: 00`.
- Stronger check: 300 µs CPU-only harnesses `fpga/tb2.v` / `fpga/tb_dbg.v`; pass = zero traps and PC parked in the loop. Repro programs `fpga/dbg_{a,b,c}.s` + handler `fpga/dbg_handler.s` (`csrw mtvec,0x200`; handler stores mepc/mcause to 0xE00 then spins).
- After touching `BU.v`, `IDU.v`, `InstrBufferUnit.v`, `SystemBus.v`, or any fetch/flush logic, rerun a 300 µs long-run (`dbg_b`+`dbg_c`) in addition to the 1000 ns category tests.
