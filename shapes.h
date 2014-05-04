#ifndef SHAPES_H_
#define SHAPES_H_

#include "vectorgl.h"

#include "bool.h"

typedef struct {
    unsigned int x, y;
} point;

typedef struct {
    point llc, urc;
} box;

typedef struct {
    signed int dx, dy;
} vector;

typedef struct {
    int n;
    box bb;
    point d[];
} shape;

void move(point *p, vector *v);
void draw(shape *s, point *p);
bool bounce(shape *s, point *p, vector *v, box *b);
bool collide( shape *s1, shape *s2, point *p1, point *p2,
              vector *v1, vector *v2);

#endif /*SHAPES_H_*/
