INCLUDE C:\Irvine\Irvine32.inc		
INCLUDElib C:\Irvine\Irvine32.lib


.386 ;32 bit so just in case
.STACK 4096 ;reserves 4KB for stack 

ExitProcess PROTO,dwExitCode:DWORD 

.data
; MESSAGES
	intro_message BYTE "Welcome to our RPN Calculator",10,0
	prompt_message BYTE "Enter an integer or operation.",10,0
	quit_message BYTE "Quitting",10,0
	op_messages BYTE 10,"Valid Operations List: + - * / X N U D V C Q",10,0
	in_op_messages BYTE "Error: Invalid Operands for the operation", 10, 0
	stack_full BYTE "Error: Stack Full",10,0
	dashes BYTE ".............................",10,0
	top_marker BYTE "Top: ",0
	nl_maker BYTE 10,0
	empty_display BYTE "empty",10,10,0
;MESSAGES

	;TEMPS FOR ROLLING *insert barrel rolls*
	quad_tmp QWORD 0
	roll_tmp DWORD 7 DUP(0)

	sub_total DWORD 0

	stack_size EQU 8 ;our stacksize

	t_char = 9h ;for tabs

	elements TYPEDEF SDWORD					

	bufferSize EQU 60                   ;size of buffer
	buffer BYTE buffersize DUP(0)		;all zeroes boss

	my_stack SDWORD stack_size DUP(0)   ;our stack with a size of stack_size
	temp SDWORD ?	                    ;This temp is for rolling up and down
	instack SDWORD -1                   ;starting position
									
;this program uses ASCII hex representations for comparing
;a quick and easy to access table for the hexidecimal representations is
; https://www.ionos.com/digitalguide/server/know-how/ascii-codes-overview-of-all-characters-on-the-ascii-table/	
;this was used as a reference instead of flipping through the book for the table
.code
;our code
main PROC
	MOV edx, OFFSET intro_message	;move it in and display introduction message
	call WriteString				;print that message to screen


;grab input
get_input:
	;Messages for user
	MOV edx, OFFSET op_messages	 ;tells them what they can do 		
	call WriteString			;shows them it

	MOV edx, OFFSET prompt_message	;prompts user for input	
	call WriteString				
	
	;grabbing user input
	MOV edx, OFFSET buffer		;from command line to register
	MOV ecx, SIZEOF buffer		;our count
	call Readstring				;gets user input

		;location initialization
	MOV edx, (offset buffer) -1			

  next_char: 
	INC edx			;increment edx, the location of each char in buffer

   
	MOV AL, BYTE PTR [EDX]		;load character into AL register byte 

	CMP AL, 51h            ;two compares checking for the q or Q		
	JE quit_prog						
	CMP AL, 113							
	JE quit_prog						
   	;check for spaces
	cmp AL, 20h     
	je next_char						
   ;check for tabs
	cmp AL, 09h         
	je next_char
	;do we have a digit?
	call isDigit
	je parse	;		
;checks in order of + - * /
addition:
	cmp AL, 2Bh  ;do we have addition?
	jne subtraction                                  
	call do_addition   ;calling addition <- call to function		
	jmp get_input		 ;back up to inputs (all of these for +-*/  have this sort of structure and call
;same as addition just subtraction	
subtraction:	
	cmp AL, 2Dh		;do we have a dash?
	jne multiplication		;so we have a dash that means we gotta check it
	jmp dash_checker		;not subtraction LETS TRY MULTIPLYING
								
dash_checker:	               ;dash exists
			
	inc edx			        ;increments edx
	MOV AL, [edx]		        

	call isdigit	;do we have a number following the dash
	jne subtract_it		;subtraction time
	dec edx				
	jmp parse
	
subtract_it:

	call do_subtraction
	jmp get_input	

multiplication:

	cmp AL, 2Ah      ;checks if multiplication
	jne division		
	jmp multi_it
	
multi_it:

	call do_multiplication    ;calling multiplication
	jmp get_input

division:

	cmp AL, 2Fh		;check if division
	je divide_it				
	jmp exchange			
divide_it:

	call do_division  ;calling division
	jmp get_input

exchange:

	cmp AL, 58h			;check if exchange an E?
	je exchange_it
	cmp AL, 78h      ;an e
	je exchange_it
	jmp negation       ;negate jump
	
exchange_it:

	call exchange_them                      
	jmp get_input

negation:	
					
	cmp AL, 4Eh		;an N?	
	je negate_it
	cmp AL, 6Eh      ;an n?
	je negate_it
	jmp rolldown
	
negate_it:

	call negate_them                 
	jmp get_input

	
rollup:

	cmp AL, 55h		;a U
	je roll_it_up
	cmp AL, 75h		;a u
	je roll_it_up
	jmp rolldown
	
roll_it_up:

	call rollup_time                
	jmp get_input

rolldown:	
				
	cmp AL, 44h			;a D
	je roll_it_down
	cmp AL, 64h			;a d
	je roll_it_down
	jmp view
	
roll_it_down:

	call rolldown_time          
	jmp get_input

view:

	cmp AL, 56h		;a V
	je view_it
	cmp AL, 76h     ;a v 
	je view_it
	jmp clear
	
view_it:

	call view_data        
	jmp get_input
   
clear:		
	
	cmp AL, 43h		;a C?
	je clearing
	cmp AL, 63h      ; a c?
	je clearing
	jmp operation_error
	
clearing:  

        call clear_it_out                          
        jmp get_input

operation_error:
;if not a digit then we have junk
	call isdigit		
	je parse		
	jmp get_input		

parse:

	call ParseInteger32		;parsing the string
	call push_it			;place upon the stack milord
	
jmp get_input
 
quit_prog:

	MOV edx, OFFSET quit_message               ;Quit message display get OUTTA HERE 
	call WriteString			;displaying quit message to the screen

	INVOKE ExitProcess,0
main endP



push_it PROC 

	cmp instack, stack_size-1
	jge Stack_f
	INC instack                             ;increments stack index

	MOV ecx, instack                        ;store stack index in ecx
	ADD ecx, ecx                            ;getting that movement on     
	ADD ecx, ecx                                
	MOV my_stack[ecx], eax                      ;store in eaxvalue on stack
	jmp the_end                                 ;it is THE END OF THE LINE... FOR YOU MUHAHAHAHHAHAHAHAHAHAHAHAHAHHAHAAHAAAAAAAA *dramatic music*

Stack_f:

	MOV edx, offset stack_full
	call WriteString	

 ret
 
push_it ENDP

pop_it PROC USES ECX

	cmp instack, 0
	jl skip

	MOV ecx, instack						
	add ecx, ecx								
	add ecx, ecx
	MOV eax, my_stack[ecx]
	dec instack
	
skip:

	ret
	
pop_it ENDP

do_addition PROC

	cmp instack, 1		;needs to be enough there to add
	jl inval_op             ;jump less than enough operands

	call pop_it			;grabbing the first number
	MOV ebx, eax
	call pop_it			;grabbing the second number
	add eax, ebx
	call push_it			;calling push
	jmp the_end
	
inval_op:             
	MOV edx, offset in_op_messages	
	call WriteString
	
the_end:
	;show me the top stack
	call show_top
	ret
	
do_addition ENDP

;see addition and it pretty much follows the same thing but with subtraction
do_subtraction PROC

	cmp instack, 1		
	jl inval_op
	call pop_it
	MOV ebx, eax
	call pop_it
	sub ebx, eax
	MOV eax,ebx			
	call push_it
	jmp the_end
	
inval_op:

	MOV edx, offset in_op_messages
	call WriteString

	
the_end:

call show_top

	ret
	
do_subtraction ENDP

;see above again, code is pretty much the same,
;but with multiplication instead of addition or subtraction

do_multiplication PROC

	cmp instack, 1
	jl inval_op
	call pop_it
	MOV ebx, eax
	call pop_it
	imul eax, ebx
	call push_it
	jmp the_end
	
	inval_op:
	
	MOV edx, offset in_op_messages
	call WriteString
	
the_end:

call show_top
	ret
	
do_multiplication ENDP

;some things different in division but pretty much the same
do_division PROC

	cmp instack, 1	
	jl inval_op

	call pop_it			
	MOV ebx, eax		
	call pop_it			
	cmp ebx, 30h                      ;you can't divide by 0 
	je zero_handler	;jump zero
;	cdq          ;convert double to quad
	idiv ebx
	call push_it	
	jmp the_end
	;when you try to divide by zero,but i'm here to fail to stop you
	zero_handler:
		call push_it
		mov eax, ebx
		call push_it
	;invalid
	inval_op:

		MOV edx, offset in_op_messages
		call WriteString
	
	the_end:

		call show_top
		ret
do_division ENDP


exchange_them PROC USES ECX EBX

	cmp instack, 1			
	jl inval_op		;invalid op nothing to exchange
	call pop_it		;pop it off		
	MOV ecx, eax	;store it somewhere
	call pop_it		;pop the other one	
	MOV ebx, eax	;store that somewhere			
	MOV eax, ecx    ;move the first one back to eax
	call push_it    ;push it
	MOV eax, ebx	;grab the second elements			
	call push_it    ;real good 
	jmp the_end		;exchange completed
	
inval_op:
	;prints a message when you mess up
	MOV edx, offset in_op_messages
	call WriteString
	
the_end:
	;calls the show top
call show_top
	ret
	
exchange_them ENDP


negate_them PROC

	cmp instack, 0
	jl Stack_full ;invalid op call nothing to negate
	call pop_it ;pop it
	neg eax	      ;negate it 
	call push_it	  ;push it back on
	jmp the_end	 ;i'm outta here
	
inval_op:

	MOV edx, offset in_op_messages
	call WriteString
	
the_end:

	call show_top
	ret
	
negate_them ENDP

;rollup function
rollup_time PROC

	mov ebx, my_stack[SIZEOF elements * (stack_size -1)]
	mov temp, ebx
	mov ecx, (SIZEOF elements) * (stack_size - 2)

;loop for moving everything up
 loop_it:    
                            
	mov ebx, my_stack[ecx]		
	mov my_stack[ecx+(SIZEOF elements)], ebx	
	add ecx, -(SIZEOF elements)
	cmp ecx, 0                      
	jge loop_it

	mov ebx, temp	;moving temp back to ebx
	mov my_stack, ebx	;ebx val onto stack
	call show_top
	RET
	
rollup_time ENDP

;rollup but backwards
rolldown_time PROC

	mov ebx, my_stack
	mov temp, ebx
	mov ecx, 4
	
loop_it:

	mov ebx, my_stack[ecx]					
	mov my_stack[ecx - (SIZEOF elements)], ebx	
	add ecx, SIZEOF elements					
	cmp ecx, (SIZEOF elements) * (stack_size - 1)	
	jle loop_it

	mov ebx, temp
	mov my_stack[28], ebx
	call show_top
  RET
  
rolldown_time ENDP

clear_it_out PROC USES ECX

	MOV instack, -1	
	mov ecx, stack_size-1	

	repeat_it:

		mov my_stack[ecx], 0	
		dec ecx		
		cmp ecx, 0	
		jl repeat_it					
		call show_top				
		ret			
 			
clear_it_out ENDP


view_data proc

	call Crlf
	MOV edx, OFFSET dashes
	call WriteString
	MOV ebx, instack

l1:
	cmp ebx, 0   
	jl the_end	
	MOV eax, my_stack[ebx*4]
	call WriteInt		
	call Crlf		
	MOV edx, OFFSET dashes
	call WriteString	
	add ebx, -1
jmp l1

the_end:

	ret
	
view_data ENDP

show_top PROC

	cmp instack,0
	jge not_empty
	MOV EDX, OFFSET top_marker
	call WriteString
	mov edx, offset empty_display	
	call WriteString
	jmp skip
 
not_empty:

	MOV EDX, OFFSET nl_maker
	call WriteString
	MOV EDX, OFFSET top_marker
	call WriteString
	call pop_it
	call push_it
	call WriteInt	
	MOV EDX, OFFSET nl_maker
	call WriteString
 
skip:

	ret
show_top ENDP 

END main