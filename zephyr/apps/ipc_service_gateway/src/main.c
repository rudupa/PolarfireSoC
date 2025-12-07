// SPDX-License-Identifier: MIT
#include <ctype.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/logging/log.h>
#include <zephyr/ipc/ipc_service.h>
#include <zephyr/sys/util.h>

LOG_MODULE_REGISTER(ipc_gateway, CONFIG_LOG_DEFAULT_LEVEL);

#define READY_BANNER "ipc_service_gateway: ready"
#define RX_BUF_SIZE   256
#define RADAR_PROFILE_MAX 32

static K_SEM_DEFINE(bound_sem, 0, 1);
static struct ipc_ept endpoint;
static uint8_t rx_cache[RX_BUF_SIZE];
static char tx_buf[RX_BUF_SIZE];
static bool radar_active;
static char radar_profile[RADAR_PROFILE_MAX] = "idle";

static void send_response_fmt(const char *fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	int len = vsnprintf(tx_buf, sizeof(tx_buf) - 2, fmt, args);
	va_end(args);
	if (len < 0) {
		LOG_ERR("failed to format response");
		return;
	}
	if (len > (int)(sizeof(tx_buf) - 2)) {
		len = sizeof(tx_buf) - 2;
	}
	tx_buf[len++] = '\n';
	tx_buf[len] = '\0';
	int ret = ipc_service_send(&endpoint, tx_buf, len);
	if (ret != 0) {
		LOG_ERR("response send failed (%d)", ret);
	}
}

static void endpoint_bound(void *priv)
{
	ARG_UNUSED(priv);
	LOG_INF("endpoint bound to Linux peer");
	k_sem_give(&bound_sem);
}

static void endpoint_unbound(void *priv)
{
	ARG_UNUSED(priv);
	LOG_WRN("endpoint unbound; waiting for rebind");
}

static void endpoint_received(const void *data, size_t len, void *priv)
{
	ARG_UNUSED(priv);
	size_t copy_len = MIN(len, sizeof(rx_cache) - 1);
	memcpy(rx_cache, data, copy_len);
	rx_cache[copy_len] = '\0';
	LOG_INF("rx %u bytes: %s", (unsigned)copy_len, (char *)rx_cache);

	char *msg = (char *)rx_cache;
	/* Trim leading whitespace. */
	while (*msg != '\0' && isspace((unsigned char)*msg)) {
		msg++;
	}
	if (*msg == '\0') {
		return;
	}
	char *end = msg + strlen(msg) - 1;
	while (end > msg && isspace((unsigned char)*end)) {
		*end-- = '\0';
	}

	char *args = msg;
	while (*args != '\0' && !isspace((unsigned char)*args)) {
		*args = toupper((unsigned char)*args);
		args++;
	}
	if (*args != '\0') {
		*args++ = '\0';
		while (*args != '\0' && isspace((unsigned char)*args)) {
			args++;
		}
	}

	const char *arg_str = (*args != '\0') ? args : NULL;

	if (strcmp(msg, "PING") == 0) {
		send_response_fmt("PONG");
	} else if (strcmp(msg, "STATUS") == 0) {
		uint64_t uptime = k_uptime_get();
		send_response_fmt("STATUS uptime_ms=%llu radar_active=%s profile=%s",
			(unsigned long long)uptime,
			radar_active ? "true" : "false",
			radar_active ? radar_profile : "idle");
	} else if (strcmp(msg, "RADAR_START") == 0) {
		if (arg_str == NULL || arg_str[0] == '\0') {
			send_response_fmt("ERR RADAR_START requires profile");
			return;
		}
		strncpy(radar_profile, arg_str, sizeof(radar_profile) - 1);
		radar_profile[sizeof(radar_profile) - 1] = '\0';
		radar_active = true;
		send_response_fmt("RADAR_START profile=%s", radar_profile);
	} else if (strcmp(msg, "RADAR_STOP") == 0) {
		radar_active = false;
		send_response_fmt("RADAR_STOP ok");
	} else if (strcmp(msg, "HELP") == 0) {
		send_response_fmt("HELP commands=PING,STATUS,RADAR_START <profile>,RADAR_STOP");
	} else {
		send_response_fmt("ERR unknown=%s", msg);
	}
}

static struct ipc_ept_cfg endpoint_cfg = {
	.name = "ipc_gateway",
	.cb = {
		.bound = endpoint_bound,
		.received = endpoint_received,
		.unbound = endpoint_unbound,
	},
};

static const struct device *get_ipc_device(void)
{
#if DT_NODE_HAS_STATUS(DT_NODELABEL(rpmsg0), okay)
	return DEVICE_DT_GET(DT_NODELABEL(rpmsg0));
#elif DT_HAS_CHOSEN(zephyr_ipc_shm)
	return DEVICE_DT_GET(DT_CHOSEN(zephyr_ipc_shm));
#else
#error "No RPMsg backend chosen for ipc_service_gateway"
#endif
}

void main(void)
{
	const struct device *ipc_dev = get_ipc_device();

	if (!device_is_ready(ipc_dev)) {
		LOG_ERR("IPC device %s not ready", ipc_dev->name);
		return;
	}

	int ret = ipc_service_register_endpoint(ipc_dev, &endpoint, &endpoint_cfg);
	if (ret != 0) {
		LOG_ERR("ipc_service_register_endpoint failed (%d)", ret);
		return;
	}

	k_sem_take(&bound_sem, K_FOREVER);
	send_response_fmt("%s", READY_BANNER);

	while (true) {
		k_sleep(K_SECONDS(5));
	}
}
