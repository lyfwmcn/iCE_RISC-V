# AGENTS.md

Course-style Chinese Verilog project: a pipelined RV32I + Zicsr RISC-V core (M/S/U privilege, CSR, traps/exceptions, paging) for iCESugar-Pro (ECP5) / iCESugar (iCE40). Simulation-first. **Design reference (encodings/CSR/exception tables, Chinese) lives in `docs/RV32I_Zicsr_Ref.md`**; `README.md` is only a short toolchain/usage quickstart. Everything builds and runs from the repo root via one Makefile.

## Directory layout (get this right — it changed before)

- `src/` — CPU RTL: `CPU.v` plus stage/unit modules (no testbench here).
- `sim/` — simulation-only: `sim/SystemBus.v` (behavioral `reg [7:0] mem[4095:0]`, loads `build/test.bin` via `$fopen`) and `sim/tb.v` (dumps `build/wave.vcd`, prints mem[100..107]+`CPU.RegFile.regs` at t=1000ns then `$finish`).
- `syn/` — synthesis-only board shell: `top.v`, `top.lpf`, `SystemBus.v` (ECP5 EBR lane variant), `report.v`, `rst_gen.v`, `uart_tx.v`.
- **There are two `module SystemBus` variants (`sim/SystemBus.v` vs `syn/SystemBus.v`). They must keep identical module name and port list** — CPU drives the same bus in both `sim/tb.v` and `syn/top.v`. Change memory behavior in the matching variant; a port change must land in both.
- `filelists/sim_filelist.f` and `filelists/syn_filelist.f` — iverilog (sim) and yosys (syn) source lists. Both include `src/*`. `sim` list adds `sim/tb.v` + `sim/SystemBus.v`; `syn` list adds the `syn/*` RTL and **must not** contain any tb. New files go into the right list or the tool won't see them.
- `tests/` — programs: `tests/test.s` is **the single program for both sim and board**; `tests/<Category>/test.s` are samples (R, S, B, Load, J, Jalr, ArithmeticI, CSR). `tests/linker.ld` lays out only `.text` at 0x0 (no `.text.system`/handler section anymore).
- `tools/bin2hex.py` — `build/test.bin` → `build/mem0.hex` + `build/mem1.hex` (EBR lane words, 4KB zero-padded).
- riscv-tests glue (see below): `tools/run_rv32ui.sh`, `tools/rv32i_env/riscv_test.h`, `tests/link_rv32ui.ld`, `sim/tb_rv32ui.v`. `sim/tb_rv32ui.v` is compiled ad hoc (not in `sim_filelist.f`).
- `build/` — all artifacts (gitignored).

## Commands (must run from repo root — paths are root-relative)

- `make` / `make sim` — assemble `tests/test.s` → `build/test.bin`, iverilog `-f filelists/sim_filelist.f`, run `build/sim`. Sim SystemBus reads `build/test.bin` at runtime; tb writes `build/wave.vcd`.
- `make synth` — yosys (`syn_filelist.f`, EBR INIT from `build/mem*.hex`) → nextpnr-ecp5 → ecppack → `build/top.bit`, **then auto-programs the board** via drag-drop (requires iCELink mounted at `/run/media/$USER/iCELink`; errors otherwise). If the new config doesn't start, replug USB to reload from SPI flash. The board program is always the current `tests/test.s`.
- `make clean` — removes `build/`.
- Toolchain: `riscv64-unknown-elf-{gcc,ld,objcopy}`, `iverilog`, `python3`, `yosys`/`nextpnr-ecp5`/`ecppack`. Assembly: `-march=rv32i_zicsr -mabi=ilp32`. No test framework, lint, or CI.
- Arch ECP5 tools: `pacman -S prjtrellis prjtrellis-db`. If nextpnr is the archlinuxcn `-git` build, use `prjtrellis-db-git` instead — the release db crashes ecppack with `row_bias`.

## Running a categorized test

- Copy `tests/<Category>/test.s` over `tests/test.s`, then `make sim`. Verify via stdout and `build/wave.vcd`. Programs conventionally end `flag: j flag`.

## riscv-tests (rv32ui) runner

- External suite kept in a sibling clone (default `~/Projects/Verilog/riscv-tests`; override with `RISCV_TESTS`). Run `tools/run_rv32ui.sh [name...]` — no args runs all of `isa/rv32ui`, prints `PASS/FAIL/TIMEOUT` per test + summary, non-zero exit on any failure. It only writes `build/` artifacts.
- Pipeline: compile `isa/rv32ui/<n>.S` with `-I tools/rv32i_env` FIRST (so it overrides `env/p/riscv_test.h`), link `tests/link_rv32ui.ld` (`.text`@0, `.tohost`@0xC00, whole image ≤4KB), `objcopy` → `build/test.bin`, run `sim/tb_rv32ui.v`, which polls `mem[0xC00]` (`1`=PASS, other=fail code, no write=timeout).
- The override header has two deliberate patches: forces the test body to run in **M mode** (`mstatus.MPP=3`) because the core only reliably handles M-mode traps; and strips `fence` from `RVTEST_PASS/FAIL` because the core has **no FENCE decode** (opcode 0x0f → illegal). The real fix is to decode FENCE as NOP.
- Known non-CPU blockers: `fence_i` needs `zifencei`; `ld_st`'s image exceeds 4KB (linker overlap). Last verified matrix over 44 rv32ui tests: 30 PASS / 12 FAIL / 2 COMPILE_FAIL. Unresolved CPU bugs surfaced: `bgeu`, `bltu`, and several `lh/lhu/lw/sb/sh/sw/st_ld/ma_data` assertions — chase each with a minimal case before trusting the suite.

## Microarchitecture (wiring in `src/CPU.v`)

- Pipeline `IF → ID → EX → M1 → M2 → WB`; M1 issues the data-bus request, M2 consumes the response with alignment/fault checks.
- Hazard/forwarding units instantiated in `CPU.v`: `RegByPass` (GPR fwd + `RegWait`), `CSRHazard` (CSR RAW → `CSRWait`), `TrapCSRByPass`. Stalls `RegWait|CSRWait|MemWait`; flushes `ActualJump|PredJump|Trap|Ret`.
- Memory: 4KB, access must be aligned and within 0x0–0xFFF; misaligned/out-of-range accesses fault and stores are dropped (both SystemBus variants enforce this).

## Board observability (`syn/report.v`)

- A store to mailbox **0xF00** triggers a UART dump of the 32-word report window **0xE00–0xE7F** (8 hex + CRLF per word, then `PASS`), repeating every ~1 s. LEDs: 001=dumping, 111=PASS steady, blink=FAIL (timeout: mailbox never written).
- So a board program must store results to 0xE00.. and write 0xF00. **Burning a `tests/<Cat>` copy that never writes 0xF00 → FAIL blink and no serial** (silent-looking). The default `tests/test.s` already does both.
- Board: ECP5 LFE5U-25F CABGA256, clk **P6 = 25 MHz**, RGB LED {A11,A12,B11} (measured: A12=blue), UART **TX=B9 → iCELink USB-CDC** `/dev/ttyACM0` @115200. A11/A12/B11/B9 share an IO bank: keep them all **LVCMOS33** in `syn/top.lpf` or nextpnr rejects mixed bank voltages. CRLF is handled; bare LF makes terminals staircase. ModemManager may steal the port and eat automated captures — manual terminals usually work.

## Testing pitfalls (learned the hard way)

- `tb.v` samples **once at t=1000ns (~100 cycles) and is not a correctness oracle**. A real bug (taken-branch redirect left stale in-flight prefetch in `InstrBufferUnit.v`; fixed) made the CPU run off into zero padding and trap-loop to `mtvec=0`; restarts rewrote registers to identical values, hiding it from the 1000ns snapshot.
- Cheap detector: `j loop` immediately followed by a store you never expect to run (sentinel) — if the sentinel address is nonzero, a taken branch leaked. For loop/branch/flush changes, raise tb's sample time and confirm the PC parks in the intended loop with zero traps before trusting reg dumps.
- `mtvec` resets to 0 and there is no default handler in current `tests/linker.ld`; trap tests must both `csrw mtvec` and (re)add a handler section to the linker script.

## Editor (optional, gitignored `.vscode/`)

- Verilog-HDL/SystemVerilog ext: built-in features only index the open file. Cross-file module jumps work with verible-verilog-ls enabled (`verilog.languageServer.veribleVerilogLs.enabled`) — no `verible.filelist` needed (verified; verible resolves modules across the workspace on its own).
