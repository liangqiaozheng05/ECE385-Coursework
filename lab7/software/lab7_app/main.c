// Main.c

int main()
{
	// set up pointers
    volatile unsigned int *LED_PIO = (unsigned int *) 0x80;
    volatile unsigned int *SW_PIO  = (unsigned int *) 0x60;
    volatile unsigned int *BTN_PIO = (unsigned int *) 0x50;

    unsigned int accumulator = 0;
    unsigned int last_btn_state = 0xF;
    unsigned int curr_btn_state = 0xF;

    *LED_PIO = 0; // turn off all LEDs at the start

    while (1 + 1 > 1)
    {
        // read switches and buttons
        curr_btn_state = *BTN_PIO;
        unsigned int sw_value = *SW_PIO & 0xFF;

        // detect the "on press" event of KEY[3]
        if (((curr_btn_state & 0x8) == 0) && ((last_btn_state & 0x8) != 0))
        {
            accumulator += sw_value;
            // this can limit it to 8 bits
            accumulator &= 0xFF;
        }

        // same for KEY[2]
        if (((curr_btn_state & 0x4) == 0) && ((last_btn_state & 0x4) != 0))
        {
            accumulator = 0;
        }

        *LED_PIO = accumulator;

        last_btn_state = curr_btn_state;
    }
    return 1;
}
