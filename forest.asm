PORT_UART_OUT equ 2
PORT_DISPLAY equ 2

;org 0h
start:
	call forest_copy
loop:
	call forest_draw
	;call DELAY
	call forest_copy
	;jmp loop
	;mvi A, 3
	;mvi B, 3
	;mvi C, 'X'
	;call forest_set
	call forest_evaluate
	call forest_restore
	;call forest_draw
	;jmp $

	call DELAY
	call DELAY
	mvi A, 26
	call PRINTC
	;mvi A, 1
	;mvi B, 1
	;call forest_get
;loop:
	jmp loop

forest_data:
	db 'PDDPDDDD'
	db 'DDDDDDDD'
	db 'DDDDDDDD'
	db 'DDDDDDDD'

forest_data_copy:
	db '00000000'
	db '00000000'
	db '00000000'
	db '00000000'

DELAY:
	push H
	mvi H, 0
DELAY_loop_H:
	mvi L, 255
DELAY_loop_L:
	dcr L
	mov A, L
	jnz DELAY_loop_L
	dcr H
	mov A, H
	jnz DELAY_loop_H
	pop H
	ret

forest_eval_P_OLD:
	push D
	push H
	mov H, A
	mov L, B
	mov A, E
	mov B, D
	mvi C, 'S'
	call forest_set
	mov B, L
	mov A, H
	pop H
	pop D
	ret

forest_eval_P:
	mvi C, 'S'
	jmp forest_evaluate_setstate
;	ret

forest_eval_D:
	mvi C, 'X'
	jmp forest_evaluate_setstate
;	ret

forest_eval_S:
	mvi C, 'S'
	jmp forest_evaluate_setstate
;	ret

; Evaluate the board
; E - X
; D - Y
forest_evaluate:
	lxi H, forest_data
	mvi D, 0
forest_evaluate_loop_y:
	mov A, D
	cpi 4
	jz forest_evaluate_end_y
	mvi E, 0
forest_evaluate_loop_x:
	mov A, E
	cpi 8
	jz forest_evaluate_end_x
	; logic
	mov A, E
	mov B, D
	call forest_get
	cpi 'P'
	jz forest_eval_P
	cpi 'D'
	jz forest_eval_D
	cpi 'S'
	jz forest_eval_S
forest_evaluate_setstate:
	call forest_set
	; END logic
	inr E
	jmp forest_evaluate_loop_x
forest_evaluate_end_x:
	inr D
	jmp forest_evaluate_loop_y
forest_evaluate_end_y:
	ret

OLD_forest_evaluate:
	lxi H, forest_data
	mvi D, 0
OLD_forest_evaluate_loop_y:
	mvi E, 0
OLD_forest_evaluate_loop_x:
	mov A, E
	mov B, D
	call forest_get
	cpi 'P'
	jz forest_eval_P
	cpi 'D'
	jz forest_eval_D
	cpi 'S'
	jz forest_eval_S
OLD_forest_evaluate_setstate:
	; set new state
	call forest_set
	; loop check
	inr E
	inx H
	mov A, E
	cpi 8
	jnz OLD_forest_evaluate_loop_x
	inr D
	mov A, D
	cpi 4
	jnz OLD_forest_evaluate_loop_y
	ret

rand:
	mvi A, 1
	ret

forest_copy:
	; BC to DE A bytes
	mvi A, 32
	lxi D, forest_data_copy
	lxi B, forest_data
	call MEMCPY
	ret

forest_restore:
	mvi A, 32
	lxi D, forest_data
	lxi B, forest_data_copy
	call MEMCPY
	ret

; FOREST SUB get
; gets state at x=A, y=B
; Char in A
forest_get:
	push D
	lxi H, forest_data_copy
	mvi D, 0
	mvi E, 8
forest_get_loop:
	jz forest_get_end
	dad D
	dcr A
	jmp forest_get_loop
forest_get_end:
	mov E, B
	dad D
	xchg
	ldax D
	pop D
	ret

; FOREST SUB set
; sets at x=A y=B value=C
forest_set:
	push D
	lxi H, forest_data_copy
	mvi D, 0
	mvi E, 8
forest_set_loop:
	jz forest_set_end
	dad D
	dcr A
	jmp forest_set_loop
forest_set_end:
	mov E, B
	dad D
	xchg
	mov A, C
	stax D
	pop D
	ret
	
; FOREST SUB draw
forest_draw:
	;lhld forest_data
	mvi E, forest_data_copy
	;xchg
	mvi C, 0
forest_draw_loop_x:
	mvi B, 0
forest_draw_loop_y:
	;call DELAY
	ldax D
	call printc
	inx D
	inr B
	mov A, B
	cpi 8
	jnz forest_draw_loop_y
	mvi A, 13
	call printc
	mvi A, 10
	call printc

	inr C
	mov A, C
	cpi 4
	jnz forest_draw_loop_x
	ret

; SUB ------------------------------------
; prints null terminated string from H:L
prints:
	ldax D
	cpi 0
	jz exsub_prints_end
	call printc
	inx D
	jmp prints
exsub_prints_end:
	ret

exsub_println:
	call PRINTS
	mvi A, 0Dh
	call PRINTC
	mvi A, 0Ah
	jmp PRINTC
; END ------------------------------------

; SUB ------------------------------------
; prints char from ACC
printc:
	out PORT_DISPLAY
	ret
; END ------------------------------------

; SUB ------------------------------------
; Copy data
; BC to DE. A bytes
MEMCPY:
exsub_memcpy:
	cpi 0
	rz
	push D
	push B
	push H
	mov H, A
exsub_memcpy_loop:
	ldax B
	stax D
	inx B
	inx D
	dcr H
	mov A, H
	jnz exsub_memcpy_loop
	pop H
	pop B
	pop D
	ret
; END ------------------------------------
