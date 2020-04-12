#################
# Basic VERSION	
# This program takes an array v and computes
# min{|v[i]|}, the minimum of the absolute value,
# where v[i] is the i-th element in the array
	.data
	.align	2
v:
	.word	10
	.word	-47
	.word	22
	.word	-3
	.word	15
	.word	27
	.word	-4
m:
	.word	0

	.text
	.align	2
	.globl	__start
__start:
	li x16,7          # put 7 in x16 
	la x4,v           # put in x4 the address of v
	la x5,m           # put in x5 the address of m
	li x13,0x3fffffff # init x13 with max pos
loop:	
	beq x16,x0,done   # check all elements have been tested
	lw x8,0(x4)       # load new element in x8
	add x10,x10,x9    # x10 += x9 (add the carry in)
	addi x4,x4,0x4	  # point to next element
	addi x16,x16,-1   # decrease x16 by 1
	slt x11,x10,x13   # x11 = (x10 < x13) ? 1 : 0
	beq x11,x0,loop   # next element
	add x13,x10,x0    # update min
	jal loop          # next element
done:
	sw x13,0(x5)      # store the result	
endc:	
	jal endc  	  # infinite loop
	addi x0,x0,0
	
