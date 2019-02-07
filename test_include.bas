
type Include_type
	data_ptr as UByte Ptr
	data_len as ULong
END TYPE



#Macro IncFileEx(label, file, sectionName)
#ifndef __##label##__DEF__
 #define __##label##__DEF__
  #If __FUNCTION__ = "__FB_MAINPROC__"
	dim shared label##_type as Include_type
	sub SubName_##label##()
        dim label##_data as UByte Ptr
        dim label##_size as ULong
         #If __FB_DEBUG__
              asm jmp .LT_END_OF_FILE_##label##_DEBUG_JMP
         #Else
              ' Switch to/Create the specified section
			asm .section sectionName
         #EndIf
         ' Assign a label to the beginning of the file
         asm .LT_START_OF_FILE_##label##:
         asm __##label##__start = .
         ' Include the file
         asm .incbin ##file
         ' Mark the end of the the file
         asm __##label##__len = . - __##label##__start
         asm .LT_END_OF_FILE_##label##:
         ' Pad it with a NULL Long (harmless, yet useful for text files)   asm .LONG 0
        #If __FB_DEBUG__
             asm .LT_END_OF_FILE_##label##_DEBUG_JMP:
        #Else
             ' Switch back to the .text (code) section
             asm .section .text
             'was asm .balign 16
             asm .balign 16
        #EndIf
         asm .LT_SKIP_FILE_##label##:
         asm mov dword ptr [ label##_data], offset .LT_START_OF_FILE_##label
         asm mov dword ptr [ label##_size], offset __##label##__len

		 label##_type.data_ptr = label##_data
		 label##_type.data_len = label##_size
	end sub
	SubName_##label##()
  #else
		dim label##_type as Include_type
        dim label##_data as UByte Ptr
        dim label##_size as ULong
         #If __FB_DEBUG__
              asm jmp .LT_END_OF_FILE_##label##_DEBUG_JMP
         #Else
              ' Switch to/Create the specified section
			asm .section sectionName
         #EndIf
         ' Assign a label to the beginning of the file
         asm .LT_START_OF_FILE_##label##:
         asm __##label##__start = .
         ' Include the file
         asm .incbin ##file
         ' Mark the end of the the file
         asm __##label##__len = . - __##label##__start
         asm .LT_END_OF_FILE_##label##:
         ' Pad it with a NULL Long (harmless, yet useful for text files)   asm .LONG 0
        #If __FB_DEBUG__
             asm .LT_END_OF_FILE_##label##_DEBUG_JMP:
        #Else
             ' Switch back to the .text (code) section
             asm .section .text
             'was asm .balign 16
             asm .balign 16
        #EndIf
         asm .LT_SKIP_FILE_##label##:
         asm mov dword ptr [ label##_data], offset .LT_START_OF_FILE_##label
         asm mov dword ptr [ label##_size], offset __##label##__len

		 label##_type.data_ptr = label##_data
		 label##_type.data_len = label##_size
  #endif
#else
	#error ===> error ##label## already defined
#endif

#EndMacro

sub SubName()
	IncFileEx(EXE2, "test32.exe", .Data)
	print EXE2_type.data_len
END SUB

	IncFileEx(EXE, "test32.exe", .Data)
	print EXE_type.data_len

SubName()
SubName()
IncFileEx(EXE3, "test32.exe", .Data)
	print EXE3_type.data_len
sleep

' -gen gcc -O 2