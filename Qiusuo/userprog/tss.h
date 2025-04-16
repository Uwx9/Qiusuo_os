#ifndef __USERPROG_TSS_H
#define __USERPROG_TSS_H
#include "stdint.h"
#include "thread.h"

void update_tss_esp(struct task* pthread);
void tss_init(void);
#endif 