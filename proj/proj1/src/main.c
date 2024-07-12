#include "proj_menu.h"
#include "perf.h"

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

#include "cfu.h"
#include "menu.h"

#define NAME "qn24b base"
#define VER  "version 1.0.1 2004-09-02"
#define MAX 29 /** 32 is a real max! **/
#define MIN 2
#define N   16

#define cfu_init(x)       (cfu_op0(0, x, 0))
#define cfu_kernel()      (cfu_op1(0, 0, 0))
#define cfu_get_ret()     (cfu_op2(0, 0, 0))
#define cfu_get_PC()    (cfu_op3(0, 0, 0))
#define cfu_check_rr()    (cfu_op4(0, 0, 0))
#define cfu_check_a_cdt() (cfu_op5(0, 0, 0))
#define cfu_check_a_col() (cfu_op6(0, 0, 0))
#define cfu_check_a_pos() (cfu_op7(0, 0, 0))

int h = 0;
int r = 0;
int ret = 0;

namespace {
void queens(){
  int i;
  long long answers = 0;

  printf("The size of N: %d\n", N);
  

  for(i=0; i<(N/2+N%2); i++){
    cfu_init(i);
    while(cfu_kernel());
    ret = cfu_get_ret();
    printf("PC: 0x%lx\n", cfu_get_PC());
    answers += ret;
    if(i!=N/2) answers += ret;
  }

  printf("%lld\n", answers);
}

struct Menu MENU = {
    "Project Menu",
    "project",
    {
        MENU_ITEM('0', "N-queens", queens),
        MENU_END,
    },
};

};  // anonymous namespace

extern "C" void do_proj_menu() { menu_run(&MENU); }