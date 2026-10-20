# ECE385labFinal

Rhythm game on FPGA board, mainly based on lab8.

# Qsys Part:

## Legacy

Nios II process

SDRAM Controller: main memory, for C code and music data

JTAG UART

USB IO: otg_hpi_address, otg_hpi_data, otg_hpi_cs, for keyboard

## Game control IO

Score_PIO (Output, 32-bit)
TODO, Nios II calculates the score and writes it here, and VGA can draw it.

score_pio



Note_Spawn_PIO (Output, 8-bit)
TODO, Nios II write command here based on the rhythm (0001 for 1 note in track #1).
VGA can draw based on this.

note_spawn_pio



Also need Note_Hit_PIO,

to destroy the corresponding trail's note after input. 

note_hit_pio



Interval Timer (Hardware Timer)
TODO, provides an accurate 1ms interrupt for global music timing to replace while-loop counting.

timer_1ms

**1. Interval Timer (硬件定时器 - 你们的时间基准)**

- 在左侧元件库搜索 `Interval Timer`。
- **设置**：Period 设为 `1 ms`，Counter Size 设为 `32-bit`。
- **连线**：
  - `clk` 连到系统的 50MHz 时钟。
  - `reset` 连到系统复位。
  - `s1` (Avalon Memory Mapped Slave) 连到 Nios II 的 `data_master`。
  - **最重要的一步**：在最右侧的 `IRQ` 栏，把该定时器的圆圈点亮，连接到 Nios II，让它分配一个中断号。
- **重命名**：右键改名为 `timer_1ms`。

**2. Score_PIO (32位输出 - 传输分数与连击)**

- 搜索 `PIO (Parallel I/O)`。
- **设置**：Width: `32` bits，Direction: `Output`。
- **连线**：`clk`, `reset`, `s1` 分别连好。
- **导出 (Export)**：在 `External Connection` 那一列，双击并填入 `score_pio`。这会让它在 `.sv` 顶层文件里露出来。
- **重命名**：右键改名为 `score_pio`。

**3. Note_Spawn_PIO (8位输出 - 触发生成)**

- 新建一个 PIO。
- **设置**：Width: `8` bits，Direction: `Output`。
- **连线**：同上。
- **导出**：填入 `note_spawn_pio`。
- **重命名**：`note_spawn_pio`。

**4. Note_Hit_PIO (8位输出 - 触发销毁)**

- 新建一个 PIO。
- **设置**：Width: `8` bits，Direction: `Output`。
- **连线**：同上。
- **导出**：填入 `note_hit_pio`。
- **重命名**：`note_hit_pio`。

**分配基地址**：点击菜单栏的 `System` -> `Assign Base Addresses`，消除所有地址冲突的报错。

**生成 HDL**：点击右下角的 `Generate HDL...`。

**编译 Quartus**：回到 Quartus 主界面，不用急着改 `.sv` 代码，直接点击绿色的播放键 **Start Compilation**，等待它生成最新的 `.sopcinfo` 文件。

**生成 BSP**：打开 Eclipse，右键点击你们的 `bsp` 工程 -> `Nios II` -> `Generate BSP`。

**查阅 `system.h`**：打开 `bsp` 目录下的 `system.h`，检查 Qsys 给你们生成的宏到底叫什么（比如是叫 `SCORE_PIO_BASE` 还是 `SCORE_PIO_0_BASE`），然后把你们 `main.c` 和 `rhythm_engine.c` 里的宏名字统一修改。



## Sound IO

TODO, for Nios II to feed sound data to sound card.

# SV Part:

lab_final_toplevel.sv
TODO, original lab8.sv, line up Qsys, VGA and sound. Instantiate it.=

Still need to polish



vga_controller.sv, hpi_io_intf.sv
Legacy, generate VGA synchronized signals, deal with data from and to USB chip.



note_manager.sv
FINISHED, original ball.sv.
Since rhythm game needs smooth scrolling, we need sv file to maintain some arrays to keep the alive notes's Y information in track.
When VGA_VS received, they will fall based on current speed (or just 1).
Signal "Note_Spawn_PIO" will let it generate a new note at the top.
*Note: To support the 3D effect, this module should also output scaling parameters so notes get wider as Y increases.*



color_mapper.sv
FINISHED, Based on (DrawX, DrawY), decide the color.
If UI area, from font_rom, draw score, and "perfect" responses.
If in note block, draw block.
Then draw track color and bg.
*TODO: try to narrow the top area to create pseudo-3D effect.*

TODO: also try to add sprite



audio_driver
TODO, turn signal to music.

# C part

main.c
FINISHED, state machine (MENU, PLAYING, PAUSE, GAME OVER).
While playing:
play music -> check beatmap.h -> read keyboard -> get score -> update PIO.

usb.c / io_handler.c
Legacy, poll EZ-OTG.

beatmap.h
FINISHED, store "what note appears in what time".
Store {timestamp, track number}.

rhythm_engine.c
FINISHED, when key pressed, get current music time and the corresponding expected note time, calculate delta T.
Give response (Perfect, Great, Miss), add score, write into Score_PIO.