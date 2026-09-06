CC        := riscv64-unknown-elf-gcc
LD        := riscv64-unknown-elf-ld
OBJCOPY   := riscv64-unknown-elf-objcopy
IVERILOG  := iverilog
PYTHON    := python


BUILD_DIR := build


BIN       := $(BUILD_DIR)/test
ELF       := $(BUILD_DIR)/test.elf
OBJ       := $(BUILD_DIR)/test.o
ASM       := tests/test.s
LDSCRIPT  := tests/linker.ld
FILELIST  := filelist.f
SIM       := $(BUILD_DIR)/sim
MEM0      := $(BUILD_DIR)/mem0.hex
MEM1      := $(BUILD_DIR)/mem1.hex
BIN2HEX   := tools/bin2hex.py
SRCS      := $(shell cat filelist.f)


.PHONY: all clean

all: $(SIM) | $(BUILD_DIR)
	./$<

$(SIM): $(FILELIST) $(SRCS) $(MEM0) $(MEM1) | $(BUILD_DIR)
	$(IVERILOG) -o $@ -f $(FILELIST)

$(MEM0) $(MEM1) &: $(BIN) | $(BUILD_DIR)
	$(PYTHON) $(BIN2HEX) $< $(MEM0) $(MEM1)

$(BIN): $(ELF) | $(BUILD_DIR)
	$(OBJCOPY) -O binary $< $@

$(ELF): $(OBJ) $(LDSCRIPT) | $(BUILD_DIR)
	$(LD) -m elf32lriscv -T $(LDSCRIPT) $< -o $@

$(OBJ): $(ASM) | $(BUILD_DIR)
	$(CC) -c $< -o $@ -march=rv32i_zicsr -mabi=ilp32

$(BUILD_DIR):
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR)
