.data
prompt:		.asciiz "Rows, Columns?"
array:		.space 10000
seed: 		.word 10178934
additive: 	.word 2342347
remainderVal: .word 29387641
directions:  .word 0
newline:	.asciiz "\n"

.text

main:

	## get rows and cols from user ##
	# cols $s1
	# rows $s2
	jal prompt_user

	# if cols % 2 = 0, add 1
	li 		$s0, 2
	div 	$s1, $s0
	mfhi 	$s0
	bne 	$s0, $zero, oddcols
	addi 	$s1, $s1, 1
oddcols:

	# if rows % 2 = 0, add 1
	li 		$s0, 2
	div 	$s2, $s0
	mfhi 	$s0
	bne 	$s0, $zero, oddrows
	addi 	$s2, $s2, 1

oddrows:
	# fill the array with *s	
	jal fill_array

	## print array ##
	#s5 = rows*cols
	#s1 = rows
	add 	$a0, $s5, $zero
	add 	$a1, $s1, $zero
	jal print
	## array printed ##

	## blank starting value (1,1) ##
	jal blank_1_1

	## print array ##
	#s5 = rows*cols
	#s1 = rows
	add 	$a0, $s5, $zero
	add 	$a1, $s1, $zero
	jal print
	## array printed ##

loopbegin:
	# index = 0
	add 	$s0, $zero, $zero

	## choose random direction ##
	jal random
	# $s4 = direction
	add 	$s4, $zero, $v0

move_in_direction:
	## calculate dx,dy ##
	# $s6 = dx
	# $s7 = dy
	jal calculate_movement


	## peek 1 space ahead ##
	# $t4 = array offset for adjacent square
	# $t3 = symbol at adjacent square
	jal peek_1

	# is it a space?
	# are we backtracking?


	## peek 2 spaces ahead ##
	# $t5 = array offset for 2 squares away
	# $t3 = symbol at adjacent square
	jal peek_2

	li 		$t2, '*'
	bne 	$t3, $t2, cantgo

go:

	# blank array[t4]
	la 		$s3, array
	add 	$s3, $s3, $t4
	li 		$t3, ' '
	sb 		$t3, 0($s3)

	# place symbol at array[t5]
	la 		$s3, array
	add 	$s3, $s3, $t5
	addi 	$t3, $s4, 33
	sb 		$t3, 0($s3)

	# set new X and Y #

	#calculate curx + 2dx
	# $t8
	add 	$t8, $t8, $t0

	#calculate cury + 2dy
	# $t9
	add 	$t9, $t9, $t1


	# if x = 1 and y = 1 - exit loop
	li 		$t3, 1
	bne 	$t8, $t3, keep_going
	# both = 1, exit program
	beq 	$t9, $t3, spim_error_fix

keep_going:
	## print array ##
	#s5 = rows*cols
	#s1 = rows
	add 	$a0, $s5, $zero
	add 	$a1, $s1, $zero
	jal print
	## array printed ##

	# jump back to loopbegin
	j loopbegin

cantgo:
	# cannot go in chosen direction

	# we have tried 1 direction, so increment index by 1
	#index++
	addi 	$s0, $s0, 1

	# if we have tried 4 directions, begin backtracking
	li 		$t3, 4
	beq		$s0, $t3, backtracking

	# else, try next direction
	# direction = (direction+1)%4
	addi 	$s4, $s4, 1
	div 	$s4, $t3
	mfhi	$s4

	j move_in_direction


backtracking: 

	add 	$s0, $zero, $zero

	# get symbol at x,y
	# y*cols + x

	# y* cols
	mult 	$t9, $s1
	mflo	$t3

	# + x
	add 	$t3, $t3, $t8

	#multiply by 4
	sll 	$t3, $t3, 2

	la 		$t2, array
	add 	$t2, $t3, $t2
	lb 		$t3, 0($t2)


	#replace it with ' '
	li 		$t4, ' '
	sb 		$t4, 0($t2)


	# $s4 = new direction

	# subtract 33
	addi 	$t3, $t3, -33
	
	# add 2
	addi 	$t3, $t3, 2

	# %4
	li 		$t2, 4
	div		$t3, $t2
	mfhi	$s4

	# move in dir $s4
	# get 2dx and 2dy

	jal calculate_movement

	jal peek_1

	jal peek_2

	# set new X and Y #

	#calculate curx + 2dx
	# $t8
	add 	$t8, $t8, $t0

	#calculate cury + 2dy
	# $t9
	add 	$t9, $t9, $t1


	# if x = 1 and y = 1 - exit loop
	li 		$t3, 1
	bne 	$t8, $t3, keep_going
	# both = 1, exit program
	beq 	$t9, $t3, finish_up

	j move_in_direction


###############################
## Get rows & cols from user ##
j dont_prompt
prompt_user:
	# Obtain following values from user
	# $s2 = rows
	# $s1 = columns


	la 		$a0, prompt
	li 		$v0, 4
	syscall

	# get first value (rows)
	li 		$v0, 5
	syscall
	add 	$s2, $v0, $zero

	# get second value (cols)
	li 		$v0, 5
	syscall
	add 	$s1, $v0, $zero 
 done_prompt:
	jr $ra
dont_prompt:

############################
#### Fill Array with *s ####
j dont_fill
fill_array:
	
	# $s5 = rows*colums
	mult	$s1, $s2
	mflo	$s5

	#initialize array
	#$s3 is arraybegin
	la  	$s3, array

 fill_header:
	#$t1 index = 0
	add 	$t1, $zero, $zero
	#$s4 is *
	li 	$s4, '*'
 fill:
	beq		$t1, $s5, array_full

	sb		$s4, 0($s3)

	# Go to next value of array
	addi 	$s3, $s3, 4
	
	# increment our counter 
	addi	$t1, $t1, 1

	j fill

 array_full:
    # Array is done filling with *'s
	#print array
	#s5 = rows*cols
	#s1 = columns
	add 	$a0, $s5, $zero
	add 	$a1, $s1, $zero
 filled:
 	jr $ra
dont_fill:

#############################
#### Print out array  #######
j dont_print
print:
	# Subroutine Prologue
	addiu	$sp, $sp, -32
	sw		$fp, 0($sp)
	sw		$ra, 4($sp)
	sw		$a0, 8($sp)
	sw 		$a1, 12($sp)
	add		$fp, $sp, 28
	
	# Save all S registers
	addiu	$sp, $sp, -32
	sw		$s7, 28($sp)
	sw		$s6, 24($sp)
	sw		$s5, 20($sp)
	sw		$s4, 16($sp)
	sw		$s3, 12($sp)
	sw		$s2, 8($sp)
	sw		$s1, 4($sp)
	sw		$s0, 0($sp)

	# s1 is columns
	# s5 is rows*cols
	add 	$s1, $zero, $a1
	add 	$s5, $zero, $a0

 print_header:
	#index $t0 = 0
	add 	$t1, $zero, $zero
	#$s3 is arraybegin
	la  	$s3, array

 print_array:
	#if index = rows*cols we're done printing
	beq		$t1, $s5, print_done

	lb 		$s4, 0($s3)

	#print value
	add 	$a0, $s4, $zero
	li 		$v0, 11
	syscall

	#go to next value in array
	addi	$s3, $s3, 4 
	#increment index
	addi	$t1, $t1, 1

	#if t1%cols = 0, print a new line
	div		$t1, $s1
	#$t4 = remainder
	mfhi	$t4
	beq		$t4, $zero, print_newline

	j print_array

 print_newline:
	# print a new line
	la 		$t0, newline
	lw		$t0, 0($t0)
	add 	$a0, $t0, $zero
	li 		$v0, 11
	syscall

	j print_array

 print_done:

	# print a new line
	la 		$t0, newline
	lw		$t0, 0($t0)
	add 	$a0, $t0, $zero
	li 		$v0, 11
	syscall

	# Restore all S registers
	lw	$s7, 28($sp)
	lw	$s6, 24($sp)
	lw	$s5, 20($sp)
	lw	$s4, 16($sp)
	lw	$s3, 12($sp)
	lw	$s2, 8($sp)
	lw	$s1, 4($sp)
	lw	$s0, 0($sp)
	addiu	$sp, $sp, 32
	

	# Subroutine Epilogue
	lw	$ra, 4($sp)
	lw	$fp, 0($sp)
	addiu	$sp, $sp, 32
	jr	$ra
dont_print:

#############################
#### Generate random 0-3 ####
j skip_random
random:
    # Subroutine Prologue
	addiu	$sp, $sp, -32
	sw	$fp, 0($sp)
	sw	$ra, 4($sp)
	sw	$a0, 8($sp)
	sw	$a1, 12($sp)
	sw	$a2, 16($sp)
	sw	$a3, 20($sp)
	add	$fp, $sp, 28
	
	# Save all S registers
	addiu	$sp, $sp, -32
	sw		$s7, 28($sp)
	sw		$s6, 24($sp)
	sw		$s5, 20($sp)
	sw		$s4, 16($sp)
	sw		$s3, 12($sp)
	sw		$s2, 8($sp)
	sw		$s1, 4($sp)
	sw		$s0, 0($sp)


	# s0 = seed
	la 		$s2, seed
	lw		$s0, 0($s2)
	# s1 = additive
	la 		$s1, additive
	lw 		$s1, 0($s1)

	# i = t0
	add 	$t0, $zero, $zero

	# s7 = 100 (for comparison)
	li		$s7, 100
	# s6 value for taking remainder
	la 		$s6, remainderVal
	lw 		$s6, 0($s6)

	#$s4 = result
 rloop:
	beq 	$t0, $s7, rdone

	# s5 = seed * additive
	mult	$s0, $s1
	mflo	$s5


	# seed = s5 % s6
	div 	$s5, $s6
	mfhi	$s0
 
 	sw 		$s0, 0($s2)
 
	# value of 3 bits needed
	andi	$s4, $s0, 0x3

	#i++
	addi 	$t0, $t0, 1
	j rloop
 rdone:
	add 	$v0, $zero, $s4


	# Restore all S registers
	lw	$s7, 28($sp)
	lw	$s6, 24($sp)
	lw	$s5, 20($sp)
	lw	$s4, 16($sp)
	lw	$s3, 12($sp)
	lw	$s2, 8($sp)
	lw	$s1, 4($sp)
	lw	$s0, 0($sp)
	addiu	$sp, $sp, 32
	

	# Subroutine Epilogue
	lw	$ra, 4($sp)
	lw	$fp, 0($sp)
	addiu	$sp, $sp, 32
	jr	$ra
skip_random:


#############################
## Blank value at (1,1) #####
j skip_blank
blank_1_1:
	#set (1,1) to blank
	#$t8 = current X
	add 	$t8, $zero, 1
	#$t9 = current Y
	add 	$t9, $zero, 1

	#$s3 is arraybegin
	la  	$s3, array

	## Starting point (1,1) ##
	#offset = (cols*y) + x

	#$t7 is offset
	add 	$t7, $zero, $zero

	#$t7   = 1 + ($s1 * 1)

	# $t7 = (Y*cols)
	mult	$t9, $s1
	mflo	$t7

	# $t7 += x
	add 	$t7, $t7, $t8

	#multiply offset by 4
	sll 	$t7, $t7, 2

	#add offset to beginning of array
	add 	$s3, $s3, $t7

	#save ' ' in register $t5
	li 	$t5, ' '

	sb		$t5, 0($s3)


 done_blank:
 	jr $ra
skip_blank:

#############################
#####  Calculate dx/dy  #####
##### Calculate 2dx/2dy #####
j skip_calculate_movement
calculate_movement:

	# $s4 = dir

 	#calculate dx
	# dx = $s6
	li 		$t2, 1
	and 	$s6, $s4, $t2
	addi 	$t1, $s4, -2
	mult 	$s6, $t1
	mflo 	$s6

	#calculate dy 
	# dy = $s7
	li 		$t2, -2
	nor 	$s7, $s4, $t2
	addi 	$t1, $s4, -1
	mult 	$s7, $t1
	mflo 	$s7

	# $s6 = 2dx
	sll 	$t0, $s6, 1

	# $s7 = 2dy
	sll 	$t1, $s7, 1
 done_calculate_movement:
 	jr $ra
skip_calculate_movement:


##############################
### What is 1 space ahead ####
j skip_peek_1
peek_1:
 calculate_offset_1:
 	#(curx + dx) + cols (cury+dy)
	#($t8 + $s6) + $s1  ($t9 + $s7)
	# answer is $t4

	#calculate curx + dx
	# $t3
	add 	$t3, $t8, $s6

	#calculate cury + dy
	# $t4
	add 	$t4, $t9, $s7


	# check bounds #

	#if new x = 0, cantgo
	beq 	$t3, $zero, cantgo
	#if new x = cols-1, cantgo
	addi 	$t2, $s1, -1
	beq 	$t3, $t2, cantgo

	#if new y = 0, cantgo
	beq 	$t4, $zero, cantgo
	#if new y = rows-1, cantgo
	addi 	$t2, $s2, -1
	beq 	$t4, $t2, cantgo


	# get offset
   
	#calculate cols * (cury+dy)
	mult 	$s1, $t4
	mflo 	$t4

	# add $t3 and $t4
	add 	$t4, $t3, $t4

	# $t4 is the array index
	# array offset = $t4 * 4
	sll 	$t4, $t4, 2

 get_symbol_at_1:
 	la 		$s3, array

 	add 	$s3, $s3, $t4

 	lb 		$t3, 0($s3)
 done_peek_1:
 	jr 		$ra
skip_peek_1:

###############################
### What is 2 spaces ahead ####
j skip_peek_2
peek_2:
 	#(curx + 2dx) + cols (cury+2dy)
	#($t8 + $t0) + $s1  ($t9 + $t1)
	# answer is $t5

	#calculate curx + 2dx
	# $t3
	add 	$t3, $t8, $t0

	#calculate cury + 2dy
	# $t5
	add 	$t5, $t9, $t1


	# check bounds #

	#if new x = 0, cantgo
	beq 	$t3, $zero, cantgo
	#if new x = cols-1, cantgo
	addi 	$t2, $s1, -1
	beq 	$t3, $t2, cantgo

	#if new y = 0, cantgo
	beq 	$t5, $zero, cantgo
	#if new y = rows-1, cantgo
	addi 	$t2, $s2, -1
	beq 	$t5, $t2, cantgo


	# get offset
   
	#calculate cols * (cury+2dy)
	mult 	$s1, $t5
	mflo 	$t5

	# add $t3 and $t5
	add 	$t5, $t3, $t5

	# $t5 is the array index
	# array offset = $t5 * 4
	sll 	$t5, $t5, 2

 get_symbol_at_2:
 	la 		$s3, array

 	add 	$s3, $s3, $t5

 	lb 		$t3, 0($s3)

 done_peek_2:
 	jr $ra
skip_peek_2:

j skip_finish_up
finish_up:



	# get value at (1,3)
	# 3 times rows + x
	mult 	$s2, $t9
	mflo	$t0

	add 	$t0, $t0, $t8

	#add offset
	add 	$s3, $s3, $t0

	li 		$t1, ' '
	sb 		$t1, 0($s3)

	# get value at (3,3)
	addi 	$s3, $s3, 12
	sb 		$t1, 0($s3)

	## print array ##
	#s5 = rows*cols
	#s1 = rows
	add 	$a0, $s5, $zero
	add 	$a1, $s1, $zero
	jal print
	## array printed ##


 make_entrance:
	la 		$s3, array
	sll 	$s0, $s1, 2
	add 	$s3, $s3, $s0
	li 		$t9, ' '
	sb 		$t9, 0($s3)


	## print array ##
	#s5 = rows*cols
	#s1 = rows
	add 	$a0, $s5, $zero
	add 	$a1, $s1, $zero
	jal print
	## array printed ##
 
 make_exit:
 	la  	$s3, array

 	# add (rows-2)*cols + cols-1
 	addi 	$s0, $s2, -2

 	mult 	$s0, $s1
 	mflo 	$s0

 	add 	$s0, $s0, $s1
 	addi 	$s0, $s0, -1

 	sll 	$s0, $s0, 2

 	add 	$s3, $s3, $s0

 	li 		$t9, ' '
	sb 		$t9, 0($s3)



	## print array ##
	#s5 = rows*cols
	#s1 = rows
	add 	$a0, $s5, $zero
	add 	$a1, $s1, $zero
	jal print
	## array printed ##

skip_finish_up:

spim_error_fix:
	#get rid of "attempt to execute non-instruction..."
	li $v0,10
	syscall
