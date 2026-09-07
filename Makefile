CC           := riscv64-unknown-elf-gcc
LD           := riscv64-unknown-elf-ld
OBJCOPY      := riscv64-unknown-elf-objcopy
IVERILOG     := iverilog
PYTHON       := python3
YOSYS        := yosys
NEXTPNR_ECP5 := nextpnr-ecp5
ECPPACK      := ecppack


BUILD_DIR    := build


BIN          := $(BUILD_DIR)/test.bin
ELF          := $(BUILD_DIR)/test.elf
OBJ          := $(BUILD_DIR)/test.o
ASM          := tests/test.s
LDSCRIPT     := tests/linker.ld
MEM0         := $(BUILD_DIR)/mem0.hex
MEM1         := $(BUILD_DIR)/mem1.hex
BIN2HEX      := tools/bin2hex.py


SIMFILELIST  := filelists/sim_filelist.f
SIMSRCS      := $(shell cat filelists/sim_filelist.f | grep -v '^$$')
SIM          := $(BUILD_DIR)/sim


SYNSRCS      := $(shell cat filelists/syn_filelist.f | grep -v '^$$')
SYN          := $(BUILD_DIR)/top.bit
CONFIG       := $(BUILD_DIR)/top_out.config
JSON         := $(BUILD_DIR)/top.json
LPF          := fpga/top.lpf


.PHONY: all sim synth clean


all: sim | $(BUILD_DIR)


$(BUILD_DIR):
	mkdir -p $@


$(MEM0) $(MEM1) &: $(BIN) $(BIN2HEX) | $(BUILD_DIR)
	$(PYTHON) $(BIN2HEX) $< $(MEM0) $(MEM1)

$(BIN): $(ELF) | $(BUILD_DIR)
	$(OBJCOPY) -O binary $< $@

$(ELF): $(OBJ) $(LDSCRIPT) | $(BUILD_DIR)
	$(LD) -m elf32lriscv -T $(LDSCRIPT) $< -o $@

$(OBJ): $(ASM) | $(BUILD_DIR)
	$(CC) -c $< -o $@ -march=rv32i_zicsr -mabi=ilp32



sim: $(SIM) | $(BUILD_DIR)
	./$<

$(SIM): $(SIMFILELIST) $(SIMSRCS) $(MEM0) $(MEM1) | $(BUILD_DIR)
	$(IVERILOG) -o $@ -f $<


synth: $(SYN) | $(BUILD_DIR)
	@set -e; D=$$(find /run/media/$$USER -maxdepth 1 -name iCELink 2>/dev/null | head -1); \
	if [ -z "$$D" ]; then echo "iCELink 盘未挂载，请先挂载后再 make prog"; exit 1; fi; \
	cp $(SYN) $$D/ && sync && echo "已复制到 $$D，固件自动烧写中…"

$(SYN): $(CONFIG) | $(BUILD_DIR)
	$(ECPPACK) --input $< --bit $@

$(CONFIG): $(JSON) $(LPF) | $(BUILD_DIR)
	$(NEXTPNR_ECP5) --25k --package CABGA256 --speed 6 --json $(JSON) --textcfg $@ --lpf $(LPF) --freq 65

$(JSON): $(SYNSRCS) $(MEM0) $(MEM1) | $(BUILD_DIR)
	$(YOSYS) -p "read_verilog -sv $(SYNSRCS); hierarchy -top top; synth_ecp5 -json $(JSON)"


clean:
	rm -rf $(BUILD_DIR)
