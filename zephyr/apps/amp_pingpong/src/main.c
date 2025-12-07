#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/logging/log.h>
#include <zephyr/ipc/ipc_service.h>
#include <zephyr/sys/printk.h>
#include <errno.h>
#include <stdbool.h>
#include <string.h>

#include "amp/shmem_layout.h"

LOG_MODULE_REGISTER(amp_pingpong, CONFIG_LOG_DEFAULT_LEVEL);

#if !DT_HAS_CHOSEN(zephyr_ipc_shm)
#error "zephyr,ipc-shm chosen node is required for OpenAMP"
#endif

#define IPC_INSTANCE_NODE DT_CHOSEN(zephyr_ipc_shm)

static struct ipc_ept ep_handle;
static volatile bool endpoint_ready;

static void amp_bound_cb(void *priv)
{
	ARG_UNUSED(priv);
	endpoint_ready = true;
	LOG_INF("Hart %d endpoint bound", CONFIG_MPFS_HART_INDEX);
}

static void amp_received_cb(const void *data, size_t len, void *priv)
{
	ARG_UNUSED(priv);
	LOG_INF("Hart %d rx (%zu bytes): %s", CONFIG_MPFS_HART_INDEX, len,
		(const char *)data);

	/* Echo payload back to Linux/QNX peer. */
	if (endpoint_ready && len > 0) {
		int rc = ipc_service_send(&ep_handle, data, len);
		if (rc < 0) {
			LOG_ERR("echo failed (%d)", rc);
		}
	}
}

static void amp_error_cb(int reason, void *priv)
{
	ARG_UNUSED(priv);
	LOG_ERR("Hart %d endpoint error %d", CONFIG_MPFS_HART_INDEX, reason);
	endpoint_ready = false;
}

static const struct ipc_service_cb amp_callbacks = {
	.bound = amp_bound_cb,
	.received = amp_received_cb,
	.error = amp_error_cb,
};

static int register_endpoint(void)
{
	const struct device *ipc_instance = DEVICE_DT_GET(IPC_INSTANCE_NODE);
	if (!device_is_ready(ipc_instance)) {
		LOG_ERR("IPC instance not ready");
		return -ENODEV;
	}

	static const struct ipc_endpoint_cfg ep_cfg = {
		.name = "amp-pingpong",
		.cb = &amp_callbacks,
		.priv = NULL,
	};

	int rc = ipc_service_register_endpoint(ipc_instance, &ep_handle, &ep_cfg);
	if (rc < 0) {
		LOG_ERR("Failed to register endpoint (%d)", rc);
		return rc;
	}

	return 0;
}

void main(void)
{
	LOG_INF("AMP ping-pong starting on hart %d", CONFIG_MPFS_HART_INDEX);
	LOG_DBG("Shared memory base 0x%08lx", (unsigned long)AMP_SHMEM_BASE_ADDR);
	LOG_DBG("RPMsg TX base 0x%08lx RX base 0x%08lx", (unsigned long)amp_rpmsg_tx_base(),
		(unsigned long)amp_rpmsg_rx_base());

	if (register_endpoint() < 0) {
		return;
	}

	while (1) {
		if (endpoint_ready) {
			static uint32_t counter;
			char payload[32];
			snprintk(payload, sizeof(payload), "hart%d-%lu", CONFIG_MPFS_HART_INDEX,
				(unsigned long)counter++);
			int rc = ipc_service_send(&ep_handle, payload, strlen(payload) + 1);
			if (rc < 0) {
				LOG_ERR("heartbeat send failed (%d)", rc);
			}
		}

		k_msleep(1000);
	}
}
