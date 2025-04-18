#include "syscall-init.h"
#include "stdint.h"
#include "thread.h"
#include "print.h"
#include "syscall.h"
#include "console.h"
#include "../string.h"
#include "memory.h"

#define syscall_nr 32
typedef void* syscall;
syscall syscall_table[syscall_nr];

/*  第0个子功能返回当前任务的pid */
uint32_t sys_getpid(void)
{
	return running_thread()->pid;
}

/* 打印字符串str（未实现文件系统前的版本）*/
uint32_t sys_write(char* str)
{
	console_put_str(str);
	return strlen(str);
}

/* 初始化系统调用,注册子功能函数 */
void syscall_init(void)
{
	put_str("syscall_init start\n");
	syscall_table[SYS_GETPID] = sys_getpid;
	syscall_table[SYS_WRITE] = sys_write;
	syscall_table[SYS_MALLOC] = sys_malloc;
	syscall_table[SYS_FREE] = sys_free;
	put_str("syscall_init done\n");
}