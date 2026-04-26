#include <stdint.h>
#include <stdbool.h>
#include "mcu_uq.h"

// ----------------------- Config -----------------------
#define APP_BASE   ((uint32_t)0x30000800u)
#define BOOT_PIN   (15u)
#define LED_PIN    (2u)

// ----------------------- UART MMIO --------------------
// Bits
#define UART_ON         9
#define UART_BITS       8
#define UART_PARITY     6
#define UART_STOPBITS   5
#define UART_WRITE      4
#define UART_AVAIL      3

#define UART_BAUDRATE_TO_TICKS(baudrate) ((50000000u/(uint32_t)(baudrate))-1u)
#define UART_PARITY_NONE 0

static inline void uart_begin_min(uint32_t baudrate)
{
    UART_BITRATE = UART_BAUDRATE_TO_TICKS(baudrate);
    UART_CTRL = (1u<<UART_ON) | (1u<<UART_BITS) | (UART_PARITY_NONE<<UART_PARITY) | (0u<<UART_STOPBITS);
}

static inline bool uart_available(void)
{
    return (UART_CTRL & (1u<<UART_AVAIL)) != 0;
}

static inline uint8_t uart_read_u8_blocking(void)
{
    while (!uart_available()) {}
    return UART_DATA_IN;
}

static inline void uart_write_u8(uint8_t ch)
{
    UART_DATA_OUT = ch;
    UART_CTRL |= (1u<<UART_WRITE);
    while (UART_CTRL & (1u<<UART_WRITE)) {}
}

static void uart_write_str(const char *s)
{
    while (*s) uart_write_u8((uint8_t)*s++);
}

static void uart_write_hex32(uint32_t v)
{
    for (int i = 7; i >= 0; i--) {
        uint8_t nib = (v >> (i*4)) & 0xF;
        uart_write_u8((uint8_t)(nib < 10 ? ('0'+nib) : ('A'+(nib-10))));
    }
}

static uint32_t read_u32_le_blocking(void)
{
    uint32_t v = 0;
    for (int i = 0; i < 4; i++) {
        v |= ((uint32_t)uart_read_u8_blocking()) << (8*i);
    }
    return v;
}

// FLASH = RAM por ahora
static void mem_write(uint32_t addr, const uint8_t *buf, uint32_t len)
{
    volatile uint8_t *p = (volatile uint8_t *)addr;
    for (uint32_t i = 0; i < len; i++) p[i] = buf[i];
}

static void mem_read(uint32_t addr, uint8_t *buf, uint32_t len)
{
    volatile const uint8_t *p = (volatile const uint8_t *)addr;
    for (uint32_t i = 0; i < len; i++) buf[i] = p[i];
}

static void jump_to_app(void)
{
    void (*app_reset)(void) = (void(*)(void))APP_BASE;
    app_reset();
}

static inline bool boot_pin_is_pressed(void)
{
    GPIO_DIR &= ~(1u << BOOT_PIN);
    asm volatile ("nop; nop;");
    return (GPIO_DATA_IN & (1u << BOOT_PIN)) != 0;
}

// -------------------- Boot protocol --------------------
// 'U' + LEN(u32 LE) + BIN     -> write @ APP_BASE
// 'R' + OFF(u32) + LEN(u32)   -> read  @ APP_BASE+OFF, send bytes
// 'J'                         -> jump to app

static void cmd_upload(void)
{
    uint32_t len = read_u32_le_blocking();

    /*uart_write_str("LEN=0x");
    uart_write_hex32(len);
    uart_write_str("\r\n");

    if (len == 0 || len > (112u * 1024u)) {
        uart_write_str("ERR: bad len\r\n");
        return;
    }*/

    uint8_t chunk[256];
    uint32_t remaining = len;
    uint32_t dst = APP_BASE;

    while (remaining) {
        uint32_t n = remaining > sizeof(chunk) ? (uint32_t)sizeof(chunk) : remaining;
        for (uint32_t i = 0; i < n; i++) chunk[i] = uart_read_u8_blocking();
        mem_write(dst, chunk, n);
        dst += n;
        remaining -= n;
    }

    uart_write_u8(0x55);   // ACK upload
}

static void cmd_read(void)
{
    uint32_t off = read_u32_le_blocking();
    uint32_t len = read_u32_le_blocking();

    if (len > 2048u || off + len > (128u*1024u)) { uart_write_u8(0xEE); return; }
    
    // ACK + payload
    uart_write_u8(0xAA);
    volatile const uint8_t *p = (volatile const uint8_t *)(APP_BASE + off);
    for (uint32_t i = 0; i < len; i++) uart_write_u8(p[i]);
}


static void cmd_jump(void)
{
    uart_write_u8(0xCC);
    for (volatile int i=0;i<50000;i++) asm volatile("nop");
    jump_to_app();
}

void boot_main(void)
{
    GPIO_DIR |= (1u << LED_PIN);
    GPIO_DATA_OUT |= (1u << LED_PIN);

    uart_begin_min(115200);
    uart_write_str("\r\nUQ Bootloader\r\nAPP @ 0x");
    uart_write_hex32(APP_BASE);
    uart_write_str("\r\n");

    // Si NO se presiona -> app
    if (!boot_pin_is_pressed()) {
        uart_write_str("BOOT: jump to app\r\n");
        jump_to_app();
    }

    uart_write_str("BOOT: stay in bootloader\r\n");
    uart_write_str("Cmds: U(upload) R(read) J(jump)\r\n");

    while (1) {
        uint8_t c = uart_read_u8_blocking();

        if (c == (uint8_t)'U') {
            cmd_upload();
        } else if (c == (uint8_t)'R') {
            cmd_read();
        } else if (c == (uint8_t)'J') {
            cmd_jump();
        } else {
            uart_write_str("?\r\n");
        }
    }
}

