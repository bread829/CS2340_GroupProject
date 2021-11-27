	.data
delim:	.asciiz ", "
endl:	.asciiz "\n"
	.text

	# Printing cards for each of the 6 possible values (1, 2, 4, 8, 16, 32) 
	li $a0, 1
	jal prCard
	la $a0, endl
	li $v0, 4
	syscall
	
	li $a0, 2
	jal prCard
	la $a0, endl
	li $v0, 4
	syscall
	
	li $a0, 4
	jal prCard
	la $a0, endl
	li $v0, 4
	syscall
	
	li $a0, 8
	jal prCard
	la $a0, endl
	li $v0, 4
	syscall
	
	li $a0, 16
	jal prCard
	la $a0, endl
	li $v0, 4
	syscall
	
	li $a0, 32
	jal prCard

	# Exit Program
	li $v0, 10
	syscall

# Name: printCard
# Author: David Allen
# Date: 11/27/21
# Args: $a0 = number in top left of card. ASSUMES $a0 is power of 2 < 64
# Return: N/A
# Notes: Right now we set the MAX as an immediate, 64
# 	 Otherwise we could make MAX another argument, but that adds extra lines of code throughout the program
prCard: # initialize vars
	move $s0, $a0 # number at top-left of card (n)
	li $s1, 64 # $s1 = MAX = 64
	move $t1, $a0 # incremented value (i)
	move $t5, $zero # increment counter (c)
	addi $t1, $t1, -1 # initialize i at n - 1
	#li $s2, 7 # value before newline
# ALGORITHM PSEUDOCODE
# While i < n:
#  i++
#  if i >= MAX: break
#  if i does not contain binary position n (ex. 8 = 001000): continue
#  print i
#  if i % 8 == 7, print a new line
#  else, print delimiter ", "
prLoop: addi $t1, $t1, 1
	slt $t3, $t1, $s1
	beq $t3, $zero, prExit
	and $t2, $t1, $s0
	bne $t2, $s0, prLoop
	# print i
	move $a0, $t1
	li $v0, 1
	syscall
	addi $t5, $t5, 1 # increment c
	# all numbers div. by 8 do not contain bits 000111.
	andi $t4, $t5, 7 # nums div. by 8 should = 0 after andi w/ 7
	beq $t4, $zero, prEndl
	la $a0, delim
	li $v0, 4
	syscall
	j prLoop
prEndl:	la $a0, endl
	li $v0, 4
	syscall
	j prLoop
prExit: jr $ra