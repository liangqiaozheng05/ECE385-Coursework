# ECE385 Coursework

ECE385 课程作业与 FPGA 实验项目展示，包含 Lab 3–9 及期末项目。

This repository contains ECE385 coursework, FPGA lab projects, and a final project. It is published solely as a portfolio and demonstration of course work.

## 学术诚信与使用声明 / Academic Integrity and Usage Notice

**本仓库仅供展示，禁止抄袭。请勿将这里的代码、设计或其修改版本作为你自己的课程作业、实验或项目提交，也不得代交、分享作业答案或用于其他违反课程学术诚信要求的行为。**

**Do not plagiarize. Do not submit any code, designs, or modified versions from this repository as your own coursework, lab work, or project, or use them to facilitate academic misconduct. Follow your institution's and course's academic integrity policies.**

公开可见不代表授予开源使用许可。除平台条款允许的查看和 fork 外，本仓库原创作业内容未授予复制、修改、再发布或商业使用的许可；如有其他使用需求，请事先取得相应权利人的明确许可。课程提供的模板、第三方代码、厂商 IP 及相关组件的权利归各自权利人所有，其原有声明和适用条款继续有效。

Public visibility does not grant an open-source license. Apart from viewing and forking permitted by the platform's terms, no permission is granted to copy, modify, redistribute, or commercially use the original coursework without the relevant rights holder's prior permission. Course-provided templates, third-party code, vendor IP, and related components remain subject to their respective notices and terms.

## 内容 / Contents

- `lab3/`: Lab 3 project.
- `lab4adder/`: Lab 4 adder project.
- `lab5/`: Lab 5 project.
- `lab6/`: Lab 6 project.
- `lab7/`: Lab 7 project.
- `Lab8/`: Lab 8 project.
- `Lab9/`: Lab 9 project.
- `ECE385labFinal/`: FPGA rhythm-game final project. See its existing README for project details.

## 工程说明 / Project Notes

工程包含 SystemVerilog/Verilog、C 源码、Quartus 工程和 Qsys 系统配置。编译缓存、日志、烧录输出及本地 IDE 临时文件不纳入版本控制。打开对应目录中的 Quartus 工程；如需构建 Nios II 软件，可能需要按本地工具版本重新生成 Qsys 系统和 BSP。

The projects include SystemVerilog/Verilog and C source files, Quartus projects, and Qsys system configurations. Build caches, logs, programming outputs, and local IDE temporary files are excluded. Open the relevant Quartus project; Qsys systems and Nios II BSPs may need regeneration for your local toolchain.
