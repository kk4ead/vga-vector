#ifndef CHROME_H_
#define CHROME_H_

#include "shapes.h"

box SCREEN = {
    {10,10},
    {1023,1023}
};

shape BALL = {
    4,
    { {0,0}, {25,25} },
    {
      {25, 0},
      {25,25},
      { 0,25},
      { 0, 0}
    }
};

shape PADDLE = {
    4,
    { {0,0}, {25,199} },
    {
      {25,  0},
      {25,199},
      { 0,199},
      { 0,  0}
    }
};

#endif /*CHROME_H_*/
