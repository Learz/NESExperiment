;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Premier test d'assembleur NES
;	Création: Marc-Antoine Renaud, 10 septembre 2013
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;; Entête de la rom ;;;;;;;;;;;
  .inesprg 1 ; 1 banque de 16KB (2 banque de 8KB) pour le programme
  .ineschr 1 ; 1 banque de 8KB pour les image (2 tables de motifs)
  .inesmap 0 ; mapper 0 = NROM, Banque par défaut
  .inesmir 1 ; Mirroir vertical de l'image de fond

;;;;;;;;;;;;;;BANK 0;;;;;;;;;;;;;;;;
  .bank 0
  .org $8000

RESET:
	SEI         ; Arreter les interruption, Met le bit I du registre P (etat du processeur) a 1
	CLD         ; Arrete le mode decimal. Met le bit D du registre P à 0
	LDX #$40
	STX $4017  ;  Met $40 dans le registre de controle de l'APU pour arreter les interruptions de l'APU
	LDX #$FF
	TXS         ; Initialise la pile. Place X ($FF$ comme octet moins significatif de l'adresse de la pile). La pile est toujours entre $0100 et $01FF.
	INX         ; Lorsqu'on incremente X qui contient $FF, C tombe à 0
	STX $2000  ;  Arrete les interruption NMI (Bit 7 du registre Contrôle PPU)
	STX $2001  ;  N'affiche rien (Voir bits 3 à 7 du registre Masque PPU)
	STX $4010  ;  Arrete les interruption logiciel

vblankwait1:
	BIT $2002		; Bit place les Code de condition N, V, Z.
	BPL vblankwait1	; Si le bit 7 est allumé, on a un vblank (BPL = N flag clear, le bit de negatif = bit 7)

clrmem:
	LDA #$00
	;STA $0000,  x		; Place tous les octets à 0 (", x" correspond a l'adressage indexe avec le registre x)
	STA $0100,  x
	STA $0300,  x
	STA $0400,  x
	STA $0500,  x
	STA $0600,  x
	STA $0700, x
	LDA #$FE
	STA $0200, x		; Placer tous les sprite en dehors de l'écran
	INX
	BNE clrmem		; Branche si non zero (lorsque x a fait le tour des valeurs de 0 à FF)

vblankwait2:			; Attent le prochain vblank (voir vblankwait1)
	BIT $2002
	BPL vblankwait2

LoadPalettes:
  LDA $2002    ; read PPU status to reset the high/low latch to high
  LDA #$3F
  STA $2006    ; write the high byte of $3F10 address
  LDA #$00
  STA $2006    ; write the low byte of $3F10 address
  LDX #$00                ; start out at 0

LoadPalettesLoop:
  LDA PaletteData, x      ; load data from address (PaletteData + the value in x)
  STA $2007               ; write to PPU
  INX                     ; X ++
  CPX #$20                ; Compare X to hex $20, decimal 32
  BNE LoadPalettesLoop    ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                          ; if compare was equal to 32, keep going down

; Initialisation des sprites
	LDX #$00
LoadSpritesData:
	LDA SpriteData, x
	STA $0200, x
	INX
	CPX #$6C
	BNE LoadSpritesData

LoadBackground:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address

  LDX #$00              ; start out at 0
LoadBackgroundLoop:
  LDA background, x     ; load data from address (background + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$F0              ; Compare X to hex $F0
  BNE LoadBackgroundLoop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero

  LDX #$00              ; start out at 0
LoadBackground1Loop:
  LDA background1, x     ; load data from address (background + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$F0             ; Compare X to hex $F0
  BNE LoadBackground1Loop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero

  LDX #$00              ; start out at 0
LoadBackground2Loop:
  LDA background2, x     ; load data from address (background + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$F0             ; Compare X to hex $80, decimal 128 - copying 128 bytes
  BNE LoadBackground2Loop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero

  LDX #$00              ; start out at 0
LoadBackground3Loop:
  LDA background3, x     ; load data from address (background + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$F0              ; Compare X to hex $F0
  BNE LoadBackground3Loop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero

LoadAttribute:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23C0 address
  LDA #$C0
  STA $2006             ; write the low byte of $23C0 address
  LDX #$00              ; start out at 0
LoadAttributeLoop:
  LDA attribute, x      ; load data from address (attribute + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$78              ; Compare X to hex $20, decimal  - copying  bytes
  BNE LoadAttributeLoop  ; Branch to LoadAttributeLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down

vblankwait3:		; Attend le prochain vblank
	BIT $2002
	BPL vblankwait3

initPPU:
  LDA #%10001000
  STA $2000
  LDA #%00011110
  STA $2001
  LDA #$00		;Ne pas faire de defilement d'image
  STA $2005
  STA $2005
  
  LDA #$00
  STA var1

Forever:
  JMP Forever
  
NMI:
  LDA #$00
  STA $2003
  LDA #$02
  STA $4014

Frame:
  LDX #$04
  STX $0201
  LDX #$08
  STX $0265
  STX $0269
  
  LDA frame
  SEC
  CMP #$00
  BMI EndFrame5
  LDX #$05
  STX $0201
EndFrame1:
  LDX #$04
  STX $0215
  CMP #$10
  BMI EndFrame5
  LDX #$05
  STX $0215
EndFrame2:
  LDX #$04
  STX $0229
  CMP #$20
  BMI EndFrame5
  LDX #$05
  STX $0229
EndFrame3:
  LDX #$04
  STX $023D
  CMP #$30
  BMI EndFrame5
  LDX #$05
  STX $023D
EndFrame4:
  LDX #$04
  STX $0251
  CMP #$40
  BMI EndFrame5
  LDX #$05
  STX $0251
EndFrame5:
  CMP #$25
  BMI EndBird
  LDX #$09
  STX $0265
  STX $0269
EndBird:
  CLC
  ADC #$01
  CMP #$50
  BMI ContinueFrame
  LDA #$00
ContinueFrame:
  STA frame
  
LatchController:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
;|||||||||||||||||||||||||||||||||||ENTRÉES CONTROLLEUR||||||||||||||||||||||||||||||||||;
;;;;;;;;;;;;MANETTE 1;;;;;;;;;;;

  LDA $0207
  CLC
  ADC #$04
  STA $0203
  LDA $0204
  CLC
  ADC #$04
  STA $0200

  LDA $4016        ; a
  LDA $4016		   ; b
R1Select:
  LDA $4016
  AND #%00000001
  BEQ R1SelectDone

  LDA #%00000000
  STA $0202
  STA $0206
  STA $020A
  STA $020E
  STA $0212
R1SelectDone:

R1Start:
  LDA $4016
  AND #%00000001
  BEQ R1StartDone

  LDA #%00000011
  STA $0202
  STA $0206
  STA $020A
  STA $020E
  STA $0212
R1StartDone:

R1Up:
  LDA $4016
  AND #%00000001
  BEQ R1UpDone

  LDA $0200
  SBC #$5A
  BEQ R1UpDone

  LDA $0204
  SEC
  SBC #$01
  STA $0204
  STA $0208
  CLC
  ADC #$03
  STA $0200
  CLC
  ADC #$05
  STA $020C
  STA $0210
R1UpDone:

R1Down:
  LDA $4016
  AND #%00000001
  BEQ R1DownDone

  LDA $0200
  SBC #$DA
  BEQ R1DownDone

  LDA $0204
  CLC
  ADC #$01
  STA $0204
  STA $0208
  CLC
  ADC #$05
  STA $0200
  CLC
  ADC #$03
  STA $020C
  STA $0210
R1DownDone:

R1Left:
  LDA $4016
  AND #%00000001
  BEQ R1LeftDone

  LDA $0207
  SEC
  SBC #$01
  STA $0207
  STA $020F
  CLC
  ADC #$03
  STA $0203
  CLC
  ADC #$05
  STA $020B
  STA $0213
R1LeftDone:

R1Right:
  LDA $4016
  AND #%00000001
  BEQ R1RightDone

  LDA $0207
  CLC
  ADC #$01
  STA $0207
  STA $020F
  CLC
  ADC #$05
  STA $0203
  CLC
  ADC #$03
  STA $020B
  STA $0213
R1RightDone:

;;;;;;;;;;;;MANETTE 2;;;;;;;;;;;    
R2A:
  LDA $4017       ; a
  AND #%00000001
  BEQ R2ADone
  
  LDA #$00
  STA var1
R2ADone:

R2B:
  LDA $4017		  ; b
  AND #%00000001
  BEQ R2BDone
  
  LDA #$14
  STA var1  
R2BDone:

  LDX var1
  
  LDA $021B,x
  CLC
  ADC #$04
  STA $0217,x
  LDA $0218,x
  CLC
  ADC #$04
  STA $0214,x

R2Select:
  LDA $4017
  AND #%00000001
  BEQ R2SelectDone

  LDA #$28
  STA var1
R2SelectDone:

R2Start:
  LDA $4017
  AND #%00000001
  BEQ R2StartDone

  LDA #$3C
  STA var1
R2StartDone:

R2Up:
  LDA $4017
  AND #%00000001
  BEQ R2UpDone

  LDA $0214,x
  SBC #$5A
  BEQ R2UpDone

  LDA $0218,x
  SEC
  SBC #$01
  STA $0218,x
  STA $021C,x
  CLC
  ADC #$08
  STA $0220,x
  STA $0224,x
R2UpDone:

R2Down:
  LDA $4017
  AND #%00000001
  BEQ R2DownDone

  LDA $0214,x
  SBC #$DA
  BEQ R2DownDone

  LDA $0218,x
  CLC
  ADC #$01
  STA $0218,x
  STA $021C,x
  CLC
  ADC #$08
  STA $0220,x
  STA $0224,x
R2DownDone:

R2Left:
  LDA $4017
  AND #%00000001
  BEQ R2LeftDone

  LDA $021B,x
  SEC
  SBC #$01
  STA $021B,x
  STA $0223,x
  CLC
  ADC #$08
  STA $0227,x
  STA $021F,x
R2LeftDone:

R2Right:
  LDA $4017
  AND #%00000001
  BEQ R2RightDone

  LDA $021B,x
  CLC
  ADC #$01
  STA $021B,x
  STA $0223,x
  ADC #$08
  STA $0227,x
  STA $021F,x
R2RightDone: 

assezBas:
  LDA #$06
  STA $0201
  STA $0215,x

  LDA $0214,x
  ADC #$30
  SBC $0200
  BMI pasDansZone
assezHaut:
  LDA $0214,x
  SBC #$20
  SBC $0200
  BPL pasDansZone
assezDroite:
  LDA $0217,x
  SBC #$20
  SBC $0213
  BPL pasDansZone
assezGauche:
  LDA $0217,x
  ADC #$20
  SBC $0213
  BMI pasDansZone  

  LDA #$04
  STA $0201
  STA $0215,x
pasDansZone:

  LDA $0267
  CLC
  ADC #$01
  STA $0267
  
  LDA $026B
  SEC
  SBC #$01
  STA $026B
  
  RTI             ; retourne de l'interruption


;;;;;;;;;;;;;;BANK 1;;;;;;;;;;;;;;;
  .bank 1
  .org $E000
PaletteData:
  .db $12,$1A,$0A,$0A,$12,$19,$29,$39,$12,$09,$0A,$0B,$12,$30,$31,$21  ;background
  .db $12,$28,$18,$08,$12,$21,$11,$01,$12,$26,$16,$06,$12,$34,$24,$14  ;sprite

SpriteData:
  ;Joueur 1
  .db $83, $04, %00000000, $14  ; SpriteB1 $0200
  .db $7F, $00, %00000000, $10	; SpriteA1 $0204
  .db $7F, $01, %00000000, $18	; SpriteA2 $0208
  .db $87, $02, %00000000, $10	; SpriteA3 $020C
  .db $87, $03, %00000000, $18	; SpriteA4 $0210

  ;Joueur 2-1
  .db $83, $04, %00000011, $24  ; SpriteB1 $0214
  .db $7F, $00, %00000011, $20	; SpriteA1 $0218
  .db $7F, $01, %00000011, $28	; SpriteA2 $021C
  .db $87, $02, %00000011, $20	; SpriteA3 $0220
  .db $87, $03, %00000011, $28	; SpriteA4 $0224
  
  ;Joueur 2-2
  .db $A3, $04, %00000001, $14  ; SpriteB1 $0228
  .db $9F, $00, %00000001, $10	; SpriteA1 $022C
  .db $9F, $01, %00000001, $18	; SpriteA2 $0230
  .db $A7, $02, %00000001, $10	; SpriteA3 $0234
  .db $A7, $03, %00000001, $18	; SpriteA4 $0238
  
  ;Joueur 2-3
  .db $A3, $04, %00000010, $24  ; SpriteB1 $023C
  .db $9F, $00, %00000000, $20	; SpriteA1 $0240
  .db $9F, $01, %00000000, $28	; SpriteA2 $0244
  .db $A7, $02, %00000000, $20	; SpriteA3 $0248
  .db $A7, $03, %00000000, $28	; SpriteA4 $024C
  
  ;Joueur 2-3
  .db $93, $04, %00000000, $1C  ; SpriteB1 $0250
  .db $8F, $00, %00000010, $18	; SpriteA1 $0254
  .db $8F, $01, %00000010, $20	; SpriteA2 $0258
  .db $97, $02, %00000010, $18	; SpriteA3 $025C
  .db $97, $03, %00000010, $20	; SpriteA4 $0260
  
  .db $15, $08, %00000001, $15  ; SpritLuv $0264
  .db $40, $09, %00100001, $40  ; SpritLuv $0268

background:
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01  ;;ligne 1
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01  ;;ligne 2
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01  ;;ligne 3
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
  .db $01,$01,$01,$01,$01,$01,$01,$01,$04,$05,$06,$01,$01,$01,$01,$01  ;;ligne 4
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
  .db $01,$01,$01,$01,$01,$01,$01,$07,$08,$09,$0A,$01,$01,$01,$01,$01  ;;ligne 5
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$04,$05,$06,$01,$01
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01  ;;ligne 6
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$07,$08,$09,$0A,$01,$01
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01  ;;ligne 7
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01  ;;ligne 8
background1:
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01  ;;ligne 9
  .db $01,$01,$01,$01,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$01,$01
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01  ;;ligne 10
  .db $01,$01,$01,$01,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$01,$01
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01  ;;ligne 11
  .db $01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01  ;;ligne 12
  .db $01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 13
  .db $0B,$0B,$0B,$0B,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0B,$0B
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 14
  .db $0B,$0B,$0B,$0B,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0B,$0B
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 15
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
background2:
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 16
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 17
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 18
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 19
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 20
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
  .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;;ligne 21
  .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;;ligne 22
  .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 23
background3:
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 24
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 25
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 26
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 27
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 28
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 29
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B  ;;ligne 30
  .db $0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B

attribute:
  .db %11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111
  .db %11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111
  .db %11111111,%11111111,%11111111,%11111111,%11111111,%10100101,%10100101,%10100101
  .db %01010101,%01010101,%01010101,%01010101,%01010101,%01011010,%01011010,%01010110
  .db %01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101
  .db %01011010,%01011010,%01011010,%01011010,%01011010,%01011010,%01011010,%01011010
  .db %01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101
  .db %01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%01010101


  .org $FFFA     ;Début du premier interrupteur
  .dw NMI
  .dw RESET
  .dw 0

;;;;;;;;;;;;BANK 2;;;;;;;;;;;;;;;;;
  .bank 2
  .org $1000
SpriteA1:
	.db %00000000
	.db %00000011
	.db %00111111
	.db %00111111
	.db %01111111
	.db %01111111
	.db %11111111
	.db %11111111

	.db %00000011
	.db %00001100
	.db %00110000
	.db %00100000
	.db %01000000
	.db %01000000
	.db %10000000
	.db %10000000

SpriteA2:
	.db %00000000
	.db %11000000
	.db %11110000
	.db %11111000
	.db %11111100
	.db %11111100
	.db %11111110
	.db %11111110

	.db %11000000
	.db %00110000
	.db %00001100
	.db %00000100
	.db %00000010
	.db %00000010
	.db %00000001
	.db %00000001

SpriteA3:
	.db %11111111
	.db %11111111
	.db %01111111
	.db %01111111
	.db %00111111
	.db %00111111
	.db %00001111
	.db %00000011

	.db %10000000
	.db %10000000
	.db %01000000
	.db %01000000
	.db %00100000
	.db %00110000
	.db %00001100
	.db %00000011

SpriteA4:
	.db %11111111
	.db %11111111
	.db %11111110
	.db %11111110
	.db %11111100
	.db %11111100
	.db %11110000
	.db %11000000

	.db %00000001
	.db %00000001
	.db %00000010
	.db %00000010
	.db %00000100
	.db %00001100
	.db %00110000
	.db %11000000

SpriteB1:
	.db %00000000
	.db %01000100
	.db %01100110
	.db %00000000
	.db %00000000
	.db %01000000
	.db %01100000
	.db %00110000

	.db %01000100
	.db %01100110
	.db %01100110
	.db %00000000
	.db %00000000
	.db %01111110
	.db %01111110
	.db %00111100

SpriteB2:
	.db %00000000
	.db %01100110
	.db %00000000
	.db %00000000
	.db %00000000
	.db %01000000
	.db %01100000
	.db %00110000

	.db %00000000
	.db %01100110
	.db %00000000
	.db %00000000
	.db %00000000
	.db %01111110
	.db %01111110
	.db %00111100
	
SpriteB3:
	.db %00000000
	.db %01000100
	.db %01100110
	.db %00000000
	.db %00000000
	.db %00000000
	.db %01100000
	.db %01110000

	.db %01000100
	.db %01100110
	.db %01100110
	.db %00000000
	.db %00000000
	.db %00111100
	.db %01111110
	.db %01111110
	
SpriteLuv:
	.db %00000110
	.db %00011111
	.db %00011111
	.db %00001110
	.db %00000100
	.db %00000000
	.db %00000000
	.db %00000000

	.db %01100000
	.db %11100000
	.db %11100000
	.db %01110000
	.db %00111000
	.db %00011000
	.db %00000000
	.db %00000000
	
birdFlapUp:
	.db %00000000
	.db %00000000
	.db %00111100
	.db %01111110
	.db %11000011
	.db %00000000
	.db %00000000
	.db %00000000
	
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	
birdFlapDn:
	.db %00000000
	.db %11000011
	.db %01111110
	.db %00111100
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000

  .org $0000

sol:
	.db %11110000
	.db %11110000
	.db %11110000
	.db %11110000
	.db %00001111
	.db %00001111
	.db %00001111
	.db %00001111

	.db %00001111
	.db %00001111
	.db %00001111
	.db %00001111
	.db %11110000
	.db %11110000
	.db %11110000
	.db %11110000

ciel:
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000

	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000

nuagePetit:
	.db %00111100
	.db %01000010
	.db %10000001
	.db %10000111
	.db %10001111
	.db %11011111
	.db %01111111
	.db %00111111

	.db %00111100
	.db %01111110
	.db %11111111
	.db %11111000
	.db %11110000
	.db %11100000
	.db %01111111
	.db %00111111

nuagePetit1:
	.db %00000000
	.db %01110000
	.db %10011100
	.db %11111110
	.db %11000111
	.db %10111111
	.db %11111111
	.db %11111110

	.db %00000000
	.db %01110000
	.db %11101100
	.db %00000010
	.db %00111001
	.db %01000001
	.db %00000001
	.db %11111110

nuageGran0:
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000011
	.db %00000101
	.db %11001011

	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000000
	.db %00000011
	.db %00000110
	.db %11001100

nuageGrand1:
	.db %00000000
	.db %00000001
	.db %00000010
	.db %00000010
	.db %00001111
	.db %10010011
	.db %11100111
	.db %11111111

	.db %00000000
	.db %00000001
	.db %00000011
	.db %00000011
	.db %00001110
	.db %10011110
	.db %01111001
	.db %01000000

nuageGrand2:
	.db %11110000
	.db %11001000
	.db %10001100
	.db %00001100
	.db %00011100
	.db %00111100
	.db %11111100
	.db %01110110

	.db %11110000
	.db %00111000
	.db %01111100
	.db %11111100
	.db %11111100
	.db %11111100
	.db %11111100
	.db %11111110

nuageGrand3:
	.db %00000001
	.db %00011110
	.db %00111000
	.db %01100001
	.db %01000000
	.db %00110111
	.db %00001110
	.db %00000011

	.db %00000001
	.db %00011111
	.db %00100111
	.db %01011111
	.db %01111111
	.db %00111111
	.db %00001111
	.db %00000011

nuageGrand4:
	.db %10101000
	.db %01010000
	.db %11001111
	.db %11011111
	.db %10010111
	.db %00110111
	.db %11111011
	.db %11111111

	.db %01101111
	.db %11111111
	.db %11111111
	.db %11111111
	.db %11111110
	.db %11111110
	.db %11111111
	.db %11111111

nuageGrand5:
	.db %01100000
	.db %11100011
	.db %11011111
	.db %10001110
	.db %10100001
	.db %00110000
	.db %11111111
	.db %11111111

	.db %11111111
	.db %11111111
	.db %11111111
	.db %11111111
	.db %01111110
	.db %11111111
	.db %11111111
	.db %11111111

nuageGrand6:
	.db %11000111
	.db %11101111
	.db %11101111
	.db %10011111
	.db %01111111
	.db %11111110
	.db %11111110
	.db %11111100

	.db %11111111
	.db %11011111
	.db %10011111
	.db %01111111
	.db %11111111
	.db %11111110
	.db %11111110
	.db %11111100
	
sol2:
	.db %11110000
	.db %11110000
	.db %00001111
	.db %00001111
	.db %11110000
	.db %11110000
	.db %00001111
	.db %00001111

	.db %00001111
	.db %00001111
	.db %11110000
	.db %11110000
	.db %00001111
	.db %00001111
	.db %11110000
	.db %11110000
	
sol3:
	.db %00001111
	.db %00001111
	.db %00001111
	.db %00001111
	.db %00001111
	.db %00001111
	.db %00001111
	.db %00001111

	.db %11110000
	.db %11110000
	.db %11110000
	.db %11110000
	.db %11110000
	.db %11110000
	.db %11110000
	.db %11110000
	
sol4:
	.db %11110000
	.db %11110000
	.db %11110000
	.db %11110000
	.db %11110000
	.db %11110000
	.db %11110000
	.db %11110000
	
	.db %00001111
	.db %00001111
	.db %00001111
	.db %00001111
	.db %00001111
	.db %00001111
	.db %00001111
	.db %00001111
	
;;;;; La prochaine section n'est pas dans la cartouche, elle est en RAM du NES ;;;;;;

	.zp	; Zero page bank (memoire rapide $0000 à $00FF).
	.org $0000  
		; Définir les variables ici
var1:	.ds 1	; Puisque la RAM du nes n'est pas dans la cartouche, l'initialisation n'est pas prise en compte (ne vous attendez pas à avoir 0 dans cette mémoire par défaut).
frame:	.ds 2
luved:  .ds 3