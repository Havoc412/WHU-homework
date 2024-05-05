# 处理后 2.0，通过 sw_i 来设定 n

    lui x31, 0x00000
    addi x1, x0, 1020

main:
    andi x6, x6, 0x01F
    jal x5, fib
    sw x7, 0x00C(x31)
    jal x0, end

fib:
    addi x7, x0, 1
    bge x7, x6, ret
    addi x1, x1, -8
    sw x5, 4(x1)
    addi x6, x6, -1
    jal x5, fib
    sw x7, 0(x1)
    addi x6, x6, -1
    jal x5, fib
    lw x8, 0(x1)
    add x7, x7, x8
    addi x6, x6, 2
    lw x5, 4(x1)
    addi x1, x1, 8
ret:
    jalr x0, x5, 0

end:
    lw x9 0x00C(x31)
