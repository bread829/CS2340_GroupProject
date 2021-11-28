	.data
delim:	.asciiz ", "
endl:      	.asciiz "\n"
userPrompt:    .asciiz "Think of a number between 1 and 63, answer 6 simple questions, and the Mind Reader will reveal your number! How is this possible??\n"
userAsk:    .asciiz "Is your number shown bellow?  Type Y for yes, and N for no.\n"
result:       .asciiz "THE NUMBER YOU WERE THINKING OF WAS: "
answer: .space 256

.text
main:

	 # will display user prompt 
	li $v0, 4                          
	la $a0, userPrompt 
	syscall
	la $a0, endl
	li $v0, 4
	syscall

	#generate seed (1-7)
	li $a1, 7 #upper bound
   	li $v0, 42  
  	syscall #generates the random number. and places it into $a0
	addi $t0, $a0, 1 # add lower bound
	#generate mask(3 or 5)
	li $a1, 2 #upper bound (exclusive)
   	li $v0, 42 
   	syscall #generates the random number. and places it into $a0
	li $t1, 5
	beq $a0, $zero, diffMask
	li $t1, 3
diffMask:	
	#call genCardSeqeuence
	move $a0, $t0
	move $a1, $t1
	jal genCardSeqeuence
	#get results
	move $t9, $v0
	
	afterCards:	
	la $a0, endl
	li $v0, 4
	syscall	
	
        li $v0, 4                          
	la $a0, result
	syscall
	
	move $a0, $t9
	li $v0, 1 
	syscall
	
#
	
	
	# Exit Program
	li $v0, 10
	syscall


#Name:	 calculateNextLFSRterm
#Author: Jordan Zon
#Args: 	a0 - current value/State(between 1-7), a1 - mask (3 or 5)
#Return:	v0 - next state
#Notes:	This function is used in generating the next state in the genCardSequence Function
#	 How Linear FeedBack Shift Registers Work  (Pseudo-Random number sequence generation)
#		a seed is given  001, and a mask 101 (Both of these inital values can be randomly generated)
#		mask 101 says that the first and third bits have been selected for XOR, and wheather or not a 0 or 1 is added to the front is based on those two bits
#		So given the seeds
#				001  011  100  110  = yes add a 1   while    010  101  111 = no, don't add 1
#		for 001,  1 is added at the front (+8), ->  1001
#		right shift is applied  regardless -> 100
#   	   	 pattern  -->   seed 001, 100, 110, 111, 011, 101, 010, 001   (1,4,6,7,3,5,2,1) and then it repeats
calculateNextLFSRterm:
	move $t0, $a0 # $t0 will be shifted and hold the answer
	and $t1, $a0, $a1 # $t1 after applying an and, the only invalid ones =000 or the mask
	# if $t1 = zero || $t1 = mask,  skipAddStep
	beq $t1, $zero, skipAddStepLFSR
	beq $t1, $a1, skipAddStepLFSR 
	addi $t0, $t0, 8 #This function works only for 3 bit LFSR
skipAddStepLFSR:	
	srl $v0, $t0, 1 #return next value
	jr $ra

#Name: genCardSeqeuence
#Author: Jordan Zon + EDIT: Mikasa
#Args: 	a0 - current value/State(between 1-7), a1 - mask (3 or 5)
#Return: v0 - sumUserInput
#Notes:	This function generates the card sequence, prints out the card, gets user input, and returns the sum of the user input
#	The loop will run 7 times, since the choosen maxiumal length LFSR 
genCardSeqeuence: 
	#initalize variables (All will be stored on the Stack)
	add 	$t1, $zero, $zero	 # the increment i =0
	move  $t2, $a0 		# the current state 
	move  $t3, $a1 		# the mask 
	add $t4,  $zero, $zero # user input sum = 0
gCSLoopStart: 
	add $t0, $zero, 7 # the max i (t0 is used for int comparision)
	beq $t1, $t0, gCSExit # break when i = 7
	#Place variables on stack (Will call Two Functions)
	addiu $sp, $sp, -20 	#set up space for the stack (5 words)
	sw $ra, 16($sp)		#save $ra in uppmost stack
	sw $t1, 12($sp)		#save $t1  - i
	sw $t2, 8($sp)		#save $t2  - state
	sw $t3, 4($sp)		#save $t3  - mask
	sw $t4, ($sp)			#save $t4 -  userInputSum
	
	#-------Select Card ----------
	#Function to generate next number in sequence
	move $a0, $t2 #state
	move $a1, $t3 #mask
	jal calculateNextLFSRterm
	#process results
	sw $v0, 8($sp)		#Next State stored **
	move $t2, $v0
	add $t0, $zero, 7 
	beq $t2, $t0, gCSLoopIncrement  #iWhen generated number = 7 skip.
	
	#-------Print Card----------
	# ask the user if the card is shown 
        li $v0, 4                          
	la $a0, userAsk
	syscall
	la $a0, endl
	li $v0, 4
	syscall
	# Get  Card number from StateNumber $t2, and set t0 = cardNumber
	addi $t0, $zero, 1 #set v0 =1
	addi $t2, $t2, -1 #state subtract 1
	sllv $t0, $t0, $t2 #shift t0 
	#Print Card, given card Number
	move $a0, $t0
	jal prCard  
	la $a0, endl
	li $v0, 4
	syscall
	
	#-------Get User Input----------
	la  $a0, answer
   	li  $a1, 3
        li  $v0, 8
        syscall
        lb  $t4, 0($a0)
        bne $t4, 'Y', gCSLoopIncrement
	# Get  Card number from StateNumber, and set t0 = cardNumber
	lw $t2, 8($sp)			#load $t2  - state, the registers may have be rewritten but cardNumber can be recalculated.
	addi $t0, $zero, 1	 	#set t0 =1
	addi $t2, $t2, -1		#subtract from genNumber 1
	sllv $t0, $t0, $t2 		#shift t0 
	#add card number to user sum
	lw $t4, ($sp)			#load $t4 - userInputSum
	add $t4, $t4, $t0
	sw $t4, ($sp)			#save $t4 -  userInputSum  ****
gCSLoopIncrement:
	#Stack  unloading
	lw  $ra, 16($sp)		#return ra
	lw $t1, 12($sp)		#load $t1  - i
	lw $t2, 8($sp)			#load $t2  - state
	lw $t3, 4($sp)			#load $t3  - mask
	lw $t4, ($sp)			#load $t4 - userInputSum
	addiu $sp, $sp, 20 	#Clear up space
	addi $t1, $t1, 1 #  i++
	j gCSLoopStart
gCSExit:
	move $v0, $t4
	jr  $ra

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

# ALGORITHM PSEUDOCODE
# While i < n:
#  i++
#  if i >= MAX: break
#  if i does not contain binary position n (ex. 8 = 001000): continue
#  print i
#  if c is divisible by 8, print a new line
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
