#ifndef VECTORGL_H_
#define VECTORGL_H_

#include <system.h>
#include <io.h>

void init_vram();
void switch_frames();
void draw_line_absolute(int, int);
void move_pen_absolute(int, int);

#endif /*VECTORGL_H_*/
