#include "firmware.h"
#include "mcu_uq.h"


void wdt_enable(uint32_t time_ms) {
	uint32_t wdt_tick = TIME_MS_TO_TICK(time_ms);
	WATCHDOG_CTRL = 0x80000000 | wdt_tick;
}

void wdt_disable() {
	WATCHDOG_CTRL = 0;
}

void wdt_reset() {
	WATCHDOG = 0;
}
