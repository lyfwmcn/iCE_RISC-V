CC = riscv64-unknown-elf-gcc
LD = riscv64-unknown-elf-ld
OBJCOPY = riscv64-unknown-elf-objcopy
IVERILOG = iverilog

BIN = $(BIN_DIR)/test
ELF = $(BIN_DIR)/test.elf
OBJ = $(BIN_DIR)/test.o
ASM = $(ASM_DIR)/test.s
LDSCRIPT = $(ASM_DIR)/linker.ld
FILELIST = filelist.f
SIM = $(BIN_DIR)/sim
VCD = $(BIN_DIR)/wave.vcd

ASM_DIR = asm
BIN_DIR = bin

.PHONY: all clean

all: $(SIM) | $(BIN_DIR)
	./$<

$(SIM): $(FILELIST) $(BIN) | $(BIN_DIR)
	$(IVERILOG) -o $@ -f $<

$(BIN): $(ELF) | $(BIN_DIR)
	$(OBJCOPY) -O binary $< $@

$(ELF): $(OBJ) | $(BIN_DIR)
	$(LD) -m elf32lriscv -T $(LDSCRIPT) $< -o $@

$(OBJ): $(ASM) | $(BIN_DIR)
	$(CC) -c $< -o $@ -march=rv32i_zicsr -mabi=ilp32

$(BIN_DIR):
	mkdir -p $@

clean:
	rm -f $(OBJ) $(ELF) $(BIN) $(SIM) $(VCD)
