
type Include_type
	data_ptr   as UByte Ptr
	data_len   as ULong
END TYPE

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
    label##_type.data_ptr = label##_data
    label##_type.data_len = label##_size
#EndMacro

#Macro Macro_IncFileEx(label , file , sectionName)
    #ifndef __INC__##label##__DEF__
        #define __INC__##label##__DEF__
        #If __FUNCTION__ = "__FB_MAINPROC__"
            dim label##_type as Include_type
            sub Sub_Inc_##label##(byref label##_type as Include_type)
                Macro_IncCommunEx(label , file , sectionName)
            end sub
            Sub_Inc_##label##( label##_type)
        #else
            dim label##_type as Include_type
            Macro_IncCommunEx(label , file , sectionName)
        #endif
    #else
        #error ===> error ##label## already defined
    #endif
#EndMacro



sub SubName()
    Macro_IncFileEx(EXE2 , "test32.exe" , .Data)
    print EXE2_type.data_len ,, EXE2_type.data_ptr
END SUB

Macro_IncFileEx(EXE , "test32.exe" , .Data)
print EXE_type.data_len ,, EXE_type.data_ptr

SubName()
SubName()
Macro_IncFileEx(EXE3 , "test32.exe" , .Data)
print EXE3_type.data_len ,, EXE3_type.data_ptr
sleep

' -gen gcc -O 2


