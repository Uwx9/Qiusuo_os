[bits 32]
%define ERROR_CODE nop
%define ZERO push 0
extern put_str
extern idt_func_table            	;idt_table是interrupt.c中注册的中断处理程序数组

section .data
global intr_entry_table
intr_entry_table:		   			;中断入口地址数组,不仅作为入口会跳转到中断处理函数本体,
                           			;还要负责中断本体返回后的善后工作(维护栈)

%macro VECTOR 2
section .text
intr%1entry:                		;每个中断处理程序都要压入中断向量号,所以一个中断类型一个中断处理程序
    %2					    		;ZERO宏是push 0，中断若有错误码会压在eip后面

    ;以下是保存上下文(c调用汇编)，无特权级变化时eflags，cs，eip，error_code自动压栈
    push ds
    push es 
    push fs
    push gs 
    pushad                  		;压入32位寄存器,入栈顺序是EAX,ECX,EDX,EBX,ESP,EBP,ESI,EDI

;如果是从片上进入的中断，除了往从片上发送EOI外，还要往主片上发送EOI
    mov al, 0x20            		;中断结束命令EOI 
    out 0xa0, al            		;向从片发送
    out 0x20, al            		;向主片发送 

    push %1                 		;不管idt_table中的目标程序是否需要参数都一律压入中断向量号,调试时很方便

    call [idt_func_table + %1*4] 	;调用idt_table中的C版本中断处理函数,idt_table+%1*4是数组元素的地址用[]取值
    jmp intr_exit

section .data
    dd intr%1entry					;定义一个32位数据，存储intr%1entry的值，是该标号的地址

%endmacro

section .text 
global intr_exit
intr_exit:
    ;以下是恢复上下文
    add esp, 4              		;跳过中断号
    popad                   		;popad 在执行弹栈时，栈中esp的值会被忽略
    pop gs
    pop fs 
    pop es 
    pop ds 
    add esp, 4              		;跳过error_code或故意压入用于对齐的0,esp指向栈顶eip
    iretd 

VECTOR 0x00, ZERO
VECTOR 0x01, ZERO
VECTOR 0x02, ZERO
VECTOR 0x03, ZERO
VECTOR 0x04, ZERO
VECTOR 0x05, ZERO
VECTOR 0x06, ZERO
VECTOR 0x07, ZERO
VECTOR 0x08, ZERO
VECTOR 0x09, ZERO
VECTOR 0x0a, ZERO
VECTOR 0x0b, ZERO
VECTOR 0x0c, ZERO
VECTOR 0x0d, ZERO
VECTOR 0x0e, ZERO
VECTOR 0x0f, ZERO
VECTOR 0x10, ZERO
VECTOR 0x11, ZERO
VECTOR 0x12, ZERO
VECTOR 0x13, ZERO
VECTOR 0x14, ZERO
VECTOR 0x15, ZERO
VECTOR 0x16, ZERO
VECTOR 0x17, ZERO
VECTOR 0x18, ZERO
VECTOR 0x19, ZERO
VECTOR 0x1a, ZERO
VECTOR 0x1b, ZERO
VECTOR 0x1c, ZERO
VECTOR 0x1d, ZERO
VECTOR 0x1e, ERROR_CODE 
VECTOR 0x1f, ZERO

VECTOR 0x20, ZERO		;时钟中断对应的入口
VECTOR 0x21, ZERO		;键盘中断对应的入口
VECTOR 0x22, ZERO 		;级联用的		
VECTOR 0x23, ZERO 		;串口 2 对应的入口
VECTOR 0x24, ZERO 		;串口 1 对应的入口
VECTOR 0x25, ZERO 		;并口 2 对应的入口
VECTOR 0x26, ZERO 		;软盘对应的入口
VECTOR 0x27, ZERO 		;并口 1 对应的入口
VECTOR 0x28, ZERO 		;实时时钟对应的入口
VECTOR 0x29, ZERO  		;重定向
VECTOR 0x2a, ZERO 		;保留
VECTOR 0x2b, ZERO 		;保留
VECTOR 0x2c, ZERO 		;ps/2 鼠标
VECTOR 0x2d, ZERO 		;fpu 浮点单元异常
VECTOR 0x2e, ZERO 		;硬盘
VECTOR 0x2f, ZERO 		;保留

;;;;;;;;;;;;;;;;   0x80 号中断   ;;;;;;;;;;;;;;;; 
[bits 32]
extern syscall_table

section .text
global syscall_handler
syscall_handler:
; 保存上下文
	push 0			; 与其他中断格式统一
	push ds
	push es 
	push fs 
	push gs 
	pushad 
	push 0x80		; 与其他中断格式统一

; 为子功能传递参数
	push edx 
	push ecx 
	push ebx 

; 调用子功能
	call [syscall_table + eax * 4]
	add esp, 12		;丢掉三个参数，准备退出中断

; 返回值放到栈中的eax,然后退出中断
	mov [esp + 8 * 4], eax
	jmp intr_exit 

