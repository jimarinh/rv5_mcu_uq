#include <firmware.h>

void test(void)
{
	print_str("hello world\n");
	wdt_enable(0x100);
	print_str("This string will be interrupted by Watchdog\n");
}

