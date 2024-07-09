#include <console.h>
#include <generated/csr.h>
#include <generated/mem.h>
#include <generated/soc.h>
#include <stdio.h>

#include <irq.h>
#include <libbase/uart.h>
#include <libbase/console.h>

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <assert.h>

#include "riscv.h"

#define NAME "qn24b base"
#define VER  "version 1.0.1 2004-09-02"
#define MAX 32 /** 32 is a real max! **/
#define MIN 2
#define N   10

typedef struct array_t{
  unsigned int cdt; /* candidates        */
  unsigned int col; /* column            */
  unsigned int pos; /* positive diagonal */
  unsigned int neg; /* negative diagonal */
} array;

unsigned int reg_h    = 0;
unsigned int reg_r    = 0;
unsigned int reg_ret  = 0;

array a[MAX];

void cfu_init(int i) {
    reg_ret  = 0;
    reg_h    = 1;      /* height or level  */
    reg_r    = 1 << i; /* candidate vector */
    a[1].col = (1<<N)-1;
    a[1].pos = 0;
    a[1].neg = 0;
}

unsigned int total = 0;
unsigned int count = 0;
int cfu_kernel(void) {
  ++total;
  int w_bool = !(reg_r == 0 && reg_h == 1);
  int lsb1 = (~reg_r + 1) & reg_r;
  int r2 = (a[reg_h].col & ~lsb1) & ~((a[reg_h].pos |  lsb1) << 1 | (a[reg_h].neg |  lsb1) >> 1);
  int lsb2 = (~r2 + 1) & r2;
  int lsb3 = (-a[reg_h].cdt) & a[reg_h].cdt;
  //bool w_bool = !(!reg_r && reg_h == 1);
  if (reg_r) {
    a[reg_h+1].cdt = (       reg_r & ~lsb1);
    a[reg_h+1].col = (a[reg_h].col & ~lsb1);
    a[reg_h+1].pos = ((a[reg_h].pos |  lsb1) << 1);
    a[reg_h+1].neg = ((a[reg_h].neg |  lsb1) >> 1);

    reg_r = a[reg_h+1].col & ~(a[reg_h+1].pos | a[reg_h+1].neg);
    reg_h = reg_h + 1;
  } else {
    if (reg_h == N + 1) reg_ret = reg_ret + 1;
    reg_r = a[reg_h].cdt;
    reg_h = reg_h - 1;
  }

  assert(reg_h >= 0);

  return w_bool; 
}

int cfu_get_ret(void) {
    return reg_ret;
}


void queens(){
  int i;
  int answers = 0;

  printf("The size of N: %d\n", N);
  
  for(i=0; i<(N/2+N%2); i++){
    cfu_init(i);
    while(cfu_kernel());

    int sub = cfu_get_ret();
    answers += sub;
    if(i!=N/2) answers += sub;
  }

  printf("%d\n", answers);
  printf("---\n");
}

int main(void) {
#ifdef CONFIG_CPU_HAS_INTERRUPT
	irq_setmask(0);
	irq_setie(1);
#endif
	uart_init();
  


  queens();
  int x = opcode_R(0x0B, 1, 0, 0, 0);
  printf("%d\n", total);
  return 0;
}