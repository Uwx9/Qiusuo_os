#include "timer.h"
#include "print.h"
#include "io.h"
#include "thread.h"
#include "debug.h"
#include "interrupt.h"

#define IRQ0_FREQUENCY      100
#define INPUT_FREQUENCY     1193180
#define COUNTER0_VAULE      INPUT_FREQUENCY / IRQ0_FREQUENCY
#define COUNTER0_PORT       0x40
#define COUNTER0_NO         0
#define COUNTER0_MODE       2
#define READ_WRITE_LATCH    3
#define PIT_CONTROL_PORT    0x43

uint32_t ticks;		//ticks是内核自中断开启以来总共的嘀嗒数,这个词还挺可爱

/* 把操作的计数器counter_no､读写锁属性rwl､计数器模式 
 * counter_mode写入模式控制寄存器并赋予初始值counter_value */
static void frequency_set(uint8_t counter_port,        
                          uint8_t counter_no,          
                          uint8_t rwl,                 
                          uint8_t counter_mode,        
                          uint16_t counter_value)       
{
    /* 往控制字寄存器端口0x43中写入控制字 */ 
    outb(PIT_CONTROL_PORT, (uint8_t)(counter_no<<6 | rwl<<4 | counter_mode<<1));
    
    /* 写入counter_value，先低8位，后高8位 */
    outb(counter_port, (uint8_t)counter_value);
    outb(counter_port, (uint8_t)(counter_value>>8));
}

/* 时钟的中断处理函数 */
static void intr_timer_handler(void)
{
	put_str("\ntime interrupt occur \n");
	struct task* cur_thread = running_thread();
	ASSERT(cur_thread->stack_magic == 0x20050608);
	cur_thread->elapsed_ticks++;		//记录此线程占用的cpu时间
	ticks++;							//从内核第一次处理时间中断后开始至今的滴哒数，内核态和用户态总共的嘀哒数
	if (cur_thread->ticks == 0) {		//若进程时间片用完，就开始调度新的进程上cpu 	
		schedule();
	} else {
		cur_thread->ticks--;			//将当前进程的时间片-1
	}

}

/* 初始化PIT8253 */ 
void timer_init()
{
    put_str("time_init start\n");
    /* 设置 8253的定时周期，也就是发中断的周期 */ 
    frequency_set(COUNTER0_PORT, COUNTER0_NO, READ_WRITE_LATCH, COUNTER0_MODE, COUNTER0_VAULE);                     
	register_handler(0x20, intr_timer_handler);
    put_str("time_init done\n");
}
