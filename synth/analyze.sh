#!/bin/bash

# CPU
# iCESugar-Pro v1.3
yosys -p 'read_verilog -sv src/*.v; hierarchy -top CPU; synth_ecp5; stat'

# iCESugar v1.5
# yosys -p 'read_verilog -sv src/*.v; hierarchy -top CPU; synth_ice40; stat'

# SystemBus
# yosys -p "read_verilog -sv src/SystemBus.v; hierarchy -top SystemBus; synth_ecp5; stat"
