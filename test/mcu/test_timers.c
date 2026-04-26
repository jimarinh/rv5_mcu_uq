#include <firmware.h>

void test() {
	int i;

    print_str("TIMER0 Test\n");
	
    timer_initialize(0, 100);
    timer_start(0);
    for(i=0; i<100; i++) {
        print_dec(timer_count(0));
        print_chr(' ');
    }

    print_str("PWM Signals on TIMER0\n");
    timer_pwm(0, 0, FAST_PWM, 50);
    timer_pwm(0, 1, FAST_PWM, 20);
    for(i=0; i<100; i++) { }


    print_str("TIMER1 Test\n");
	
    timer_initialize(0, 100);
    timer_start(0);
    for(i=0; i<100; i++) {
        print_dec(timer_count(0));
        print_chr(' ');
    }

    print_str("PWM Signals on TIMER1\n");
    timer_pwm(0, 0, FAST_PWM, 50);
    timer_pwm(0, 1, FAST_PWM, 20);


    print_str("Delay test on TIMER0\n");
    delay_us(0, 100);
}