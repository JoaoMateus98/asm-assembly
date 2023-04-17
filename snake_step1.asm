; connect DATA_IN to pin 8, CS to pin 9, CLK to pin 10
; connect button to pin 2, optionally connect second button to pin 3

.include "m328pdef.inc"

.org 0x0
	rjmp start
.org 0x2
	rjmp button1
.org 0x4
	rjmp button2

start:

; THIS IS SETUP CODE.  DON'T CHANGE IT

	; set up stack
	ldi r16,LOW(RAMEND)
	out SPL,r16
	ldi r16,HIGH(RAMEND)
	out SPH,r16

	; set up the display
	call ledinit

	; a 0->5v on pin 2 will now cause button1 to run
	call setup_button_interrupt

	; set index register Y to 0x100 memory
	ldi r28,LOW(0x100)
	ldi r29,HIGH(0x100)



	; recommended variables:
	;  Y+0 (100): snake head dx
	;  Y+1 (101): snake head dy
	;  Y+2 (102): apple x
	;  Y+3 (103): apple y
	;  Y+4 (104): button press count for random?
	;  Y+5 (105): delay
	;  Y+6 (106): snake size
	;  Y+10 (110): snake head x
	;  Y+11 (111): snake head y
	;  Y+12, Y+13, Y+14, Y+15 ...  snake body x and y

; YOUR SETUP CODE GOES HERE
	; initialize snake x and y
	ldi r17,2
	std Y+10,r17
	std Y+11,r17

	; initialized snake body
	ldi r17, 1
	std Y+12, r17
	ldi r17, 2
	std Y+13, r17
	ldi r17, 0
	std Y+14, r17
	ldi r17, 2
	std Y+15, r17

	; initialize dx and dy
	ldi r17,1
	std Y+0,r17
	ldi r17,0
	std Y+1, r17

	; initialize apple coordinates at (1,5)
	;  Y+2 (102): apple x
	;  Y+3 (103): apple y
	ldi r17, 1
	std Y+2, r17
	ldi r17, 5
	std Y+3, r17

	
	ldd r20, Y+2
	ldd r21, Y+3
	ldi r16,1
	call setpixel
	ldd r20, Y+12
	ldd r21, Y+13
	ldi r16, 1
	call setpixel
	ldd r20, Y+14
	ldd r21, Y+15
	ldi r16, 1
	call setpixel


mainloop:
	; YOUR REPEATED CODE GOES HERE
	ldd r20,Y+10
	ldd r21,Y+11
	ldi r16,0
	call setpixel
	
	; set x=x+dx
	ldd r17,Y+10
	ldd r18,Y+0
	add r17,r18
	std Y+10,r17

	; set y=y+dy
	ldd r17,Y+11
	ldd r18,Y+1
	add r17,r18
	std Y+11,r17

	; check for the gameover conditions
	ldd r17,Y+10 ; x value
	ldd r18,Y+11 ; y value

	cpi r17,8
	breq gameover

	cpi r17,-1
	breq gameover

	cpi r18,8
	breq gameover

	cpi r18,-1
	breq gameover

	; draw snake
	ldd r20,Y+10
	ldd r21,Y+11
	ldi r16,1
	call setpixel
	
	call handleApple

	call delay

	jmp mainloop

handleApple:
	push r17
	push r18
	push r19
	push r20

	ldd r17, Y+10 ; snake x
	ldd r18, Y+11 ; snake y
	ldd r19, Y+2 ; apple x
	ldd r20, Y+3 ; apple y

	cp r17, r19
	brne end0
	cp r18, r20
	brne end0

	; if true do this
	; Move the apple
	ldd r17, Y+2
	ldi r18, 23
	add r17, r18
	andi r17, 7
	std Y+2, r17

	ldd r17, Y+3
	ldi r18, 23
	add r17, r18
	andi r17, 7
	std Y+3, r17

	ldd r20, Y+2
	ldd r21, Y+3
	ldi r16,1
	call setpixel


	end0:


	pop r20
	pop r19
	pop r18
	pop r17	

	ret

delay:
	ldi r22, 50
		outloop:
			ldi r21, 255
			middleloop:
				ldi r20, 255
					innerloop: 
						dec r20
						brne innerloop

						dec r21
						brne middleloop

						dec r22
						brne outloop
	ret

gameover:
	jmp gameover

button1:
	cli
	push r17
	push r18
	push r19
	push r20


	; YOUR BUTTON 1 RESPONSE CODE HERE
	ldd r19, Y+0 ; dx
	ldd r20, Y+1 ; dy
	
	cpi r19, 1
	brne b0
	; move down
	ldi r17, 0
	std Y+0, r17
	ldi r17, -1
	std Y+1, r17
	jmp end

	b0:
	cpi r19, -1
	brne b1
	; move up
	ldi r17, 0
	std Y+0, r17
	ldi r17, 1
	std Y+1, r17
	jmp end

	b1:
	cpi r20, -1
	brne b2
	; move left
	ldi r17, -1
	std Y+0, r17
	ldi r17, 0
	std Y+1, r17
	jmp end

	b2:
	; move right
	ldi r17, 1
	std Y+0, r17
	ldi r17, 0
	std Y+1, r17
	jmp end

	end:
	
	pop r20
	pop r19
	pop r18
	pop r17
	sei
	reti

button2:
	cli

	; BUTTON 2 RESPONSE CODE (OPTIONAL)

	sei
	reti

;YOU SHOULD NOT NEED TO MODIFY ANY CODE AFTER THIS POINT

; takes x,y coordinate and sets pixel value
; x in r20, y in r21, pixel on/off (0 or 1) in r16
setpixel:
	push r28
	push r29
	call setdisplayaddress
	st Y,r16
	pop r29
	pop r28
	call ledupdate
	ret

; takes x,y coordinate and returns pixel value
; x in r20, y in r21, returns r16
getpixel:
	push r28
	push r29
	call setdisplayaddress
	ld r16,Y
	pop r29
	pop r28
	ret

	; set up button interrupt
setup_button_interrupt:
	cli
	sbi EIMSK,0
	sbi EIMSK,1
	lds r16,EICRA
	ori r16,0xf
	sts EICRA,r16
	cbi DDRD,2
	cbi DDRD,3
	sei
	ret

	; clear the display
clrscreen:
	push r16
	push r20
	push r21
	ldi r16,0
	ldi r20,7
cls_loop1:
	ldi r21,7
cls_loop2:
	call setpixel
	dec r21
	brge cls_loop2
	dec r20
	brge cls_loop1

	pop r21
	pop r20
	pop r16
	ret

; call at beginning of program to initialize the display
ledinit:
	sbi DDRB,0
	sbi DDRB,1
	sbi DDRB,2
	push r20
	push r22
	ldi r20,0xb	;regscanlimit=7
	ldi r22,7
	call ledwrite
	ldi r20,0x9	;regdecode=0
	ldi r22,0
	call ledwrite
	ldi r20,0xc	;regshutdown=1
	ldi r22,1
	call ledwrite
	ldi r20,0xf	;regdisplaytest=0
	ldi r22,0
	call ledwrite
	ldi r20,0xa	;regintensity=4
	ldi r22,4
	call ledwrite
	; clear all 8 lines
	ldi r22,0
	ldi r20,1
ledinit_clrloop:
	call ledwrite
	inc r20
	cpi r20,9
	brne ledinit_clrloop
	pop r22
	pop r20
	call clrscreen
	ret

; call to read memory from 0x200-0x240 and output to display
ledupdate:
	push r20
	push r21
	push r22

	; r20 is x, r21 is y, r22 is row
	;for x=0 to 8
	ldi r20,0
ledupdate_xloop:
	;row=0
	ldi r22,0
	;for y=0 to 8
	ldi r21,7
ledupdate_yloop:
	; get pixel and shift it into row
	add r22,r22
	push r16
	call getpixel
	add r22,r16
	pop r16

	dec r21
	brge ledupdate_yloop

	inc r20

	; ledwrite(x+1,row)
	call ledwrite

	cpi r20,8
	brne ledupdate_xloop

	pop r22
	pop r21
	pop r20
	ret

; reg in r20, data in r22
ledwrite:
	cbi PORTB,1
	sbi PORTB,1

	push r21
	mov r21,r20
	call ledwrite_sendbyte
	mov r21,r22
	call ledwrite_sendbyte
	pop r21

	cbi PORTB,1
	sbi PORTB,1
	ret

; sends the byte in r21 out to display serially, starting with MSB
ledwrite_sendbyte:
	push r20
	push r22
	ldi r22,0b10000000
ledwrite_sendbyte_loop:
	cbi PORTB,2
	mov r20,r21
	and r20,r22
	cpi r20,0
	breq ledwrite_sendbyte_send0
	sbi PORTB,0
	jmp ledwrite_sendbyte_sent
ledwrite_sendbyte_send0:
	cbi PORTB,0
ledwrite_sendbyte_sent:
	sbi PORTB,2
	lsr r22
	brne ledwrite_sendbyte_loop
	pop r22
	pop r20
	ret

; takes display coordinate x,y in r20,r21, sets Y to address
setdisplayaddress:
	ldi r28,LOW(0x200)
	ldi r29,HIGH(0x200)
	push r22
	push r20
	add r20,r20
	add r20,r20
	add r20,r20
	add r20,r21
	add r28,r20
	pop r20
	pop r22
	ret