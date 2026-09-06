# 使用方法
1. 安装 make, iverilog, riscv64-unknown-elf-gcc, riscv64-unknown-elf-ld, riscv64-unknown-elf-objcopy
2. 在项目目录执行 make
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
