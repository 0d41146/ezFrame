#include <console.h>
#include <generated/csr.h>
#include <generated/mem.h>
#include <generated/soc.h>
#include <stdio.h>

#include <irq.h>
#include <libbase/uart.h>
#include <libbase/console.h>

int main(void) {
  #ifdef CONFIG_CPU_HAS_INTERRUPT
	irq_setmask(0);
	irq_setie(1);
#endif
	uart_init();
  
  printf("Hello, %s!\n", "World");
  
  return 0;
}