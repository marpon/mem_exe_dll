

#Macro Macro_IncCommunEx(label , file , sectionName)
    dim label##_data as UByte Ptr
    dim label##_size as ULong
    #If __FB_DEBUG__
        asm jmp .LT_END_OF_FILE_##label##_DEBUG_JMP
    #Else
        asm .section sectionName                 		' Switch to/Create the specified section
    #EndIf
    asm .LT_START_OF_FILE_##label##:             		' Assign a label to the beginning of the file
    asm __##label##__start = .                   		' Include the file
    asm .incbin ##file
    asm __##label##__len = . - __##label##__start		' Mark the end of the the file
    asm .LT_END_OF_FILE_##label##:
    'asm .LONG 0 										'Pad it with a NULL Long (harmless, yet useful for text files)
    #If __FB_DEBUG__
        asm .LT_END_OF_FILE_##label##_DEBUG_JMP:
    #Else
        asm .section .text                       		' Switch back to the .text (code) section
        asm .balign 16                           		'was asm .balign 16
    #EndIf
    asm .LT_SKIP_FILE_##label##:
    asm mov dword ptr [label##_data] , offset .LT_START_OF_FILE_##label
    asm mov dword ptr [label##_size] , offset __##label##__len
	label##_ptr = label##_data
	label##_len = label##_size
#EndMacro

#Macro Macro_IncFileEx(label , file , sectionName)
    #ifndef __INC__##label##__DEF__
        #define __INC__##label##__DEF__
        #If __FUNCTION__ = "__FB_MAINPROC__"
            dim shared label##_ptr as UByte Ptr
		    dim shared label##_len as ULong
            sub Sub_Inc_##label##()
                Macro_IncCommunEx( label , file , sectionName )
            end sub
            Sub_Inc_##label##()
        #else
	        dim label##_ptr as UByte Ptr
	        dim label##_len as ULong
            Macro_IncCommunEx( label , file , sectionName )
        #endif
    #else
        #error ===> error ##label## already defined
    #endif
#EndMacro



sub SubName()
    Macro_IncFileEx(EXE2 , "test32.exe" , .Data)
    print EXE2_len ,, EXE2_ptr
END SUB

Macro_IncFileEx(EXE , "test32.exe" , .Data)
print EXE_len ,, EXE_ptr

SubName()
SubName()
Macro_IncFileEx(EXE3 , "test32.exe" , .Data)
print EXE3_len ,, EXE3_ptr
sleep




