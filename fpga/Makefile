# iCESugar-Pro 板级工程：CPU + SystemBus + 观测(report/uart) 综合/布线/打包。
#
# 板级程序是 fpga/prog.s（与仿真用的 asm/test.s 解耦）。工具链组装出
# build/prog.bin 后由 tools/bin2hex.py 生成 SystemBus 需要的 EBR INIT hex
# （直接覆盖 bin/mem0.hex、bin/mem1.hex，重新跑根目录 `make` 会复原为 test.s 的）。
# 注意：yosys 需在仓库根目录运行，$readmemh 的相对路径才能解析到 bin/。

ROOT     = ..
ROOTABS  = $(abspath $(ROOT))
B        = build

V       := top.v rst_gen.v uart_tx.v report.v
VABS    := $(abspath $(V))
SRCS    := $(shell ls $(ROOT)/src/*.v | grep -v '/tb\.v$$')
SRCSABS := $(abspath $(SRCS))

JSON    = $(B)/top.json
CONFIG  = $(B)/top_out.config
BIT     = top.bit

CC      = riscv64-unknown-elf-gcc
LD      = riscv64-unknown-elf-ld
OBJCOPY = riscv64-unknown-elf-objcopy
BIN2HEX = $(ROOTABS)/tools/bin2hex.py

PG_O   = $(B)/prog.o
PG_ELF = $(B)/prog.elf
PG_BIN = $(B)/prog.bin


.PHONY: all clean prog
all: $(BIT)

$(BIT): $(CONFIG)
	ecppack --input $(CONFIG) --bit $@

$(CONFIG): $(JSON) top.lpf
	nextpnr-ecp5 --25k --package CABGA256 --speed 6 --json $(JSON) --textcfg $@ --lpf top.lpf --freq 65

# hexgen 为 phony：每次建 bit 都强制从 fpga/prog.s 重新生成 mem hex，
# 避免被仓库根目录 `make`（asm/test.s）覆盖过的旧 hex 静默混入 bitstream。
.PHONY: hexgen
hexgen: $(PG_BIN)
	python3 $(BIN2HEX) $< $(ROOTABS)/bin/mem0.hex $(ROOTABS)/bin/mem1.hex

$(JSON): $(V) $(SRCS) hexgen | $(B)
	cd $(ROOTABS) && yosys -p "read_verilog -sv $(VABS) $(SRCSABS); hierarchy -top top; synth_ecp5 -json $(ROOTABS)/fpga/$(JSON)"

$(PG_BIN): $(PG_ELF) | $(B)
	$(OBJCOPY) -O binary $< $@

$(PG_ELF): $(PG_O) | $(B)
	$(LD) -m elf32lriscv -T $(ROOTABS)/asm/linker.ld $< -o $@

$(PG_O): prog.s | $(B)
	$(CC) -c $< -o $@ -march=rv32i_zicsr -mabi=ilp32

$(B):
	mkdir -p $@

# 拖拽盘已在 /run/media/.../iCELink 挂载时直接拷贝（DAPLink 自动烧录）
prog: $(BIT)
	@set -e; D=$$(find /run/media/$$USER -maxdepth 1 -name iCELink 2>/dev/null | head -1); \
	if [ -z "$$D" ]; then echo "iCELink 盘未挂载，请先挂载后再 make prog"; exit 1; fi; \
	cp $(BIT) $$D/ && sync && echo "已复制到 $$D，固件自动烧写中…"

clean:
	rm -rf $(B) $(BIT)
