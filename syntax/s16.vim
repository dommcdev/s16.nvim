if exists('b:current_syntax')
  finish
endif
syn case ignore
syn match s16Label "\<[a-z][a-z0-9_]*\>"
syn keyword s16Directive CODESEGMENT DATASEGMENT END EQU RW DW DS
syn keyword s16Instruction NOOP JMP JMPN JMPNN JMPZ JMPNZ JMPP JMPNP JMPT JMPF CALL RET SVC DEBUG
syn keyword s16Instruction ADDR SUBR INCR DECR ZEROR LSRR ASRR SLR CMPR CMPUR ANDR ORR XORR NOTR NEGR MULR DIVR MODR
syn keyword s16Instruction LDR LDAR STR COPYR PUSHR POPR SWAPR PUSHFB POPFB SETFB ADJSP
syn keyword s16Register FB R0 R1 R2 R3 R4 R5 R6 R7 R8 R9 R10 R11 R12 R13 R14 R15
syn keyword s16Boolean TRUE FALSE
syn match s16Number "[+-]\?\<\d\+\>"
syn match s16Number "[+-]\?\<0x[0-9a-f]\+\>"
syn match s16Operator "[#@*]"
syn match s16Delimiter "[,:]"
syn region s16String start=+"+ skip=+""+ end=+"+ oneline
syn match s16Character "'[^']'"
syn match s16Character "'\\\\''"
syn keyword s16Todo TODO FIXME NOTE XXX contained
syn match s16Comment ";.*$" contains=s16Todo,@Spell
hi def link s16Label Identifier
hi def link s16Directive PreProc
hi def link s16Instruction Statement
hi def link s16Register Type
hi def link s16Boolean Boolean
hi def link s16Number Number
hi def link s16Operator Operator
hi def link s16Delimiter Delimiter
hi def link s16String String
hi def link s16Character Character
hi def link s16Comment Comment
hi def link s16Todo Todo
let b:current_syntax = 's16'
