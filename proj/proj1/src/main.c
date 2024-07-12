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
#define N   16

#define CUSTOM0 0x0B
#define cfu_init(x)   opcode_R(CUSTOM0, 0, 0, x, 0)
#define cfu_kernel()  opcode_R(CUSTOM0, 1, 0, 0, 0)
#define cfu_get_ret() opcode_R(CUSTOM0, 2, 0, 0, 0)

void queens(){
  int i;
  long long answers = 0;

  printf("The size of N: %d\n", N);
  
  for(i=0; i<(N/2+N%2); i++){
    cfu_init(i);
    while(cfu_kernel());
    int ret = cfu_get_ret();
    answers += ret;
    if(i!=N/2) answers += ret;
  }

  printf("%lld\n", answers);
  printf("---\n");
}

int main(void) {
#ifdef CONFIG_CPU_HAS_INTERRUPT
	irq_setmask(0);
	irq_setie(1);
#endif
	uart_init();
  


  queens();

  printf("===END===\n");
  return 0;
}