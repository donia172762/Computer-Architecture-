.data
filename:       .asciiz "C:\\Users\\e-life center\\Desktop\\donia\\third year\\arch\\Arch_project\\input.txt"
valid_str:      .asciiz "valid\n"
invalid_str:    .asciiz "invalid\n"
newline:        .asciiz "\n"

buffer:         .space 1024

.align 2
lines_float:    .space 160         # All parsed values (max 40 floats)

.align 2
valid_floats:   .space 160         # Only valid values (max 40 floats)

zero_float:     .float 0.0
one_float:      .float 1.0

.text
.globl main
main:
    li $v0, 13
    la $a0, filename
    li $a1, 0
    li $a2, 0
    syscall
    move $s0, $v0

    li $v0, 14
    move $a0, $s0
    la $a1, buffer
    li $a2, 1024
    syscall

    li $v0, 16
    move $a0, $s0
    syscall

    la $t0, buffer
    la $t1, lines_float
    la $s1, valid_floats

    l.s $f7, zero_float
    l.s $f8, one_float

parse_loop:
    li $t2, 0
    li $t3, 0
    li $t4, 0
    li $t5, 0

    mtc1 $zero, $f10
    mtc1 $zero, $f12
    mtc1 $zero, $f14

read_digits:
    lb $t6, 0($t0)
    beqz $t6, process_float

    li $t7, 10
    beq $t6, $t7, process_float

    li $t7, 46
    beq $t6, $t7, found_dot

    li $t7, 48
    sub $s2, $t6, $t7

    beqz $t5, build_int

    mul $t3, $t3, 10
    add $t3, $t3, $t7
    addi $t4, $t4, 1
    j next_char

build_int:
    mul $t2, $t2, 10
    add $t2, $t2, $s2
    j next_char

found_dot:
    li $t5, 1
    j next_char

next_char:
    addi $t0, $t0, 1
    j read_digits

process_float:
    mtc1 $t2, $f10
    cvt.s.w $f10, $f10

    beqz $t4, skip_frac

    mtc1 $t3, $f12
    cvt.s.w $f12, $f12

    li $t7, 1
    move $t8, $t4
    li $t9, 10

divisor_loop:
    beqz $t8, div_done
    mul $t7, $t7, $t9
    subi $t8, $t8, 1
    j divisor_loop

div_done:
    mtc1 $t7, $f14
    cvt.s.w $f14, $f14
    div.s $f12, $f12, $f14
    add.s $f10, $f10, $f12

skip_frac:
    s.s $f10, 0($t1)
    addi $t1, $t1, 4

    # ? ???? ?? ????? > 0.0 AND < 1.0
    c.le.s $f10, $f7       # f10 <= 0.0
    bc1t print_invalid

    c.lt.s $f10, $f8       # f10 < 1.0
    bc1f print_invalid     # ??? ?? ???? ? invalid

    s.s $f10, 0($s1)
    addi $s1, $s1, 4

    li $v0, 4
    la $a0, valid_str
    syscall
    j check_done

print_invalid:
    li $v0, 4
    la $a0, invalid_str
    syscall

check_done:
    lb $t6, 0($t0)
    beqz $t6, exit
    addi $t0, $t0, 1
    j parse_loop

exit:
    li $v0, 10
    syscall