stek segment
     dw 128 dup(0)
	 ends

duom segment 
    
    a db 120     
    b dw 100
    c dw 1
    x db 10,20,25,33,50,100,255
    kiek    = $-x  ; x  masyvo dydis.
    y dw kiek dup(0AAh) ; cia vietoje klaustuko kad nemetytu random simboliu
    pran db "Skaiciavimas baigtas, spausk bet kuri klavisa", 0Dh,0Ah, 24h,  ; AX 16, AL 8
    perp DB 'Perpildymas', 0Dh, 0Ah, '$'
    daln    DB 'Dalyba is nulio', 0Dh, 0Ah, '$'
    netb    DB 'Netelpa i baita', 0Dh, 0Ah, '$'
    isvb    DB 'x=',6 dup (?), ' y=',6 dup (?), 0Dh, 0Ah, '$'  
	 ends

	 assume cs:kod, ds: duom
prog  segment
pradzia:
     mov ax, duom ; segmento registro uzkrovimas
     mov ds, ax 
     XOR si, si     
     XOR di, di      ;                       y indeksas  
     MOV cx, kiek
     JCXZ pabaiga ; soks i pabaiga jei kiek = 0
     
cikl:  
     mov ax,c
     
     mov bl,x[si]
     xor bh,bh
     
     add ax,bx
     jc kl1 
        
     cmp al,0            
                 
     jb pirmas ;soka i pirma jeigu c+x<0 t.y. niekada nebus
     jnbe trecias   ;soka i trecia, kai c+x>0
     jmp antras     ;soka be jokoio patikrinimo, nes jeigu ne daugiau ne maziau tai =0;
     
      
pirmas: ; |x| + 2a
    xor ax,ax
    xor bx,bx
    xor dx,dx
    mov al,2  ; i al registra ikeliame 2
    xor ah,ah   ;reikia nunulinti 8vyriausius bitus, nes nu tipo kitaip neveikia   
    mul a       ; dauginame al registra su a atsakymas lieka jau zodis tai tipo AX
    mov bl,x[si]    ; i bl ikeliame X, o poto nnuliname bh
    xor bh,bh   ; reikia nunulinti 8vyriausius bitus, nes nu tipo kitaip neveikia
    add ax,bx    ; ax registra sudedame su bx registru
    mov y[di],ax  ;atsakyma t.y. AX registra ikeliame i Y
    
    jmp ger
    
antras:  ;4b-c^2
    xor ax,ax
    xor bx,bx
    xor dx,dx
	mov al,4       ; i al ikeliame 4
	xor ah,ah      ; nunuliname kairius 8bitus AX registro
	mul b          ; dauginame ax su b  
	jc kl1;   chekina perpildyma
	mov bx, ax     ; i bx registra isikeliame ax registra, kad neprarastumem duomenu
	mov ax,c       ; i ax isikeliame c 	
	mul c          ; dauginame ax su c
	jc kl1      ; chekina perpildyma
	xchg ax,bx     ; paswapiname registrus kad galetumem 4b-c^2 padaryti vietoj c^2-4b     
	sub ax,bx      ; atemame ax registra is bx registro t.y. 4b-c^2
	jc kl1       ; chekina perpildyma
	mov y[di],ax  ;atsakyma t.y. AX registra ikeliame i Y
	
	jmp ger
	
trecias: ; c+b / x+c
    xor ax,ax
    xor bx,bx
    xor dx,dx   
    mov ax,c ; c yra zodis, tai i ax idedame x
    add ax,b    ; ax registra sudedame su b, kadangi jie vstk zodziai
    jc kl1       ; chekina perpildyma
    mov bx,ax  ; perkeliame ax i bx, kadangi mums reikes to ax
    mov al,x[si]    ; x (baita) ikeliame i desne skilti
    xor ah,ah ;padarome kad ax butu zodis 
    add ax,c  ; prie ax pridedame c
    jc kl1       ; chekina perpildyma
    jz kl2     ; chekina ar ax registre yra nulis, jeigu nulis reiskia blogai
    xchg bx,ax ; apkeiciame bx su ax, kad gautusi vietoj x+c/c+b --> c+b/x+c
    div bx      ; ax/bx
    jc kl1       ; chekina perpildyma
    mov y[di],ax  ;atsakyma t.y. AX registra ikeliame i Y
    
    jmp ger 
       
re:
    CMP ah, 0     ;ar telpa rezultatasi baita
    JE ger
    JMP kl3
ger:   
    INC si
    INC di
    INC di ; si incrementinam 1 karta nes byte, di du kartus nes word indeksas. (turbut)
    LOOP cikl
    	 
pabaiga:       
    ;rezultatu isvedimas i ekrana
    ;============================
    XOR si, si
    XOR di, di
    MOV cx, kiek
    JCXZ is_pab
is_cikl:
    MOV al, x[si]  ; isvedamas skaicius x yra ax reg.
    xor ah,ah
    PUSH ax
    MOV bx, offset isvb+2
    PUSH bx
    CALL binasc
    MOV ax, y[di]
    ;XOR ah, ah        ; isvedamas skaicius y yra ax reg.
    PUSH ax
    MOV bx, offset isvb+11
    PUSH bx
    CALL binasc
    
    MOV dx, offset isvb
    MOV ah, 9h
    INT 21h
    ;============================
    INC si
    INC di
    INC di
    LOOP is_cikl
    is_pab:
    ;===== PAUZE ===================
    ;===== paspausti bet kuri klavisa ===
    LEA dx, pran
    MOV ah, 9
    INT 21h
    MOV ah, 0
    INT 16h
    ;============================
    MOV ah, 4Ch   ; programos pabaiga, grizti i OS
    INT 21h
    ;============================
    
    kl1:    LEA dx, perp
    MOV ah, 9
    INT 21h
    XOR ax, ax
    JMP ger
    kl2:    LEA dx, daln
    MOV ah, 9
    INT 21h
    XOR ax, ax
    JMP ger
    kl3:    LEA dx, netb
    MOV ah, 9
    INT 21h
    XOR ax, ax
    JMP ger
    
    ; skaiciu vercia i desimtaine sist. ir issaugo
    ; ASCII kode. Parametrai perduodami per steka
    ; Pirmasis parametras ([bp+6])- verciamas skaicius
    ; Antrasis parametras ([bp+4])- vieta rezultatui
    
    binasc    PROC NEAR
    PUSH bp
    MOV bp, sp
    ; naudojamu registru issaugojimas
    PUSHA
    ; rezultato eilute uzpildome tarpais
    MOV cx, 6
    MOV bx, [bp+4]
    tarp:    MOV byte ptr[bx], ' '
    INC bx
    LOOP tarp
    ; skaicius paruosiamas dalybai is 10
    MOV ax, [bp+6]
    MOV si, 10
    val:    XOR dx, dx
    DIV si
    ;  gauta liekana verciame i ASCII koda
    ADD dx, '0'   ; galima--> ADD dx, 30h
    ;  irasome skaitmeni i eilutes pabaiga
    DEC bx
    MOV [bx], dl
    ; skaiciuojame pervestu simboliu kieki
    INC cx
    ; ar dar reikia kartoti dalyba?
    CMP ax, 0
    JNZ val
    
    POPA
    POP bp
    RET
    binasc    ENDP
    prog    ENDS
    END pradzia