# RTOS ↔ FPGA Communication

Communication options between Zephyr RTOS instances and FPGA radar accelerators:

- **CoreAXI4DMA / CoreAXI4Stream** IP for high-throughput transfers.
- **Shared Memory Mailboxes** to pass DMA descriptors and completion flags.
- **Interrupts vs Polling** – Zephyr can either poll shared queues or respond to DMA completion interrupts wired to each U54 hart.

Design checklist:

1. Map shared-memory regions (address, cache policy, security attributes) accessible by Linux, Zephyr, and FPGA masters.
2. Specify interrupt routing per hart to avoid conflicts with Linux.
3. Describe the packet format Zephyr uses to notify Linux of radar frame availability and vice versa.
4. Document any hardware semaphores or mutex IP required for safe buffer sharing.
