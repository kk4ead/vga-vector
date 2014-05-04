#include <system.h>
#include <io.h>
#include "shapes.h"
#include "chrome.h"
#include "alt_up_ps2_port.h"
#include "ps2_keyboard.h"
#include <sys/alt_irq.h>
#include <altera_avalon_timer_regs.h>

point  b_pos = {500, 500},
       p_pos = { 25,   400};
vector b_spd = {  5,  -6},
       p_spd = {  0,   0};

void render() {
    IOWR_ALTERA_AVALON_TIMER_STATUS (TIMER_BASE, 0);
    
    move(&p_pos, &p_spd); 
 
    if (p_pos.y > 800 || p_pos.y < 0) {
        p_pos.y = (p_pos.y < 2048 && p_pos.y > 0) ? 800 : 0;
    }
    
    if (collide(&BALL, &PADDLE, &b_pos, &p_pos,
            &b_spd, &p_spd)) {
        b_spd.dx  = -b_spd.dx + 10;
        b_spd.dy += (b_pos.y - p_pos.y - 99) / 10;   
    }
    else if (b_pos.x + b_spd.dx < p_pos.x || b_pos.x + b_spd.dx > 2048) {
        b_pos.x = 500;
        b_pos.y = 500,
        b_spd.dx = -10;
        b_spd.dy = -10;
    }
    
    if (b_spd.dy > 40) b_spd.dy = 40;
    if (b_spd.dy < -40) b_spd.dy = -40;
    
    bounce(&BALL, &b_pos, &b_spd, &SCREEN);
    move(&b_pos, &b_spd);
    if (b_pos.y < 0 || b_pos.y > 1023) b_pos.y = 0;
    
    draw(&BALL,&b_pos);
    draw(&PADDLE,&p_pos);
    switch_frames();

}

void get_key() {
    KB_CODE_TYPE decode_mode;
    alt_u8 key=0;

    if (read_make_code(&decode_mode, &key) == PS2_SUCCESS) {
        switch (decode_mode) {
            case KB_ASCII_MAKE_CODE:
            case KB_BINARY_MAKE_CODE:
            case KB_LONG_BINARY_MAKE_CODE:
                if (key & 1) p_spd.dy += 25;
                else p_spd.dy -= 25;
            break;
            
            case KB_BREAK_CODE:
            case KB_LONG_BREAK_CODE:
                p_spd.dy = 0;
            break;
            
            default: break;
        }
    }
}

int main() {

  alt_irq_register(TIMER_IRQ, (void*) 0, (void*) render);

  IOWR_ALTERA_AVALON_TIMER_CONTROL (TIMER_BASE, 
            ALTERA_AVALON_TIMER_CONTROL_ITO_MSK  |
            ALTERA_AVALON_TIMER_CONTROL_CONT_MSK |
            ALTERA_AVALON_TIMER_CONTROL_START_MSK);
/*
  switch (get_mode()) {
    case PS2_KEYBOARD: p_pos.y = 400; break;
    case PS2_MOUSE: p_pos.y = 0; break;
    default: p_pos.y = 100; break;
  }
*/
  init_vram();
  render(); 
    
  for (;;) {
    get_key();

  }
}

