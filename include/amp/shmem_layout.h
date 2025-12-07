// SPDX-License-Identifier: MIT
// Shared memory, mailbox, and interrupt layout for the PolarFire SoC AMP stack.

#ifndef AMP_SHMEM_LAYOUT_H
#define AMP_SHMEM_LAYOUT_H

#include <stdint.h>

#define AMP_SHMEM_BASE_ADDR        0xB8000000ULL
#define AMP_SHMEM_TOTAL_SIZE       0x00200000ULL

#define AMP_MAILBOX_BASE_ADDR      AMP_SHMEM_BASE_ADDR
#define AMP_MAILBOX_SIZE           0x00010000ULL
#define AMP_MAILBOX_CHANNEL_COUNT  8
#define AMP_MAILBOX_CH_STRIDE      0x00000040ULL

#define AMP_RPMSG_TX_BASE_ADDR     (AMP_MAILBOX_BASE_ADDR + AMP_MAILBOX_SIZE)
#define AMP_RPMSG_TX_SIZE          0x00080000ULL
#define AMP_RPMSG_RX_BASE_ADDR     (AMP_RPMSG_TX_BASE_ADDR + AMP_RPMSG_TX_SIZE)
#define AMP_RPMSG_RX_SIZE          0x00080000ULL
#define AMP_DMA_STAGE_BASE_ADDR    (AMP_RPMSG_RX_BASE_ADDR + AMP_RPMSG_RX_SIZE)
#define AMP_DMA_STAGE_SIZE         0x000C0000ULL

#define AMP_MAILBOX_DOORBELL_SET_OFFSET   0x00
#define AMP_MAILBOX_DOORBELL_CLR_OFFSET   0x04
#define AMP_MAILBOX_STATUS_OFFSET         0x08
#define AMP_MAILBOX_PAYLOAD_OFFSET        0x10

#define AMP_MAILBOX_REG(base, ch, off) \
    ((volatile uint32_t *)((base) + ((uint64_t)(ch) * AMP_MAILBOX_CH_STRIDE) + (off)))

#define AMP_MAILBOX_DOORBELL_SET(ch) AMP_MAILBOX_REG(AMP_MAILBOX_BASE_ADDR, (ch), AMP_MAILBOX_DOORBELL_SET_OFFSET)
#define AMP_MAILBOX_DOORBELL_CLR(ch) AMP_MAILBOX_REG(AMP_MAILBOX_BASE_ADDR, (ch), AMP_MAILBOX_DOORBELL_CLR_OFFSET)
#define AMP_MAILBOX_STATUS(ch)      AMP_MAILBOX_REG(AMP_MAILBOX_BASE_ADDR, (ch), AMP_MAILBOX_STATUS_OFFSET)

enum amp_mailbox_channel {
    AMP_MAILBOX_CH_LINUX_RX = 0,
    AMP_MAILBOX_CH_LINUX_TX,
    AMP_MAILBOX_CH_ZEPHYR_U54_1,
    AMP_MAILBOX_CH_ZEPHYR_U54_2,
    AMP_MAILBOX_CH_ZEPHYR_U54_3,
    AMP_MAILBOX_CH_QNX,
    AMP_MAILBOX_CH_FPGA_CTRL,
    AMP_MAILBOX_CH_RESERVED,
};

#define AMP_IHC_IRQ_LINUX_RX   63
#define AMP_IHC_IRQ_U54_1      62
#define AMP_IHC_IRQ_U54_2      61
#define AMP_IHC_IRQ_U54_3      60
#define AMP_IHC_IRQ_U54_4      59

static inline uintptr_t amp_rpmsg_tx_base(void)
{
    return (uintptr_t)AMP_RPMSG_TX_BASE_ADDR;
}

static inline uintptr_t amp_rpmsg_rx_base(void)
{
    return (uintptr_t)AMP_RPMSG_RX_BASE_ADDR;
}

static inline uintptr_t amp_dma_stage_base(void)
{
    return (uintptr_t)AMP_DMA_STAGE_BASE_ADDR;
}

#endif /* AMP_SHMEM_LAYOUT_H */
