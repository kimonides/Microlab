
; Replace with your application code
; ---- ���� �������� ���������
.nolist
.include "m16def.inc"
.list
.DSEG
 _tmp_: .byte 2
; ---- ����� �������� ���������
.CSEG
.include "m16def.inc"

.org  0x0
rjmp  reset



reset:
  ldi r24,low(RAMEND)    ;Initialize stack pointer
  out SPL,r24
  ldi r24,high(RAMEND)  
  out SPH,r24
  ser r24
  out DDRB,r24          ;Initialize port_b for output
  clr r24
  ldi r24, (1 << PC7) | (1 << PC6) | (1 << PC5) | (1 << PC4) 
  out DDRC,r24           ;Set the 4 msb as output

main:
  ldi   r24,0x0A
  rcall scan_keypad_rising_edge
  rcall keypad_to_ascii
  cpi   r24,0x00
  breq  main
  mov   r16,r24
pressed_first:
  ldi   r24,0x0A
  rcall scan_keypad_rising_edge
  rcall keypad_to_ascii
  cpi   r24,0x00
  breq  pressed_first
  mov   r17,r24
check_first:
  cpi   r16,0x30 
  breq  first_was_ok
not_okay:
  rcall wrong_pass
  jmp   end
first_was_ok: 
  cpi   r17,0x39
  breq  second_was_ok
  jmp   not_okay
second_was_ok:
  rcall correct_pass
  
end:  
  jmp main


wrong_pass:
  ldi r19,8
rep: 
  ser   r18
  out   PORTB,r18
  ldi   r24,low(250)
  ldi   r25,high(250)
  rcall wait_msec
  clr   r18
  out   PORTB,r18
  ldi   r24,low(250)
  ldi   r25,high(250)
  rcall wait_msec
  dec   r19
  brne  rep

  clr r24
  clr r25
  clr r18
  out PORTB,r18
  ret

correct_pass:
  ser r18
  out PORTB,r18
  ldi r24,low(4000)
  ldi r25,high(4000)
  rcall wait_msec
  clr r24
  clr r25
  clr r18
  out PORTB,r18
  ret




scan_keypad_rising_edge:
  mov r22 ,r24      ; ���������� �� ����� ������������ ���� r22
  rcall scan_keypad ; ������ �� ������������ ��� ���������� ���������
  push r24          ; ��� ���������� �� ����������
  push r25
  mov r24 ,r22      ; ����������� r22 ms (������� ����� 10-20 msec ��� ����������� ��� ���
  ldi r25 ,0        ; ������������ ��� ������������� � ������������� ������������)
  rcall wait_msec
  rcall scan_keypad ; ������ �� ������������ ���� ��� ��������
  pop r23           ; ��� ������� ���������� �����������
  pop r22
  and r24 ,r22
  and r25 ,r23
  ldi r26 ,low(_tmp_)  ; ������� ��� ��������� ��� ��������� ����
  ldi r27 ,high(_tmp_) ; ����������� ����� ��� �������� ����� r27:r26
  ld r23 ,X+
  ld r22 ,X
  st X ,r24            ; ���������� ��� RAM �� ��� ���������
  st -X ,r25           ; ��� ���������
  com r23
  com r22              ; ���� ���� ��������� ��� ����� ������ �������
  and r24 ,r22
  and r25 ,r23
  ret


scan_row:
  ldi r25 , 0x08  ; ������������ �� �0000 1000�
  back_: lsl r25  ; �������� �������� ��� �1� ����� ������
  dec r24         ; ���� ����� � ������� ��� �������
  brne back_
  out PORTC , r25 ; � ���������� ������ ������� ��� ������ �1�
  nop
  nop             ; ����������� ��� �� �������� �� ����� � ������ ����������
  in r24 , PINC   ; ����������� �� ������ (������) ��� ��������� ��� ����� ���������
  andi r24 ,0x0f  ; ������������� �� 4 LSB ���� �� �1� �������� ��� ����� ���������
  ret             ; �� ���������.




scan_keypad:
ldi r24 , 0x01    ; ������ ��� ����� ������ ��� �������������
rcall scan_row
swap r24          ; ���������� �� ����������
mov r27 , r24     ; ��� 4 msb ��� r27
ldi r24 ,0x02     ; ������ �� ������� ������ ��� �������������
rcall scan_row
add r27 , r24     ; ���������� �� ���������� ��� 4 lsb ��� r27
ldi r24 , 0x03    ; ������ ��� ����� ������ ��� �������������
rcall scan_row
swap r24          ; ���������� �� ����������
mov r26 , r24     ; ��� 4 msb ��� r26
ldi r24 ,0x04     ; ������ ��� ������� ������ ��� �������������
rcall scan_row
add r26 , r24     ; ���������� �� ���������� ��� 4 lsb ��� r26
movw r24 , r26    ; �������� �� ���������� ����� ����������� r25:r24
ret



keypad_to_ascii: ; ������ �1� ���� ������ ��� ���������� r26 ��������
movw r26 ,r24    ; �� �������� ������� ��� ��������
ldi r24 ,'*'
sbrc r26 ,0
ret
ldi r24 ,'0'
sbrc r26 ,1
ret
ldi r24 ,'#'
sbrc r26 ,2
ret
ldi r24 ,'D'
sbrc r26 ,3      ; �� ��� ����� �1������������ ��� ret, ������ (�� ����� �1�)
ret              ; ���������� �� ��� ���������� r24 ��� ASCII ���� ��� D.
ldi r24 ,'7'
sbrc r26 ,4
ret
ldi r24 ,'8'
sbrc r26 ,5
ret
ldi r24 ,'9'
sbrc r26 ,6
ret
ldi r24 ,'C'
sbrc r26 ,7
ret
ldi r24 ,'4'    ; ������ �1� ���� ������ ��� ���������� r27 ��������
sbrc r27 ,0     ; �� �������� ������� ��� ��������
ret
ldi r24 ,'5'
sbrc r27 ,1
ret
ldi r24 ,'6'
sbrc r27 ,2
ret
ldi r24 ,'B'
sbrc r27 ,3
ret
ldi r24 ,'1'
sbrc r27 ,4
ret
ldi r24 ,'2'
sbrc r27 ,5
ret
ldi r24 ,'3'
sbrc r27 ,6
ret
ldi r24 ,'A'
sbrc r27 ,7
ret
clr r24
ret


wait_msec:
 push r24           ; 2 ������ (0.250 �sec)
 push r25           ; 2 ������
 ldi r24 , low(998) ; ������� ��� �����. r25:r24 �� 998 (1 ������ - 0.125 �sec)
 ldi r25 , high(998); 1 ������ (0.125 �sec)
 rcall wait_usec    ; 3 ������ (0.375 �sec), �������� �������� ����������� 998.375 �sec
 pop r25            ; 2 ������ (0.250 �sec)
 pop r24            ; 2 ������
 sbiw r24 , 1       ; 2 ������
 brne wait_msec     ; 1 � 2 ������ (0.125 � 0.250 �sec)
 ret                ; 4 ������ (0.500 �sec)
wait_usec:
	sbiw r24 ,1     ; 2 cycles (0.250 �sec)
	nop             ; 1 cycle (0.125 �sec)
	nop
	nop             ; 1 cycle (0.125 �sec)
	nop             ; 1 cycle (0.125 �sec)
	nop             ; 1 cycle (0.125 �sec)
	brne wait_usec  ; 1 cycle if false 2 if true (0.125 ? 0.250 �sec)
	ret             ; 4 cycles (0.500 �sec)
