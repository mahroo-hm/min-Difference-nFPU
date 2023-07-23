%ifndef SYS_EQUAL
%define SYS_EQUAL

    sys_read     equ     0
    sys_write    equ     1
    sys_open     equ     2
    sys_close    equ     3
   
    sys_lseek    equ     8
    sys_create   equ     85
    sys_unlink   equ     87
     

    sys_mkdir       equ 83
    sys_makenewdir  equ 0q777


    sys_mmap     equ     9
    sys_mumap    equ     11
    sys_brk      equ     12
   
     
    sys_exit     equ     60
   
    stdin        equ     0
    stdout       equ     1
    stderr       equ     3

 
PROT_NONE  equ   0x0
    PROT_READ     equ   0x1
    PROT_WRITE    equ   0x2
    MAP_PRIVATE   equ   0x2
    MAP_ANONYMOUS equ   0x20
   
    ;access mode
    O_DIRECTORY equ     0q0200000
    O_RDONLY    equ     0q000000
    O_WRONLY    equ     0q000001
    O_RDWR      equ     0q000002
    O_CREAT     equ     0q000100
    O_APPEND    equ     0q002000


    BEG_FILE_POS    equ     0
    CURR_POS        equ     1
    END_FILE_POS    equ     2
   
; create permission mode
    sys_IRUSR     equ     0q400      ; user read permission
    sys_IWUSR     equ     0q200      ; user write permission

    NL            equ   0xA
    Space         equ   0x20

%endif

%ifndef NOWZARI_IN_OUT
%define NOWZARI_IN_OUT

;----------------------------------------------------
newLine:
   push   rax
   mov    rax, NL
   call   putc
   pop    rax
   ret
;---------------------------------------------------------
putc:

   push   rcx
   push   rdx
   push   rsi
   push   rdi
   push   r11

   push   ax
   mov    rsi, rsp    ; points to our char
   mov    rdx, 1      ; how many characters to print
   mov    rax, sys_write
   mov    rdi, stdout
   syscall
   pop    ax

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx
   ret
;---------------------------------------------------------
writeNum:
   push   rax
   push   rbx
   push   rcx
   push   rdx

   sub    rdx, rdx
   mov    rbx, 10
   sub    rcx, rcx
   cmp    rax, 0
   jge    wAgain
   push   rax
   mov    al, '-'
   call   putc
   pop    rax
   neg    rax  

wAgain:
   cmp    rax, 9
   jle    cEnd
   div    rbx
   push   rdx
   inc    rcx
   sub    rdx, rdx
   jmp    wAgain

cEnd:
   add    al, 0x30
   call   putc
   dec    rcx
   jl     wEnd
   pop    rax
   jmp    cEnd
wEnd:
   pop    rdx
   pop    rcx
   pop    rbx
   pop    rax
   ret

;---------------------------------------------------------
getc:
   push   rcx
   push   rdx
   push   rsi
   push   rdi
   push   r11

 
   sub    rsp, 1
   mov    rsi, rsp
   mov    rdx, 1
   mov    rax, sys_read
   mov    rdi, stdin
   syscall
   mov    al, [rsi]
   add    rsp, 1

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx

   ret
;---------------------------------------------------------

readNum:
   push   rcx
   push   rbx
   push   rdx

   mov    bl,0
   mov    rdx, 0
rAgain:
   xor    rax, rax
   call   getc
   cmp    al, '-'
   jne    sAgain
   mov    bl,1  
   jmp    rAgain
sAgain:
   cmp    al, NL
   je     rEnd
   cmp    al, ' ' ;Space
   je     rEnd
   sub    rax, 0x30
   imul   rdx, 10
   add    rdx,  rax
   xor    rax, rax
   call   getc
   jmp    sAgain
rEnd:
   mov    rax, rdx
   cmp    bl, 0
   je     sEnd
   neg    rax
sEnd:  
   pop    rdx
   pop    rbx
   pop    rcx
   ret

;-------------------------------------------
printString:
   push    rax
   push    rcx
   push    rsi
   push    rdx
   push    rdi

   mov     rdi, rsi
   call    GetStrlen
   mov     rax, sys_write  
   mov     rdi, stdout
   syscall
   
   pop     rdi
   pop     rdx
   pop     rsi
   pop     rcx
   pop     rax
   ret
;-------------------------------------------
; rdi : zero terminated string start
GetStrlen:
   push    rbx
   push    rcx
   push    rax  

   xor     rcx, rcx
   not     rcx
   xor     rax, rax
   cld
         repne   scasb
   not     rcx
   lea     rdx, [rcx - 1]  ; length in rdx

   pop     rax
   pop     rcx
   pop     rbx
   ret
;-------------------------------------------

%endif

extern printf
extern scanf


section .data
    n dq 0
    it dq 0
    cur dq 0
    temp dq 0.0

    fmtout db "%lf %lf", NL, 0
    fmtouttemp db "%lf", NL, 0
    fmtinp db "%lf", 0

section .bss
    arr resq 100
    result resq 2
   
section .text
    global main

main:
    call readNum
    mov qword[n], rax

    while1:
        xor r12, r12
        mov r12, [it]
        mov r11, arr
        
        push rbp
        mov rdi, fmtinp
        shl r12, 3
        add r11, r12
        mov rsi, r11
        call scanf
        pop rbp

        add qword[it], 1
        mov rax, qword[it]
        cmp rax, qword[n]
        jne while1
    
    mov qword[it], 0
    fld qword[arr]
    fsub qword[arr + 8] ;min
    fabs
    mov qword[result], 0
    mov qword[result + 8], 1

    loopi:
        ;call newLine   

        mov rax, qword[n]
        cmp rax, qword[it]
        je endi

        xor r12, r12
        mov r12, qword[it]
        mov qword[cur], r12
        add qword[cur], 1
        shl r12, 3
        add r12, arr
        fld qword[r12] ;arr[i], min

        ; ;print a[i]
        ; mov al, 'i'
        ; call putc
        ; fst qword[temp]
        ; push rbp
        ; mov rdi, fmtouttemp
        ; movq xmm0, qword[temp]
        ; call printf
        ; pop rbp
    

        loopj:
            mov rax, qword[n]
            cmp rax, qword[cur]
            je endj

            xor r12, r12
            mov r12, qword[cur]
            shl r12, 3
            add r12, arr
            fld qword[r12] ;arr[j], arr[i], min

            ; ;print a[j]
            ; mov al, 'j'
            ; call putc
            ; fst qword[temp]
            ; push rbp
            ; mov rdi, fmtouttemp
            ; movq xmm0, qword[temp]
            ; call printf
            ; pop rbp

            fsub st1 ;arr[j]-arr[i], arr[i], min
            fabs ;|arr[j]-arr[i]|, arr[i], min

            ; ;print a[j] - a[i]
            ; mov al, Space
            ; call putc
            ; fst qword[temp]
            ; push rbp
            ; mov rdi, fmtouttemp
            ; movq xmm0, qword[temp]
            ; call printf
            ; pop rbp
            
            fcom st0, st2

            fstsw ax
            and ax, 0100011100000000b
            cmp ax, 0000000100000000b
            jne greater
            xor r12, r12
            mov r12, qword[it]
            mov qword[result], r12
            mov r12, qword[cur]
            mov qword[result + 8], r12
            fxch st2

            greater:
            add qword[cur], 1
            fstp st0 ;arr[i], min
            jmp loopj
        
        endj:
            add qword[it], 1
            fstp st0 ;min
            jmp loopi

    endi:
    mov qword[it], 0

    push rbp
    mov rdi, fmtout
    xor r12, r12
    mov r12, qword[result]
    movq xmm0, qword[arr + r12*8]
    mov r12, qword[result + 8]
    movq xmm1, qword[arr + r12*8]
    mov rax, 2
    call printf
    pop rbp

    ; while:
    ;     xor r12, r12
    ;     mov r12, [it]
    ;     mov r11, arr
        
    ;     push rbp
    ;     mov rdi, fmtout
    ;     shl r12, 3
    ;     add r11, r12
    ;     movq xmm0, qword[r11]
    ;     call printf
    ;     pop rbp

    ;     add qword[it], 1
    ;     mov rax, qword[it]
    ;     cmp rax, qword[n]
    ;     jne while

Exit:
    mov rax, sys_exit
    mov rdi, rdi
    syscall
