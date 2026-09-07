# 平台及工具链
1. 平台：x86_64 Linux
2. 工具链：make, iverilog, riscv64-unknown-elf-gcc, python3, yosys, nextpnr-ecp5, ecppack
# 使用方法
## 模拟
1. 在项目根目录执行 make/make all/make sim
## 综合
1. 连接电脑和 iCESugar-Pro v1.3
2. 挂载到 /run/media/$USER
3. 在项目根目录执行 make synth
# 开发进度
## 目前实现的异常处理机制
1. 将发现的先后顺序作为优先级选出异常
2. 如果有异常，将权限改为 M
3. 修改 mstatus.MPP
4. 将异常指令地址写入 mepc
5. 按照各自的规则写入 mtval
6. 修改 mcause
7. 直接跳转到 mtvec
## 目前实现的返回机制
1. 将 MPP 加载到特权级
2. MPP 清零
3. 跳转到 mepc
