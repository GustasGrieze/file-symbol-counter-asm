.model small
    skBufDydis EQU 20                   ; Buffer size for reading.
    raBufDydis EQU 60                   ; Buffer size for writing.

.stack 100h

.data
    pagalbosZinute db '----------------------------------------------------',10,13
                   db 'Programa vieno failo simbolius uzraso i kita faila',10,13
                   db 'sesioliktainiais skaitmenimis.',10,13
                   db '----------------------------------------------------',10,13
                   db 'Programai butina perduot du parametrus-failu vardus! ',10,13
                   db 'Pirmas parametras: Duomenu failo pavadinimas,',10,13
                   db 'Antras parametras: Rezultatu failo pavadinimas',10,13
                   db '----------------------------------------------------',10,13
                   db 'Atliko: Gustas Grieze, 1 grupe',10,13, '$'
    sekmesZinute  db 'Operacijos atliktos sekmingai',10,13,'$'
    duom          db 50 dup(0)
    rez           db 50 dup(0)
    skBuf         db skBufDydis dup (?)  ; Read buffer
    raBuf         db raBufDydis dup (?)  ; Write buffer
    dFail         dw ?                  ; File descriptor for input file
    rFail         dw ?                  ; File descriptor for output file
    kiek          dw 0

.code
pradzia:
    MOV ax, @data                      ; Loads the address of the data segment into AX.
    MOV ds, ax                         ; Sets the data segment register (DS) to AX.

    ; Read command line parameters
    CMP byte ptr[ES:80h],0             ; Check if command line parameters are provided.
    JE jumpParam                       ; Jump to 'jumpParam' if no parameters.
    JMP nextParam                      ; Otherwise, jump to 'nextParam'.

    JumpParam:
        JMP help_pabaiga               ; Jump to display help message and exit.
    nextParam:
        XOR cx,cx                      ; Clear CX register.
        MOV cl,byte ptr[ES:80h]        ; Load the length of the command-line input.
        DEC cl                         ; Decrement CL for the length byte.
        DEC cl                         ; Decrement CL to skip the program name.
        MOV SI,82h                     ; Set SI to the start of the actual parameters.
        MOV DI,offset duom             ; Set DI to the 'duom' buffer.

    ; Read first parameter
    paramCiklas1:
        CMP byte ptr[ES:SI],20h        ; Compare current character to a space.
        JE paramToliau                 ; Jump if a space is found.
        XOR ax,ax                      ; Clear AX register.
        MOV al,byte ptr[ES:SI]         ; Load current character into AL.
        MOV byte ptr[DS:DI],Al         ; Move character to 'duom' buffer.
        INC DI                         ; Increment DI.
        INC SI                         ; Increment SI.
        DEC cx                         ; Decrement CX.
        CMP cx,0                       ; Check if all characters are processed.
        JE paramToliau                 ; Jump if all characters are processed.
        JMP paramCiklas1               ; Continue reading first parameter.

    ; Read second parameter
    paramToliau:
        INC SI                         ; Increment SI.
        MOV DI,offset rez              ; Set DI to 'rez' buffer.
    paramCiklas2:
        CMP byte ptr[ES:SI],20h        ; Compare current character to a space.
        JE JumpParam2                  ; Jump if a space is found.
        JMP nextParam2                 ; Continue reading the parameter.
    JumpParam2:
        JMP help_pabaiga               ; Jump to display help message and exit.
    NextParam2:
        XOR ax,ax                      ; Clear AX register.
        MOV al,byte ptr[ES:SI]         ; Load current character into AL.
        MOV byte ptr[DS:DI],al         ; Store character in 'rez' buffer.
        INC DI                         ; Increment DI.
        INC SI                         ; Increment SI.
        DEC cx                         ; Decrement CX.
        CMP cx,0                       ; Check if all characters are processed.
        JE paramToliau2                ; Jump if all characters are processed.
        JMP paramCiklas2               ; Continue reading second parameter.
    paramToliau2:
        ; Open input file for reading
        MOV ah, 3Dh                    ; Function number for opening a file.
        MOV al, 00                     ; Mode 0 for reading.
        MOV dx, offset duom            ; Point DX to 'duom' buffer.
        INT 21h                        ; Call interrupt 21h.
        JNC next1                      ; Jump if no error.
        JMP klaidaAtidarantSkaitymui   ; Jump to error handling if error.
    next1:
        MOV dFail, ax                  ; Store file handle in 'dFail'.
        ; Creating and opening the output file for writing
        MOV ah, 3Ch                    ; Function number for creating a new file.
        MOV cx, 0                      ; File attributes (normal file).
        MOV dx, offset rez             ; Point DX to 'rez' buffer, containing output file name.
        INT 21h                        ; Call interrupt 21h to create the file.
        JC sokt2                       ; Jump to error handling if error occurred.
        JMP next2                      ; Continue if no error.
    sokt2:
        JMP klaidaAtidarantRasymui     ; Jump to error handling for file creation error.
    next2:
        MOV rFail, ax                  ; Store file handle in 'rFail'.

        ; Reading data from the input file
    skaityk:
        MOV bx, dFail                  ; Load input file handle into BX.
        CALL SkaitykBuf                ; Call 'SkaitykBuf' to read data.
        CMP ax, 0                      ; Check if end of the file is reached.
        JE uzdarytiRasymui             ; Jump to close output file if end of file.

        ; Processing the read data
        MOV cx, ax                     ; Move number of bytes read into CX.
        MOV word ptr[kiek],cx          ; Store number of bytes read in 'kiek'.
        MOV si, offset skBuf           ; Point SI to start of read buffer.
        MOV di, offset raBuf           ; Point DI to start of write buffer.
        MOV [kiek],0                   ; Reset 'kiek' counter.
    dirbk:
        XOR ax,ax                      ; Clear AX register.
        MOV al,byte ptr[SI]            ; Load byte from read buffer into AL.
        MOV dl,10h                     ; Set DL to 16 (hexadecimal base).
        DIV dl                         ; Divide AX by DL.

        ; Check if the number is between 0-9
        CMP al,0                       ; Compare AL to 0.
        JAE toliau1                    ; Jump if AL >= 0.
        JMP raide1                     ; Jump to handle alphabetic characters.
    toliau1:
        CMP al,9                       ; Compare AL to 9.
        JBE skaicius1                  ; Jump if it's a digit.
    raide1:
        ADD al,37h                     ; Convert to ASCII if it's a letter.
        MOV byte ptr[DI],al            ; Store converted character.
        JMP kitas                      ; Jump to next operation.
    skaicius1:
        ADD al,'0'                     ; Convert digit to ASCII.
        MOV byte ptr[DI],al            ; Store digit.
    kitas:
        INC [kiek]                     ; Increment 'kiek' counter.
        INC DI                         ; Move to next position in write buffer.
        CMP ah,0                       ; Compare high byte of AX (remainder) to 0.
        JAE toliau2                    ; Jump if AH >= 0.
        JMP raide2                     ; Jump for alphabetic character handling.
    toliau2:
        CMP ah,9                       ; Compare AH to 9.
        JBE skaicius2                  ; Jump if it's a digit.
    raide2:
        ADD ah,37h                     ; Convert to ASCII if it's a letter.
        MOV byte ptr[DI],ah            ; Store converted character in write buffer.
        JMP baigem                     ; Jump to next operation.
    skaicius2:
        ADD ah,'0'                     ; Convert digit to ASCII.
        MOV byte ptr[DI],ah            ; Store digit in write buffer.
    baigem:
        INC [kiek]                     ; Increment 'kiek' counter.
        INC DI                         ; Move to next position in write buffer.
        MOV byte ptr[DI],20h           ; Add a space after each byte in write buffer.
        INC [kiek]                     ; Increment 'kiek' counter.
        INC DI                         ; Move to next position in write buffer.
        INC SI                         ; Move to next byte in read buffer.
        DEC cx                         ; Decrement byte count.
        CMP cx,0                       ; Check if all bytes are processed.
        JNE dirbk                      ; If not, continue loop.

        ; Writing result to file
        MOV cx, [kiek]                 ; Set number of bytes to write.
        MOV bx, rFail                  ; Load output file handle into BX.
        CALL RasykBuf                  ; Call 'RasykBuf' to write data.
        CMP ax, raBufDydis             ; Compare bytes written to buffer size.
        JE skaityk                     ; If full buffer written, read more data.

        ; Closing the output file
    uzdarytiRasymui:
        MOV ah, 3Eh                    ; Function number for closing a file.
        MOV bx, rFail                  ; Load output file handle into BX.
        INT 21h                        ; Call interrupt 21h to close file.
        JC klaidaUzdarantRasymui       ; Jump if error occurs.

        ; Closing the input file
    uzdarytiSkaitymui:
        MOV ah, 3Eh                    ; Function number for closing a file.
        MOV bx, dFail                  ; Load input file handle into BX.
        INT 21h                        ; Call interrupt 21h to close file.
        JC klaidaUzdarantSkaitymui     ; Jump if error occurs.
        MOV ah,9                       ; Function for displaying a string.
        MOV DX,offset sekmesZinute     ; Point to success message.
        INT 21h                        ; Display success message.
        JMP pabaiga                    ; Jump to program end.

    help_pabaiga:
        MOV ah,9                       ; Function for displaying a string.
        MOV DX,offset pagalbosZinute   ; Point to help message.
        INT 21h                        ; Display help message.

    pabaiga:
        MOV ah, 4Ch                    ; Function for terminating program.
        MOV al, 0                      ; Return code of program.
        INT 21h                        ; Terminate program.

        ; Error handling
    klaidaAtidarantSkaitymui:
        MOV ah,9                       ; Function for displaying a string.
        MOV DX,offset pagalbosZinute   ; Point to help message.
        INT 21h                        ; Display help message.
        JMP pabaiga                    ; Jump to program end.

    klaidaAtidarantRasymui:
        MOV ah,9                       ; Function for displaying a string.
        MOV DX,offset pagalbosZinute   ; Point to help message.
        INT 21h                        ; Display help message.
        JMP uzdarytiSkaitymui          ; Jump to close input file.

    klaidaUzdarantRasymui:
        JMP uzdarytiSkaitymui          ; Jump to close input file.

    klaidaUzdarantSkaitymui:
        JMP pabaiga                    ; Jump to program end.

;*****************************************************
; Reading from a file procedure
;*****************************************************
PROC SkaitykBuf
    ; BX receives the file descriptor number.
    ; AX will return the number of symbols read.
    PUSH cx                          ; Save CX register on stack.
    PUSH dx                          ; Save DX register on stack.
    MOV ah, 3Fh                      ; Function number for reading from file.
    MOV cl, skBufDydis               ; Set CL to read buffer size.
    MOV ch, 0                        ; Clear high byte of CX.
    MOV dx, offset skBuf             ; Point DX to read buffer.
    INT 21h                          ; Call interrupt to read from file.
    JC klaidaSkaitant                ; Jump if error occurs.

SkaitykBufPabaiga:
    POP dx                           ; Restore DX register from stack.
    POP cx                           ; Restore CX register from stack.
    RET                              ; Return from procedure.

klaidaSkaitant:
    ; Error message code here.
    MOV ax, 0                        ; Indicate no bytes were read.
    JMP SkaitykBufPabaiga            ; Jump to end of procedure.
SkaitykBuf ENDP

;*****************************************************
; Writing to a file procedure
;*****************************************************
PROC RasykBuf
    ; BX receives the file descriptor number.
    ; CX is how many bytes to write.
    ; AX will return the number of bytes written.
    PUSH dx                          ; Save DX register on stack.

    MOV ah, 40h                      ; Function number for writing to a file.
    MOV dx, offset raBuf             ; Point DX to write buffer.
    INT 21h                          ; Call interrupt to write to the file.
    JC klaidaRasant                  ; Jump if error occurs.
    CMP cx, ax                       ; Compare bytes to write with bytes written.
    JNE dalinisIrasymas              ; Jump if not all bytes were written.

RasykBufPabaiga:
    POP dx                           ; Restore DX register from stack.
    RET                              ; Return from procedure.

dalinisIrasymas:
    ; Error message code here
    JMP RasykBufPabaiga              ; Jump to end of procedure.

klaidaRasant:
    ; Error message code here.
    MOV ax, 0                        ; Indicate no bytes were written.
    JMP RasykBufPabaiga              ; Jump to end of procedure.
RasykBuf ENDP

END pradzia                         ; End of the program.
