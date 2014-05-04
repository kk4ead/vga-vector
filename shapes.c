#include "shapes.h"

void move(point *p, vector *v) {
    p->x += v->dx;
    p->y += v->dy;
} 

void draw(shape *s,  point *p) {
    int i;
    move_pen_absolute(p->x, p->y);
    for (i=0; i < s->n; i++)
        draw_line_absolute(s->d[i].x + p->x, s->d[i].y + p->y);
}

bool bounce( shape *s,  point *p,  vector *v,  box *b) {
    bool result = false;
    
    if ( (p->x + s->bb.llc.x + v->dx < b->llc.x) ||
         (p->x + s->bb.urc.x + v->dx > b->urc.x) ) {
        v->dx = -(v->dx);
        result = true;
    }
    
    if ( (p->y + s->bb.llc.y + v->dy < b->llc.y) ||
         (p->y + s->bb.urc.y + v->dy > b->urc.y) ) {
        v->dy = -(v->dy);
        result = true;
    }
        
    return result;
}        

bool collide( shape *s1, shape *s2, point *p1, point *p2,
              vector *v1, vector *v2) {
    box bb1, bb2;
    bb1.llc.x = s1->bb.llc.x + p1->x + v1->dx;
    bb1.urc.x = s1->bb.urc.x + p1->x + v1->dx;
    bb2.llc.x = s2->bb.llc.x + p2->x + v2->dx;
    bb2.urc.x = s2->bb.urc.x + p2->x + v2->dx;
    bb1.llc.y = s1->bb.llc.y + p1->y + v1->dy;
    bb1.urc.y = s1->bb.urc.y + p1->y + v1->dy;
    bb2.llc.y = s2->bb.llc.y + p2->y + v2->dy;
    bb2.urc.y = s2->bb.urc.y + p2->y + v2->dy;
    
    return
     (( (bb1.urc.x > bb2.llc.x && bb1.urc.x < bb2.urc.x) ||
         (bb1.llc.x > bb2.llc.x && bb1.llc.x < bb2.urc.x) ||
         (bb1.llc.x < bb2.llc.x && bb1.urc.x > bb2.urc.x) ) &&
       ( (bb1.urc.y > bb2.llc.y && bb1.urc.y < bb2.urc.y) ||
         (bb1.llc.y > bb2.llc.y && bb1.llc.y < bb2.urc.y) ||
         (bb1.llc.y < bb2.llc.y && bb1.urc.y > bb2.urc.y) ));    
}

