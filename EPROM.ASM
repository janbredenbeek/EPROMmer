* EPROMmer - QL EPROM programmer
* Start of work: 9 February 1988
* Release 1.00: April 1988
* Copyright (C) 1988 by Jan Bredenbeek. Licenced under GPL v3 Licence (2018)
* Assemble and link using the GST/Quanta Macro Assembler and Linker
* (see http://www.dilwyn.me.uk/asm/index.html)

version  SETSTR   1.00
incl_dev SETSTR   FLP1_

         INCLUDE  [incl_dev]MACRO_LIB        Macro Library
         INCLUDE  [incl_dev]QDOS_IN_MAC      QDOS Definitions

* Macro for printing underlined text         
         
UNDER    MACRO A
[.LAB]   LEA      .S.[.L],A1
         BSR.[.EXT] UNDERLIN
         SECTION  MSG
.S.[.L]  STRING$  {[A]}
         SECTION  CODE
         ENDM

LF       EQU      $0A
ED_SIZE  EQU      18
EP_2764  EQU      0
EP_27128 EQU      1
EP_27256 EQU      2
EP_2725N EQU      3
EP_27512 EQU      4

IO_BASE  SETSTR   ROMSTART+$2000    ; Base of 8255 I/O registers

PA_8255  EQU      0                 ; 8255 I/O
PB_8255  EQU      1
PC_8255  EQU      2
CTL_8255 EQU      3
CTL_CE   EQU      $1000             ; Control register for CE/OE/Vpp

* Variable storage

         OFFSET   0

CONCHAN  DS.L     1
EDCHAN   DS.L     1
PROGBAS  DS.L     1
PROGEND  DS.L     1
PROGLEN  DS.L     1
ROMSIZE  DS.L     1
WINPOS   DS.W     1
ROMTYPE  DS.B     1
PC_MASK  DS.B     1
         DS.W     0
BUFFER   DS.B     80

* Start of ROM code

         SECTION  CODE

ROMSTART DC.L     $4AFB0001
         DC.W     PROCDEF-ROMSTART
         DC.W     INIT-ROMSTART
         STRING$  {'EPROMmer V1.00   1988 Jan Bredenbeek',LF}
PROCDEF  DC.W     1
         DC.W     EPROM-*
         DC.B     5,'EPROM'
         DC.W     0,0,0

* Initialisation code - executed at boot time         
         
INIT     LEA      [IO_BASE],A5
         MOVE.B   #%10010000,CTL_8255(A5)
         MOVE.B   #0,PB_8255(A5)
         MOVE.B   #%11000000,PC_8255(A5)
         MOVE.B   #%0011,CTL_CE(A5)
         RTS

* BASIC command - just creates and executes the real job         

EPROM    MOVEQ    #-1,D1
         MOVEQ    #18,D2
         MOVE.L   #512,D3
         SUBA.L   A1,A1
         QDOS     MT.CJOB
         TST.L    D0
         BNE.S    EPROM_RT
         MOVE.W   #$4EF9,(A0)+
         LEA      START,A1
         MOVE.L   A1,(A0)+
         MOVE.L   #$4AFB0008,(A0)+
         MOVE.L   #'EPRO',(A0)+
         MOVE.L   #'Mmer',(A0)
         MOVEQ    #32,D2
         MOVEQ    #-1,D3
         QDOS     MT.ACTIV
EPROM_RT RTS

GUARDIAN STRING$  {'CON_448X194A32X19'}
GUARDPAR DC.B     4+4*8+3*64,2,0,7
CONNAME  STRING$  {'CON_400X180A56X26'}
CON_PAR  DC.B     0,0,0,7

* Start of job

START    ADDA.L   A4,A6
         LEA      [IO_BASE],A5
         MOVE.B   #%10010000,CTL_8255(A5)
         MOVE.B   #0,PB_8255(A5)
         MOVEQ    #%11000000,D0
         MOVE.B   D0,PC_MASK(A6)
         MOVE.B   D0,PC_8255(A5)
         MOVE.B   #%00000011,CTL_CE(A5)
         MOVEQ    #-1,D1
         MOVEQ    #-1,D2
         QDOS     MT.DMODE
         TST.B    D1
         IF NE THEN
            MOVEQ    #0,D1
            MOVEQ    #-1,D2
            QDOS     MT.DMODE
         ENDIF
         LEA      GUARDIAN,A0
         LEA      GUARDPAR,A1
         MOVE.W   UT_WINDW,A2
         JSR      (A2)
         MOVE.L   A0,EDCHAN(A6)
         LEA      CONNAME,A0
         LEA      CON_PAR,A1
         MOVE.W   UT_WINDW,A2
         JSR      (A2)
         MOVE.L   A0,CONCHAN(A6)
         MOVEQ    #3,D1
         MOVEQ    #1,D2
         MOVEQ    #-1,D3
         QDOS     SD.SETSZ
         PRINT    {'       QL EPROMmer',LF,LF}
         MOVEQ    #1,D1
         MOVEQ    #0,D2
         QDOS     SD.SETSZ
         MOVEQ    #19,D1
         MOVEQ    #3,D2
         QDOS     SD.POS
         PRINT    {'Version [version]',LF}
         PRINT    {'        Copyright  1988 by Jan Bredenbeek',LF}
         PRINT    {'                Hilversum, Holland',LF,LF,LF,LF}
         PRINT    {'FIRST set Vcc switch to '}
         UNDER.S  {'5V',LF,LF}
         PRINT    {'You may then insert an EPROM into the socket',LF}
         PRINT    {'(in the correct position, please!)',LF,LF}
         PRINT    {'Press any key to continue '}
         MOVE.B   #EP_2764,ROMTYPE(A6)
         MOVE.L   #$1FFF,ROMSIZE(A6)
         CLR.L    PROGBAS(A6)
         BRA      MAIN_KEY

UNDERLIN MOVE.L   A1,-(A7)
         MOVEQ    #1,D1
         QDOS     SD.SETUL
         MOVE.L   (A7)+,A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         MOVEQ    #0,D1
         QDOS     SD.SETUL
         RTS

GETMENU  MOVE.W   (A1)+,D5
         MOVE.L   A1,A3
         MOVE.L   CONCHAN(A6),A0
         MOVEQ    #-1,D3
         MOVE.W   D5,D4
GM_DISPL MOVE.W   (A1)+,D2
         MOVE.L   A1,-(A7)
         QDOS     IO.SSTRG
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         MOVE.L   (A7)+,A1
         ADDQ.W   #1,D2
         BCLR     #0,D2
         ADDA.W   D2,A1
         SUBQ.W   #1,D4
         BNE      GM_DISPL
         SUBQ.W   #8,A7
         MOVE.L   A7,A1
         QDOS     SD.CHENQ
         MOVE.W   2(A7),D2
         ADDQ.W   #8,A7
         SUBQ.W   #2,D2
         MOVEQ    #0,D1
         QDOS     SD.POS
         PRINT    {'Press digit or use cursor keys to select item',LF}
         PRINT    {'Press <SPACE> or <ENTER> to run selected item'}
         MOVEQ    #1,D4
GTCHOICE MOVE.W   D4,D1
         BSR.S    PR_ITEM1
GM_KEY   QDOS     IO.FBYTE
         CMPI.B   #' ',D1
         BEQ.S    GM_END
         CMPI.B   #LF,D1
         BEQ.S    GM_END
         CMPI.B   #$D0,D1
         BEQ.S    GM_UP
         CMPI.B   #$D8,D1
         BEQ.S    GM_DOWN
         SUBI.B   #'0',D1
         BLS      GM_KEY
         CMP.B    D5,D1
         BHI      GM_KEY
         BRA.S    GM_NEW
GM_UP    MOVE.W   D4,D1
         SUBQ.W   #1,D1
         BGT.S    GM_NEW
         MOVE.W   D5,D1
         BRA.S    GM_NEW
GM_DOWN  MOVE.W   D4,D1
         ADDQ.W   #1,D1
         CMP.W    D5,D1
         BLS.S    GM_NEW
         MOVEQ    #1,D1
GM_NEW   EXG      D1,D4
         BSR.S    PR_ITEM2
         BRA      GTCHOICE
GM_END   MOVE.W   D4,D1
         SUBQ.W   #1,D1
         RTS

PR_ITEM1 MOVE.W   D1,-(A7)
         MOVEQ    #4,D1
         QDOS     SD.SETST
         MOVEQ    #0,D1
         QDOS     SD.SETIN
         MOVE.W   (A7)+,D1
PR_ITEM2 MOVE.W   D1,-(A7)
         ADD.W    D1,D1
         MOVE.W   D1,D2
         MOVEQ    #0,D1
         QDOS     SD.POS
         MOVE.W   (A7)+,D1
         MOVE.L   A3,A1
PR_IT_LP SUBQ.W   #1,D1
         BLE.S    PR_ITEM3
         MOVEQ    #3,D0
         ADD.W    (A1),D0
         BCLR     #0,D0
         ADDA.W   D0,A1
         BRA      PR_IT_LP
PR_ITEM3 MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         MOVEQ    #0,D1
         QDOS     SD.SETST
         MOVEQ    #7,D1
         QDOS     SD.SETIN
         RTS

YESNO    MOVE.L   CONCHAN(A6),A0
         PRINT    {'? (Y/N) '}
         MOVEQ    #-1,D3
         QDOS     SD.CURE
YESNO_1  QDOS     IO.FBYTE
         MOVEQ    #$DF,D2
         AND.B    D1,D2
         IF D1 GE.B #$20 THEN
            QDOS     IO.SBYTE
         ENDIF
         IF D2 NE.B #'Y' AND D2 NE.B #'N' THEN
            QDOS     SD.PCOL
            BRA      YESNO_1
         ENDIF
         QDOS     SD.CURS
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         CMPI.B   #'Y',D2
         RTS

BEEP     MOVEM.L  D0-D1/D5/D7/A3,-(A7)
         LEA      BEEP_PAR,A3
         QDOS     MT.IPCOM
         MOVEM.L  (A7)+,D0-D1/D5/D7/A3
         RTS
BEEP_PAR DC.B     $0A,8,$55,$55,$AA,$AA,5,5,0,0,144,13,0,0,1

INERROR  BSR      BEEP
         MOVE.W   WINPOS(A6),D1
         QDOS     SD.TAB
         QDOS     SD.CLRRT
         RTS

GETLINE  MOVE.L   CONCHAN(A6),A0
         MOVEQ    #-1,D3
         SUBQ.W   #8,A7
         MOVE.L   A7,A1
         QDOS     SD.CHENQ
         MOVE.W   4(A7),WINPOS(A6)
         ADDQ.W   #8,A7
GL_AGAIN LEA      BUFFER+2(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         IF NE THEN
            BSR      INERROR
            BRA      GL_AGAIN
         ENDIF
         SUBA.W   D1,A1
         SUBQ.W   #1,D1
         MOVE.W   D1,-(A1)
         RTS

OP_FILE  MOVE.W   D3,-(A7)
OP_AGAIN LEA      BUFFER(A6),A0
         MOVE.W   (A7),D3
         MOVEQ    #-1,D1
         QDOS     IO.OPEN
         TST.L    D0
         BEQ.S    OP_END
         CMPI.L   #ERR.EX,D0
         BNE.S    OP_ERROR
         MOVE.L   CONCHAN(A6),A0
         LEA      BUFFER(A6),A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         PRINT    {' exists, overwrite'}
         BSR      YESNO
         BNE.S    OP_EXIST
         LEA      BUFFER(A6),A0
         MOVEQ    #-1,D1
         QDOS     IO.DELET
         BRA      OP_AGAIN
OP_EXIST MOVEQ    #1,D0
OP_ERROR MOVE.L   CONCHAN(A6),A0
         MOVE.W   UT_ERR,A2
         JSR      (A2)
OP_END   MOVE.W   (A7)+,D3
         TST.L    D0
         RTS

GETADDR  MOVEQ    #9,D2
         BSR      GETLINE
         BEQ.S    GA_NC
         ADDQ.W   #2,A1
GETADDR1 MOVEQ    #0,D0
         MOVEQ    #0,D1
         CMPI.B   #'&',(A1)
         BEQ.S    GET_DEC
HEX_LOOP MOVE.B   (A1)+,D0
         CMPI.B   #LF,D0
         BEQ.S    HEX_END
         IF D0 GE.B #$60 THEN
            SUBI.B   #$20,D0
         ENDIF
         SUBI.B   #'0',D0
         CMPI.B   #9,D0
         BLS.S    HEX_1
         CMPI.B   #'A'-'0',D0
         BLO.S    HEX_ERR
         CMPI.B   #'F'-'0',D0
         BHI.S    HEX_ERR
         SUBQ.B   #7,D0
HEX_1    LSL.L    #4,D1
         ADD.L    D0,D1
         BRA      HEX_LOOP
GET_DEC  ADDQ.W   #1,A1
DEC_LOOP MOVE.B   (A1)+,D0
         CMPI.B   #LF,D0
         BEQ.S    HEX_END
         SUBI.B   #'0',D0
         CMPI.B   #9,D0
         BHI.S    HEX_ERR
         MOVE.L   D1,D2
         LSL.L    #2,D2
         ADD.L    D2,D1
         ADD.L    D1,D1
         ADD.L    D0,D1
         BRA      DEC_LOOP
HEX_ERR  BSR      INERROR
         BRA      GETADDR
HEX_END  RTS
GA_NC    MOVEQ    #0,D1
         MOVEQ    #ERR.NC,D0
         RTS

ITOD.L   MOVEQ    #0,D2
ITODL_1  MOVEM.L  D0-D1,-(A7)
         CMPI.L   #9,D1
         BLS.S    ITODL_S
         MOVEQ    #0,D0
         SWAP     D1
         MOVE.W   D1,D0
         DIVU     #10,D0
         SWAP     D0
         MOVE.W   D0,D1
         SWAP     D1
         DIVU     #10,D1
         MOVE.W   D1,D0
         SWAP     D1
         EXG      D0,D1
         BSR      ITODL_1
         MOVE.B   D0,D1
ITODL_S  ADDI.B   #'0',D1
         MOVE.B   D1,(A1)+
         ADDQ.W   #1,D2
         MOVEM.L  (A7)+,D0-D1
         RTS

ITOH.L   MOVEQ    #0,D2
ITOHL_1  MOVEM.L  D0-D1,-(A7)
         MOVEQ    #$0F,D0
         CMP.L    D0,D1
         BLS.S    ITOHL_S
         AND.B    D1,D0
         LSR.L    #4,D1
         BSR      ITOHL_1
         MOVE.B   D0,D1
ITOHL_S  ADDI.B   #'0',D1
         CMPI.B   #'9',D1
         BLS.S    ITOHL_S1
         ADDQ.B   #7,D1
ITOHL_S1 MOVE.B   D1,(A1)+
         ADDQ.W   #1,D2
         MOVEM.L  (A7)+,D0-D1
         RTS

ITOH.B   MOVEQ    #2,D0
         BRA.S    ITOH_1
ITOH.W   MOVEQ    #4,D0
ITOH_1   ADDA.W   D0,A1
         MOVEM.L  D1-D2/A1,-(A7)
ITOH_LP  MOVEQ    #$0F,D2
         AND.B    D1,D2
         ADDI.B   #'0',D2
         CMPI.B   #'9',D2
         BLS.S    ITOH_2
         ADDQ.B   #7,D2
ITOH_2   MOVE.B   D2,-(A1)
         LSR.W    #4,D1
         SUBQ.W   #1,D0
         BNE      ITOH_LP
         MOVEM.L  (A7)+,D1-D2/A1
         RTS

GO_SUB   BSR      GETMENU
         MOVE.L   D1,-(A7)
         QDOS     SD.CLEAR
         MOVEM.L  (A7)+,D1/A1
         ADD.W    D1,D1
         ADDA.W   D1,A1
         ADDA.W   (A1),A1
         JMP      (A1)

MAIN_RET MOVE.L   CONCHAN(A6),A0
         MOVEQ    #-1,D3
         SUBQ.W   #8,A7
         MOVE.L   A7,A1
         QDOS     SD.CHENQ
         MOVE.W   2(A7),D2
         ADDQ.W   #8,A7
         SUBQ.W   #2,D2
         MOVEQ    #0,D1
         QDOS     SD.POS
         QDOS     SD.CLRLN
         QDOS     SD.NROW
         QDOS     SD.CLRLN
         PRINT    {'Press any key to return to main menu '}
MAIN_KEY QDOS     SD.CURE
         QDOS     IO.FBYTE
         QDOS     SD.CURS
MAIN_CLR QDOS     SD.CLEAR

MAINMENU MOVE.L   CONCHAN(A6),A0
         UNDER    {'MAIN MENU',LF,LF}
         LEA      MAIN_MN,A1
         BSR      GO_SUB
         DC.W     SELROM-*
         DC.W     LDFILE-*
         DC.W     LDEPROM-*
         DC.W     EDITOR-*
         DC.W     SAVPROG-*
         DC.W     PROGRAM-*
         DC.W     QUIT-*

MAIN_MN  DC.W     7
         STRING$  {' 1. Select EPROM type '}
         STRING$  {' 2. Load program from file '}
         STRING$  {' 3. Load program from EPROM '}
         STRING$  {' 4. Hex/ASCII Program Editor '}
         STRING$  {' 5. Save program to file '}
         STRING$  {' 6. Program EPROM '}
         STRING$  {' 7. Quit EPROMmer '}

QUIT     MOVEQ    #-1,D1
         MOVEQ    #0,D3
         QDOS     MT.FRJOB

SELROM   UNDER    {'SELECT EPROM TYPE',LF,LF}
         LEA      SELROM_M,A1
         BSR      GETMENU
         MOVE.B   D1,ROMTYPE(A6)
         MOVE.B   PCMASKTB(PC,D1.W),D0
         MOVE.B   D0,PC_MASK(A6)
         MOVE.B   D0,PC_8255(A5)
         ADD.W    D1,D1
         MOVEQ    #0,D0
         MOVE.W   ROMSIZTB(PC,D1.W),D0
         MOVE.L   D0,ROMSIZE(A6)
         BRA      MAIN_RET
PCMASKTB DC.B     $C0,$C0,$80,$80,0
ROMSIZTB DC.W     $1FFF,$3FFF,$7FFF,$7FFF,$FFFF

SELROM_M DC.W     5
         STRING$  {' 1. 2764 (8K byte) '}
         STRING$  {' 2. 27128 (16K byte) '}
         STRING$  {' 3. 27256 (32K byte) '}
         STRING$  {' 4. 27256 NEC '}
         STRING$  {' 5. 27512 (64K byte) '}

LDFILE   UNDER    {'LOAD PROGRAM FROM FILE',LF,LF}
LDF_AGN  MOVE.L   CONCHAN(A6),A0
         PRINT    {'File to load from: '}
         MOVEQ    #30,D2
         BSR      GETLINE
         BEQ      MAIN_RET
         MOVEQ    #1,D3
         BSR      OP_FILE
         BNE      LDF_AGN
         MOVE.L   A0,A4
         MOVEQ    #-1,D3
         LEA      BUFFER(A6),A1
         MOVEQ    #4,D2
         QDOS     FS.HEADR
         TST.L    D0
         BNE.S    LD_FAIL
         MOVE.L   PROGBAS(A6),D0
         IF NE THEN
            MOVE.L   D0,A0
            QDOS     MT.RECHP
            CLR.L    PROGBAS(A6)
         ENDIF
         MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'This file is '}
         LEA      BUFFER(A6),A1
         MOVE.L   (A1)+,D1
         BSR      ITOD.L
         SUBA.W   D2,A1
         QDOS     IO.SSTRG
         PRINT    {' ($'}
         LEA      BUFFER(A6),A1
         MOVE.L   (A1)+,D1
         BSR      ITOH.L
         SUBA.W   D2,A1
         QDOS     IO.SSTRG
         PRINT    {') bytes long',LF,'Loading...',LF,LF}
         MOVE.L   BUFFER(A6),D1
         MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         BNE.S    LD_FAIL
         MOVE.L   A0,A3
         MOVE.L   BUFFER(A6),D2
         MOVE.L   A3,A1
         MOVE.L   A4,A0
         MOVEQ    #-1,D3
         QDOS     FS.LOAD
         MOVE.L   D0,D4
         BEQ.S    LD_OK
         MOVE.L   A3,A0
         QDOS     MT.RECHP
         MOVE.L   D4,D0
LD_FAIL  MOVE.L   D0,-(A7)
         MOVE.L   A4,A0
         QDOS     IO.CLOSE
         MOVE.L   (A7)+,D0
LD_FAIL2 MOVE.L   D0,-(A7)
         BSR      BEEP
         MOVE.L   CONCHAN(A6),A0
         PRINT    {'*** Error: '}
         MOVE.L   (A7)+,D0
         MOVE.W   UT_ERR,A2
         JSR      (A2)
         BRA      MAIN_RET
LD_OK    MOVE.L   A3,PROGBAS(A6)
         MOVE.L   D2,PROGLEN(A6)
         ADDI.L   #15,D2
         ANDI.B   #$F0,D2
         ADDA.L   D2,A3
         MOVE.L   A3,PROGEND(A6)
         MOVE.L   A4,A0
         QDOS     IO.CLOSE
         BRA      MAIN_RET

SAVPROG  BSR.S    CHKPROG
         UNDER    {'SAVE PROGRAM TO FILE',LF,LF}
SP_AGAIN MOVE.L   CONCHAN(A6),A0
         PRINT    {'File to save to: '}
         MOVEQ    #30,D2
         BSR      GETLINE
         BEQ      MAIN_RET
         MOVEQ    #2,D3
         BSR      OP_FILE
         BNE      SP_AGAIN
         MOVE.L   A0,A4
         MOVE.L   CONCHAN(A6),A0
         PRINT    {'Saving...',LF}
         MOVE.L   A4,A0
         MOVE.L   PROGLEN(A6),D2
         MOVEQ    #-1,D3
         MOVE.L   PROGBAS(A6),A1
         QDOS     FS.SAVE
         TST.L    D0
         BNE      LD_FAIL
         QDOS     IO.CLOSE
         BRA      MAIN_RET

CHKPROG  TST.L    PROGBAS(A6)
         BNE.S    CHKPROG1
         PRINT    {'No program present'}
         ADDQ.W   #4,A7
         BRA      MAIN_RET
CHKPROG1 RTS

EDITOR   BSR      CHKPROG
         BRA.S    ED_NOEMP
ED_ESC   ADDQ.W   #4,A7
         QDOS     SD.CLEAR
ED_NOEMP MOVE.L   CONCHAN(A6),A0
         QDOS     SD.CLEAR
         UNDER    {'HEX/ASCII PROGRAM EDITOR',LF,LF}
         PRINT    {'Location to edit from (<ENTER> to end): '}
         BSR      GETADDR
         BNE      MAIN_CLR
         MOVE.L   PROGBAS(A6),A4
         MOVEQ    #$0F,D4
         AND.B    D1,D4       HOR. POSITION
         ANDI.B   #$F0,D1
         ADDA.L   D1,A4
         CMPA.L   PROGEND(A6),A4
         BLO.S    ED_CLR
         MOVE.L   PROGEND(A6),A4
         SUBA.W   #16,A4
ED_CLR   MOVE.L   EDCHAN(A6),A0
         MOVEQ    #-1,D3
         QDOS     SD.CLEAR
         MOVEQ    #2,D1
         QDOS     SD.SETST
         MOVEQ    #2,D1
         QDOS     SD.SETPA
         QDOS     SD.CLRLN
         MOVEQ    #6*6+3,D1
         MOVEQ    #0,D2
         QDOS     SD.PIXP
         PRINT    {'0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F'}
         MOVEQ    #55,D1
         QDOS     SD.TAB
         PRINT    {'0123456789ABCDEF'}
         MOVEQ    #0,D1
         QDOS     SD.SETST
         MOVEQ    #0,D1
         QDOS     SD.SETPA
         BSR      ED_DSPAG
         MOVEQ    #0,D5       VER. POSITION
         MOVEQ    #0,D6       UPPER (0) OR LOWER (1) NIBBLE
         MOVEQ    #0,D7       HEX (0) OR ASCII (1) MODE
ED_LOOP  TST.B    D7
         IF EQ THEN
            MOVEQ    #3,D1
            MULU     D4,D1
            ADDQ.W   #6,D1
            ADD.W    D6,D1
         ELSE
            MOVEQ    #55,D1
            ADD.W    D4,D1
         ENDIF
         MOVEQ    #1,D2
         ADD.W    D5,D2
         QDOS     SD.POS
         QDOS     SD.CURE
         QDOS     IO.FBYTE
         MOVE.B   D1,D2
         QDOS     SD.CURS
         MOVE.B   D2,D1
         LEA      ED_TBL-2,A1
ED_CTRLP ADDQ.W   #2,A1
         MOVE.W   (A1)+,D0
         BEQ.S    ED_CHAR
         CMP.B    D1,D0
         BNE      ED_CTRLP
         ADDA.W   (A1),A1
         JSR      (A1)
         BRA      ED_LOOP
ED_CHAR  MOVE.W   D5,D2
         LSL.W    #4,D2
         LEA      (A4,D2.W),A3
         ADDA.W   D4,A3
         TST.B    D7
         BNE.S    ED_NOHEX
         IF D1 GE.B #$60 THEN
            SUBI.B   #$20,D1
         ENDIF
         CMPI.B   #'0',D1
         BLO      ED_LOOP
         CMPI.B   #'9',D1
         BLS.S    ED_HEX
         CMPI.B   #'A',D1
         BLO      ED_LOOP
         CMPI.B   #'F',D1
         BHI      ED_LOOP
ED_HEX   LEA      BUFFER(A6),A1
         MOVE.B   D1,-(A7)
         MOVE.B   (A3),D1
         BSR      ITOH.B
         MOVE.B   #LF,(A1)
         SUBQ.W   #2,A1
         MOVE.B   (A7)+,(A1,D6.W)
         BSR      GETADDR1
         BRA.S    ED_ENTER
ED_NOHEX CMPI.B   #LF,D1
         BEQ.S    ED_ENTER
         CMPI.B   #$20,D1
         BLO      ED_LOOP
         CMPI.B   #$C0,D1
         BHS      ED_LOOP
ED_ENTER MOVE.B   D1,(A3)
         LEA      BUFFER(A6),A1
         BSR      ITOH.B
         MOVEQ    #3,D1
         MULU     D4,D1
         ADDQ.W   #6,D1
         MOVEQ    #1,D2
         ADD.W    D5,D2
         QDOS     SD.POS
         LEA      BUFFER(A6),A1
         MOVEQ    #2,D2
         QDOS     IO.SSTRG
         MOVEQ    #55,D1
         ADD.W    D4,D1
         QDOS     SD.TAB
         MOVE.B   (A3),D1
         CMPI.B   #$20,D1
         BLO.S    DSPBT_PT
         CMPI.B   #$C0,D1
         BLO.S    DSPBT_1
DSPBT_PT MOVEQ    #'.',D1
DSPBT_1  QDOS     IO.SBYTE
         BSR.S    ED_RIGHT
         BRA      ED_LOOP

ED_TBL   DC.W     9
         DC.W     ED_TAB-*
         DC.W     $1B
         DC.W     ED_ESC-*
         DC.W     $C0
         DC.W     ED_LEFT-*
         DC.W     $C1
         DC.W     ED_ALEFT-*
         DC.W     $C4
         DC.W     ED_SLEFT-*
         DC.W     $C8
         DC.W     ED_RIGHT-*
         DC.W     $C9
         DC.W     ED_ARGHT-*
         DC.W     $CC
         DC.W     ED_SRGHT-*
         DC.W     $D0
         DC.W     ED_UP-*
         DC.W     $D1
         DC.W     ED_AUP-*
         DC.W     $D4
         DC.W     ED_SUP-*
         DC.W     $D8
         DC.W     ED_DOWN-*
         DC.W     $D9
         DC.W     ED_ADOWN-*
         DC.W     $DC
         DC.W     ED_SDOWN-*
         DC.W     0

ED_TAB   MOVEQ    #0,D6
         BCHG     D6,D7
         RTS

ED_LEFT  TST.B    D7
         BNE.S    ED_L_1
         BCHG     #0,D6
         BNE.S    ED_L_RTS
         BRA.S    ED_L_1
ED_SLEFT MOVEQ    #0,D6
ED_L_1   SUBQ.W   #1,D4
         BGE.S    ED_L_RTS
         MOVEQ    #15,D4
         BSR.S    ED_UP
         BEQ.S    ED_L_RTS
         MOVEQ    #0,D4
         MOVEQ    #0,D6
ED_L_RTS RTS

ED_RIGHT TST.B    D7
         BNE.S    ED_SRGHT
         BCHG     #0,D6
         BEQ.S    ED_R_RTS
ED_SRGHT MOVEQ    #0,D6
         ADDQ.W   #1,D4
         CMPI.W   #15,D4
         BLE.S    ED_R_RTS
         MOVEQ    #0,D4
         BSR.S    ED_DOWN
         BEQ.S    ED_R_RTS
         MOVEQ    #15,D4
         MOVEQ    #1,D6
ED_R_RTS RTS

ED_ALEFT MOVEQ    #0,D4
         BRA.S    ED_ALT
ED_ARGHT MOVEQ    #15,D4
ED_ALT   MOVEQ    #0,D6
         RTS

ED_UP    SUBQ.W   #1,D5
         BGE.S    ED_U_OK
         MOVEQ    #0,D5
ED_AUP   CMPA.L   PROGBAS(A6),A4
         BLS.S    ED_U_NC
         SUBA.W   #16,A4
         MOVEQ    #0,D1
         MOVEQ    #0,D2
         QDOS     SD.POS
         MOVEQ    #10,D1
         QDOS     SD.SCRBT
         MOVEQ    #0,D1
         MOVEQ    #1,D2
         QDOS     SD.POS
         MOVE.L   A4,A3
         BSR      ED_DSPLN
ED_U_OK  MOVEQ    #0,D0
         RTS
ED_U_NC  MOVEQ    #-1,D0
         RTS

ED_DOWN  CMPI.W   #ED_SIZE-1,D5
         BEQ.S    ED_ADOWN
         ADDQ.W   #1,D5
         MOVE.W   D5,D2
         LSL.W    #4,D2
         LEA      (A4,D2.W),A3
         CMPA.L   PROGEND(A6),A3
         BLO      ED_U_OK
         SUBQ.W   #1,D5
         BRA      ED_U_NC
ED_ADOWN LEA      ED_SIZE*16(A4),A3
         CMPA.L   PROGEND(A6),A3
         BHS      ED_U_NC
         ADDA.W   #16,A4
         MOVEQ    #0,D1
         MOVEQ    #0,D2
         QDOS     SD.POS
         MOVEQ    #-10,D1
         QDOS     SD.SCRBT
         MOVEQ    #0,D1
         MOVEQ    #ED_SIZE,D2
         QDOS     SD.POS
         BSR.S    ED_DSPLN
         BRA      ED_U_OK

ED_SUP   SUBA.W   #(ED_SIZE-1)*16,A4
         CMPA.L   PROGBAS(A6),A4
         BHS.S    ED_DSPAG
         MOVE.L   PROGBAS(A6),A4
         BRA.S    ED_DSPAG

ED_SDOWN ADDA.W   #(ED_SIZE-1)*16,A4
         LEA      ED_SIZE*16(A4),A3
         CMPA.L   PROGEND(A6),A3
         BLS.S    ED_DSPAG
         MOVE.L   PROGEND(A6),A4
         SUBA.W   #ED_SIZE*16,A4
         CMPA.L   PROGBAS(A6),A4
         BHS.S    ED_DSPAG
         MOVE.L   PROGBAS(A6),A4

ED_DSPAG MOVE.L   A4,A3
         MOVEQ    #0,D1
         MOVEQ    #1,D2
         QDOS     SD.POS
         MOVEQ    #ED_SIZE-1,D2
DSPAG_LP QDOS     SD.DONL
         QDOS     SD.CLRLN
         BSR.S    ED_DSPLN
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         CMPA.L   PROGEND(A6),A3
         DBHS     D2,DSPAG_LP
         RTS

ED_DSPLN MOVE.L   D2,-(A7)
         LEA      BUFFER(A6),A1
         MOVE.L   A3,D1
         SUB.L    PROGBAS(A6),D1
         BSR      ITOH.W
         MOVE.W   #': ',(A1)+
         MOVEQ    #15,D2
DSPLN_HX MOVE.B   (A3)+,D1
         BSR      ITOH.B
         MOVE.B   #' ',(A1)+
         DBF      D2,DSPLN_HX
         MOVE.B   #' ',(A1)+
         MOVEQ    #15,D2
         SUBA.W   #16,A3
DSPLN_AS MOVE.B   (A3)+,D1
         CMPI.B   #$20,D1
         BLO.S    DSPLN_PT
         CMPI.B   #$C0,D1
         BLO.S    DSPLN_1
DSPLN_PT MOVEQ    #'.',D1
DSPLN_1  MOVE.B   D1,(A1)+
         DBF      D2,DSPLN_AS
         MOVEQ    #71,D2
         SUBA.W   D2,A1
         QDOS     IO.SSTRG
         MOVE.L   (A7)+,D2
         RTS

LDEPROM  UNDER    {'LOAD PROGRAM FROM EPROM',LF,LF}
LDE_AGN  PRINT    {'First location (<ENTER> = 0): '}
         BSR      GETADDR
         MOVE.L   D1,D4
         PRINT    {'Last location (<ENTER> = last from EPROM): '}
         BSR      GETADDR
         IF NE THEN
            MOVE.L   ROMSIZE(A6),D1
         ENDIF
         MOVE.L   D1,D5
         CMP.L    D4,D5
         BLO      LDE_AGN
         MOVE.L   PROGBAS(A6),D0
         IF NE THEN
            MOVE.L   D0,A0
            QDOS     MT.RECHP
            CLR.L    PROGBAS(A6)
         ENDIF
         MOVE.L   D5,D1
         SUB.L    D4,D1
         ADDQ.L   #1,D1
         MOVE.L   D1,PROGLEN(A6)
         MOVEQ    #15,D6
         ADD.L    D1,D6
         ANDI.B   #$F0,D6
         MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         BNE      LD_FAIL2
         MOVE.L   A0,PROGBAS(A6)
         ADD.L    A0,D6
         MOVE.L   D6,PROGEND(A6)
         MOVE.L   A0,A4
         MOVE.L   CONCHAN(A6),A0
         PRINT    {'Loading...',LF}
         MOVE.B   #%0010,CTL_CE(A5)
         MOVE.L   D4,D3
LDE_LP   BSR.S    GET_RBYT
         MOVE.B   D1,(A4)+
         ADDQ.L   #1,D3
         CMP.L    D5,D3
         BLS      LDE_LP
         MOVE.B   #%0011,CTL_CE(A5)
         BRA      MAIN_RET

GET_RBYT MOVE.B   D3,PB_8255(A5)
         MOVE.W   D3,D1
         LSR.W    #8,D1
         OR.B     PC_MASK(A6),D1
         MOVE.B   D1,PC_8255(A5)
         MOVE.B   #%0000,CTL_CE(A5)
         MOVE.B   PA_8255(A5),D1
         MOVE.B   #%0010,CTL_CE(A5)
         RTS

CHKEPROM PRINT    {'Checking EPROM contents...',LF}
         SF       D7
         MOVE.L   A4,A1
         MOVE.L   D4,D3
         MOVE.B   #%0010,CTL_CE(A5)
CHKEP_LP BSR      GET_RBYT
         NOT.B    D1
         IF NE THEN
            ST       D7
         ENDIF
         AND.B    (A1)+,D1
         BNE.S    CHKEP_ER
         ADDQ.L   #1,D3
         CMP.L    D5,D3
         BLS      CHKEP_LP
         MOVE.B   #%0011,CTL_CE(A5)
         TST.B    D7
         IF EQ THEN
            PRINT    {'EPROM clear over programming range',LF}
         ELSE
            PRINT    {'EPROM reprogrammable over programming range',LF}
         ENDIF
         MOVEQ    #0,D0
         RTS
CHKEP_ER MOVE.B   #%0011,CTL_CE(A5)
         PRINT    {'Cannot program EPROM - Erase first',LF}
         MOVEQ    #-1,D0
         RTS

SET_5V   MOVE.W   #'5V',-(A7)
         BRA.S    SET_VCC
SET_6V   MOVE.W   #'6V',-(A7)
SET_VCC  PRINT    {'Set Vcc switch to '}
         MOVE.W   #2,-(A7)
         MOVE.L   A7,A1
         BSR      UNDERLIN
         ADDQ.W   #4,A7
ASK_KEY  PRINT    {' and press any key '}
GETKEY   MOVEQ    #-1,D3
         QDOS     SD.CURE
         QDOS     IO.FBYTE
         QDOS     SD.CURS
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         RTS

PROGRAM  BSR      CHKPROG
         UNDER    {'PROGRAM EPROM',LF,LF}
PRG_AGN  PRINT    {'First program location (<ENTER> = start): '}
         BSR      GETADDR
         MOVE.L   D1,D4
GETLAST  PRINT    {'Last program location (<ENTER> = end): '}
         BSR      GETADDR
         IF NE THEN
            MOVEQ    #-1,D1
            ADD.L    PROGLEN(A6),D1
         ENDIF
         MOVE.L   D1,D5
         CMP.L    D4,D5
         BLS      PRG_AGN
         CMP.L    PROGLEN(A6),D5
         BLO.S    PRG_2
         PRINT    {'Too high',LF}
         BRA      GETLAST
PRG_2    MOVE.L   PROGBAS(A6),A4
         ADDA.L   D4,A4
         PRINT    {'Start location on EPROM (<ENTER> = first): '}
         BSR      GETADDR
         SUB.L    D4,D5
         MOVE.L   D1,D4
         ADD.L    D1,D5
         CMP.L    ROMSIZE(A6),D5
         BLS.S    PRG_3
         PRINT    {'Cannot program from this location',LF}
         BRA      PRG_AGN
PRINT_5V PRINT    {'Set Vcc swith back to '}
         UNDER    {'5V',LF}
         RTS
PRG_FAIL BSR      BEEP
         PRINT    {LF,'*** Verification Error - Programming failed',LF}
PRG_RET2 BSR      PRINT_5V
PRG_RET  MOVE.B   #%0011,CTL_CE(A5)
         PRINT    {LF,'Press any key to continue '}
         BSR      GETKEY
PRG_3    QDOS     SD.CLEAR
         UNDER    {'SELECT PROGRAMMING METHOD',LF,LF}
         MOVEM.L  D4/D5,-(A7)
         LEA      PRG_MENU,A1
         BSR      GETMENU
         MOVEM.L  (A7)+,D4/D5
         MOVE.B   D1,D6
         SUBQ.B   #2,D1
         BEQ      MAIN_CLR
         QDOS     SD.CLEAR
         TST.B    D6
         IF EQ THEN
            UNDER    {'STANDARD PROGRAMMING METHOD',LF,LF}
         ELSE
            UNDER    {'INTELLIGENT PROGRAMMING METHOD',LF,LF}
         ENDIF
         BSR      SET_5V
         BSR      CHKEPROM
         BNE      PRG_RET
         BSR      SET_6V
         BSR      CHKEPROM
         BNE      PRG_RET2
         TST.B    D6
         IF EQ THEN
            BSR      PRINT_5V
         ENDIF
         PRINT    {'Set Vpp switch to '}
         CMPI.B   #EP_27128,ROMTYPE(A6)
         IF LS THEN
            UNDER    {'21V'}
         ELSE
            UNDER    {'12.5V'}
         ENDIF
         BSR      ASK_KEY
         PRINT    {'Programming location $'}
         MOVE.W   #20833,D7
         TST.B    D6
         IF NE THEN
            MOVE.W   #416,D7
         ENDIF
         MOVE.L   A4,A1
         MOVE.L   D4,D3
         BSR      PRINTLOC
         BSR      PRG_IDLE
EACH_LOC TST.B    D3
         IF EQ THEN
            BSR      PRINTLOC
         ENDIF
         MOVE.B   D3,PB_8255(A5)
         MOVE.W   D3,D1
         LSR.W    #8,D1
         OR.B     PC_MASK(A6),D1
         MOVE.B   D1,PC_8255(A5)
         BSR      PRG_VRFY
         BEQ.S    NXTLOC
         BLT      PRG_FAIL
         MOVEQ    #1,D2
PRGPULSE BSR      PVER
         BEQ.S    PRGBOOST
         BLT      PRG_FAIL
         TST.B    D6
         BEQ      PRG_FAIL
         ADDQ.B   #1,D2
         CMPI.B   #15,D2
         BLS      PRGPULSE
         SUBQ.B   #1,D2
PRGBOOST TST.B    D6
         BEQ.S    NXTLOC
         LSL.W    #2,D2
         MULU     D2,D7
         BSR      PVER
         BNE      PRG_FAIL
         DIVU     D2,D7
NXTLOC   ADDQ.W   #1,A1
         ADDQ.L   #1,D3
         CMP.L    D5,D3
         BLS      EACH_LOC
         MOVE.B   #%0011,CTL_CE(A5)
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         TST.B    D6
         IF NE THEN
            BSR      SET_5V
         ENDIF
         MOVEQ    #0,D7
VRFY_ALL PRINT    {'Verifying data...',LF}
         MOVE.B   #%0010,CTL_CE(A5)
         MOVE.L   A4,A1
         MOVE.L   D4,D3
VRFY_LP  BSR      GET_RBYT
         CMP.B    (A1)+,D1
         BNE      PRG_FAIL
         ADDQ.L   #1,D3
         CMP.L    D5,D3
         BLS      VRFY_LP
         TAS      D7
         BNE.S    PRG_END
         BSR      SET_6V
         BRA      VRFY_ALL
PRG_END  PRINT    {'*** Programming finished',LF}
         BRA      PRG_RET2

PRG_MENU DC.W     3
         STRING$  {' 1. Standard Programming Method '}
         STRING$  {' 2. Intelligent Programming Method '}
         STRING$  {' 3. Exit to main menu '}

PVER     TRAP     #0
         ORI.W    #$0700,SR
         MOVE.W   D7,D0
         MOVEQ    #0,D1
         MOVE.B   ROMTYPE(A6),D1
         MOVE.B   PTABLE(PC,D1.W),D1
         LEA      PTABLE(PC,D1.W),A2
         MOVE.W   D3,D1
         LSR.W    #8,D1
         OR.B     PC_MASK(A6),D1
         JSR      (A2)
         BSR.S    PRG_IDLE
         MOVEQ    #24,D0
PV_WAIT  DBF      D0,PV_WAIT
         ANDI.W   #$D8FF,SR
PRG_VRFY MOVEQ    #0,D0
         MOVE.B   ROMTYPE(A6),D0
         MOVE.B   VTABLE(PC,D0.W),D0
         JSR      VTABLE(PC,D0.W)
         CMP.B    (A1),D1
         BEQ.S    VRFY_OK
         NOT.B    D1
         AND.B    (A1),D1
         BNE.S    DEV_FAIL
         MOVEQ    #1,D0
         RTS
VRFY_OK  MOVEQ    #0,D0
         RTS
DEV_FAIL MOVEQ    #-1,D0
         RTS
PRG_IDLE MOVEQ    #0,D0
         MOVE.B   ROMTYPE(A6),D0
         MOVE.B   ITABLE(PC,D0.W),D0
         JMP      ITABLE(PC,D0.W)

PTABLE   DC.B     P_2764-PTABLE
         DC.B     P_2764-PTABLE
         DC.B     P_27256-PTABLE
         DC.B     P_27256-PTABLE
         DC.B     P_27512-PTABLE

VTABLE   DC.B     V_2764-VTABLE
         DC.B     V_2764-VTABLE
         DC.B     V_27256-VTABLE
         DC.B     V_27256N-VTABLE
         DC.B     V_27512-VTABLE

ITABLE   DC.B     I_2764-ITABLE
         DC.B     I_2764-ITABLE
         DC.B     I_27256-ITABLE
         DC.B     I_27256N-ITABLE
         DC.B     I_27512-ITABLE

P_2764   MOVE.B   #%0111,CTL_CE(A5)
         MOVE.B   #%10000000,CTL_8255(A5)
         MOVE.B   D3,PB_8255(A5)
         MOVE.B   D1,PC_8255(A5)
         MOVE.B   (A1),PA_8255(A5)
         MOVE.B   #%0110,CTL_CE(A5)
         ANDI.B   #%10111111,D1
         MOVE.B   D1,PC_8255(A5)
P2764LP  DBF      D0,P2764LP
         ORI.B    #%01000000,D1
         MOVE.B   D1,PC_8255(A5)
         RTS
P_27256  MOVE.B   #%0111,CTL_CE(A5)
         MOVE.B   #%10000000,CTL_8255(A5)
         MOVE.B   D3,PB_8255(A5)
         MOVE.B   D1,PC_8255(A5)
         MOVE.B   (A1),PA_8255(A5)
         NOP
         NOP
         MOVE.B   #%0110,CTL_CE(A5)
P27256LP DBF      D0,P27256LP
         MOVE.B   #%0111,CTL_CE(A5)
         RTS
P_27512  MOVE.B   #%1011,CTL_CE(A5)
         MOVE.B   #%10000000,CTL_8255(A5)
         MOVE.B   D3,PB_8255(A5)
         MOVE.B   D1,PC_8255(A5)
         MOVE.B   (A1),PA_8255(A5)
         NOP
         NOP
         MOVE.B   #%1010,CTL_CE(A5)
P27512LP DBF      D0,P27512LP
         MOVE.B   #%1011,CTL_CE(A5)
         RTS

V_2764   MOVE.B   #%0100,CTL_CE(A5)
         MOVEQ    #%0110,D0
         BRA.S    V_ALL
V_27256  MOVE.B   #%0101,CTL_CE(A5)
         MOVEQ    #%0111,D0
         BRA.S    V_ALL
V_27256N MOVE.B   #%0100,CTL_CE(A5)
         MOVEQ    #%0101,D0
         BRA.S    V_ALL
V_27512  MOVE.B   #%0000,CTL_CE(A5)
         MOVEQ    #%0011,D0
V_ALL    MOVE.B   PA_8255(A5),D1
         MOVE.B   D0,CTL_CE(A5)
         RTS

I_2764   MOVEQ    #%0110,D0
         BRA.S    I_ALL
I_27256  MOVEQ    #%0111,D0
         BRA.S    I_ALL
I_27256N MOVEQ    #%0101,D0
         BRA.S    I_ALL
I_27512  MOVEQ    #%0011,D0
I_ALL    MOVEQ    #%0011,D1
         OR.B     D0,D1
         MOVE.B   D1,CTL_CE(A5)
         MOVE.B   #%10010000,CTL_8255(A5)
         MOVE.B   D3,PB_8255(A5)
         MOVE.W   D3,D1
         LSR.W    #8,D1
         OR.B     PC_MASK(A6),D1
         MOVE.B   D1,PC_8255(A5)
         MOVE.B   D0,CTL_CE(A5)
         RTS

PRINTLOC MOVEM.L  D3/A1,-(A7)
         SUBQ.W   #8,A7
         MOVE.L   CONCHAN(A6),A0
         MOVEQ    #-1,D3
         MOVE.L   A7,A1
         QDOS     SD.CHENQ
         LEA      BUFFER(A6),A1
         MOVE.L   8(A7),D1
         BSR      ITOH.L
         SUBA.W   D2,A1
         QDOS     IO.SSTRG
         MOVE.W   4(A7),D1
         QDOS     SD.TAB
         ADDQ.W   #8,A7
         MOVEM.L  (A7)+,D3/A1
         RTS

         END
