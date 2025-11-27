# Deployment Scripts

Flashing, network boot, and runtime provisioning helpers belong here:

- `flash-sd-card.sh` – writes Yocto images plus HSS payload to removable media.
- `load-hss-payload.py` – uses Microchip's tools to push payloads over UART/JTAG.
- `deploy-zephyr-via-amp.sh` – requests HSS to restart a specific hart with a new RTOS image.

Each script should log artifact versions and target serial numbers for traceability.
