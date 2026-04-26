#include "firmware.h"
#include "mcu_uq.h"


//Bit specification for SPI_CTRL register
#define TIMER_SRC       8
#define TIMER_MODE      6
#define OUTA_MODE       4
#define OUTB_MODE       2
#define TMR_I_MSK       1
#define TMR_F           0

volatile uint32_t * TIMER_CNT[] = { &TIMER_CNT0, &TIMER_CNT1 };
volatile uint32_t * TIMER_TOP[] = { &TIMER_TOP0, &TIMER_TOP1 };
volatile uint32_t * PWM_CNTA[] = { &PWM_CNTA0, &PWM_CNTA1 };
volatile uint32_t * PWM_CNTB[] = { &PWM_CNTB0, &PWM_CNTB1 };
volatile uint16_t * TIMER_CTRL[] = { &TIMER_CTRL0, &TIMER_CTRL1 };


//Set the timer period in microseconds (Use internal CPU clock)
void timer_initialize(int timer_id, uint32_t useconds)
{
    //Input: CPU clock, Timer OFF, no PWM output, no Interrupts.
    *TIMER_CTRL[timer_id] = 0B0111000000;
    *TIMER_TOP[timer_id] = TIME_US_TO_TICK(useconds);
}

//Set the timer to use external input signal (Set also top count)
void timer_initialize_extinput(int timer_id, uint32_t top_count) {
    //Input: External signal, Timer OFF, no PWM output, no Interrupts.
    *TIMER_CTRL[timer_id] = 0B1011000000;
    *TIMER_TOP[timer_id] = top_count;
}

//Start the timer in normal mode
void timer_start(int timer_id) {
    *TIMER_CNT[timer_id] = 0;
    *TIMER_CTRL[timer_id] &= 0B1100111111;
}

//Stop the timer
void timer_stop(int timer_id) {
    *TIMER_CTRL[timer_id] |= 0B0011000000;
}

//Return current timer count
uint32_t timer_count(int timer_id) {
    return *TIMER_CNT[timer_id];
}

//Generates PWM on a specified pin
void timer_pwm(int timer_id, int pin, int signal_shape, int dutyCycle) {
    uint32_t val = (*TIMER_CNT[timer_id]*dutyCycle)/100;
    if (pin == 0) {
        *TIMER_CTRL[timer_id] = (1<<TIMER_SRC) | (signal_shape<<TIMER_MODE) | (2<<OUTA_MODE);
        *PWM_CNTA[timer_id] = val;
    } else {
        *TIMER_CTRL[timer_id] = (1<<TIMER_SRC) | (signal_shape<<TIMER_MODE) | (2<<OUTB_MODE);
        *PWM_CNTB[timer_id] = val;
    }
}

//Disables PWM on a specified pin
void timer_disable_pwm(int timer_id, int pin) {
    if (pin == 0) {
        *TIMER_CTRL[timer_id] &= ~(3<<OUTA_MODE);
    } else {
        *TIMER_CTRL[timer_id] &= ~(3<<OUTB_MODE);
    }
}

//Delay in microseconds
void delay_us(int timer_id, uint32_t useconds) {
    timer_initialize(timer_id, useconds);
    timer_start(timer_id);
    while( (*TIMER_CTRL[timer_id] & 1) == 0);
}
