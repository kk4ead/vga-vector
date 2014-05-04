#include <system.h>
#include <io.h>
#include "vectorgl.h"

#define FRAME_0 0
#define FRAME_1 512

#define OP_NOP 0
#define OP_MOV 1
#define OP_JMP 2
#define OP_BEAM_OFF 0
#define OP_BEAM_ON  1

int frame_starts[] = {0, 512};
int frame_ends[]   = {0, 512};
int current_frame  = 0;

int current_x = 0, current_y = 0;

#define OFFSET (frame_ends[current_frame])
#define OTHER_FRAME (current_frame ? 0 : 1)

int byte_swap(int x) {
    return (x << 8) | (x >> 8);
}

void write(int data) {
    IOWR_16DIRECT(VRAM_BASE, OFFSET, byte_swap(data));
}

void write_op(int opcode, int data) {
    write((data & 1023) | ((opcode & 0x3f) << 10));
}

void switch_frames() {
    write_op(OP_JMP,frame_starts[current_frame]);
    current_frame = OTHER_FRAME;
    write_op(OP_JMP,frame_starts[OTHER_FRAME]);
    OFFSET = 0;
}
       
void draw_line_absolute(int x, int y) {
    unsigned int xgy, max, min, min2, shifts;
    x &= 1023;
    y &= 1023;
    
    int delta_x = x - current_x;
    int delta_y = y - current_y;
    
    if (delta_x <  0) { delta_x = -delta_x; }
    if (delta_y <  0) { delta_y = -delta_y; }

// BEGIN SPEED COMPUTE
    xgy = (delta_x > delta_y) ? 1 : 0;
    max = xgy ? delta_x : delta_y;
    min = xgy ? delta_y : delta_x;
    if (max==0) max = 1;
    if (min==0) min = max;
    min2 = min;

    for (shifts = 0; max < 0x8000; shifts++) {
        max <<= 1;
        min <<= 1;
    }

    max /= min2;
    min /= min2;
    
    if (min2 < 0x0100) min2 = 0x0020;
    
    for (shifts = 0; min >= min2 || max >=0x100; shifts++) {
        max >>= 1;
        min >>= 1;
    }
    
    if (min == 0) min = 1;

    delta_x = xgy ? max : min;
    delta_y = xgy ? min : max;
// END SPEED COMPUTE
   
    current_x = x;
    current_y = y;
    
    write_op(OP_MOV,x);
    OFFSET+=2;
    write_op(OP_BEAM_ON,y);
    OFFSET+=2;
    write(delta_x);
    OFFSET+=2;
    write(delta_y);
    OFFSET+=2;      
}
    
void move_pen_absolute(int x, int y) {
    current_x = x;
    current_y = y;
    
    write_op(OP_MOV,x);
    OFFSET+=2;
    write_op(OP_BEAM_OFF,y);
    OFFSET+=2;
    write(0xffff);
    OFFSET+=2;
    write(0xffff);
    OFFSET+=2;   
}

void init_vram() {
  int i;
  for (i=0; i<VRAM_SPAN; i+=2)
    IOWR_16DIRECT(VRAM_BASE, i, 0);
}
