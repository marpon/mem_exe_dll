

#Include Once "windows.bi"
#include Once "crt/string.bi"

' compile with "PATH_TO_COMPILER" -x "libCalendrier_enc_lib.a" -v -lib "dll2lib_test_enc_32.bas" > "dll2lib_test_enc_32.log" 2>&1
' replace PATH_TO_COMPILER by your own compiler path  ex   c:\freebasic\fbc.exe

#ifdef __FB_64BIT__
	#error ======> error not allowed for 64bits compiler!
#endif

'	cmdline to CSED_FB editor, seen as comment into source code so no effect on other editors
_:[CSED_COMPIL_NAME]:   libCalendrier_enc_lib.a


#ifndef __MEM_DLL_HEADER
	#define __MEM_DLL_HEADER
	#ifdef __FB_64BIT__

		#INCLIB "MemDll_64"   				' C  lib64  > libMemDll_64.a
	#else
		#INCLIB "MemDll_32"   				' C  lib32  > libMemDll_32.a
	#endif


	EXTERN "C"

		'DLL from memory functions/subs
		'========================================================
		DECLARE FUNCTION DllMemLoad alias "C_DllMemLoad"(byval dllname as any ptr) as any ptr
		'attach the Dll in memory, returns handle ptr

		DECLARE FUNCTION DllMemGetProc alias "C_DllMemGetProc"(byval phandle as any ptr, byval exportname as zstring ptr) as any ptr
		'declare export Function/sub from dll

		DECLARE SUB      DllMemFree alias "C_DllMemFree"(byval phandle as any ptr)
		'detach the dll from memory

		'Helper functions/subs
		'========================================================
		DECLARE FUNCTION DllCheck_Bits alias "C_CheckBits"(byval dataU as any ptr , byval len1 as Long) as long
		'to check if exe/dll is 32 or 64  if 32 returns 32  , if 64 returns 64  , error returns 0

		DECLARE FUNCTION DllCompilBits alias "C_CompilBits"() as long
		'to check if compiled in  32 or 64  if 32 returns 32  , if 64 returns 64

		DECLARE FUNCTION Decrypt alias "Decrypt"(byval input as ubyte ptr, byval ilen as long ) as any ptr

	END EXTERN

#endif

'simplified version of incbin files but must be used inside sub or function
#IfnDef INCFILE_LIGHT_
 #Define INCFILEX_LIGHT_
 #Macro __MACRO__INCLIGHT__(label, file)
	#If __FUNCTION__ = "__FB_MAINPROC__"
		#error =====> error  INCBIN outside Sub/Function!
	#Else
		dim label as UByte Ptr
		dim label##_len as ULong

		#If file = ""
			#error =====> error  no given exe/dll_file!
		#Else
			#If __FB_DEBUG__
				asm jmp .LT_END_OF_FILE_##label##_DEBUG_JMP
			#Else
			   ' Create the specified section
				asm .section .Data
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
			asm mov dword ptr [label], offset .LT_START_OF_FILE_##label
			asm mov dword ptr [label##_len], offset __##label##__len
		#EndIf
	#EndIf
 #EndMacro

#EndIf


' uing a shared var here by simplicity
dim shared as any ptr g_h_dll_calendrier_ = NULL

' to incorpotate the dll into the created lib and get handle to the dll
sub init_calendrier()

	__MACRO__INCLIGHT__(DLL32, "Calendrier_dll.enc")

	dim as ubyte ptr p1 = allocate(DLL32_len)
	p1 = Decrypt(DLL32, DLL32_len)
	memcpy(DLL32, p1, DLL32_len)
	deallocate(p1)
	if dllcheck_bits(DLL32, DLL32_len) <> dllCompilBits() THEN
		messagebox 0, "Not valid " & dllCompilBits() & " Dll included ! " & chr(10,10) & "Closing now.", "Error", MB_OK + MB_ICONERROR
		error 150
		exit sub
	end if
	'print "Loading embedded dll  DLL32 " , "Calendrier.dll" : print
	g_h_dll_calendrier_ = DllMemLoad(DLL32)
	if g_h_dll_calendrier_ = NULL THEN
		messagebox 0, "Wrong Dll ", "Error", MB_OK + MB_ICONERROR
		error 150
	end if
End Sub

'to "detach" the dll it is optionnal because it is done when prog close,
'		but cleaner to use it to reduce the amount of memory when no more used
Sub free_calendrier()
	if g_h_dll_calendrier_ <> NULL THEN DllMemFree(g_h_dll_calendrier_)
End Sub






'to reproduce the exported function date1 in calendrier.dll
Function dll_date1(byval day0 as long, byval month0 as long, byval year0 as long)as string

	if g_h_dll_calendrier_ = NULL THEN init_calendrier()
	dim Date1 as function (Byval  As UShort, Byval  As UShort, Byval  As UShort) As ZString Ptr _
			= DllMemGetProc(g_h_dll_calendrier_, "Date1")

	if Date1 = 0 THEN
		messagebox 0, "Wrong dll function name", "Error", MB_OK + MB_ICONERROR
		error 150
		return ""
	end if
	dim as string sret = *Date1(day0, month0, year0)
	'messagebox 0, sret, "Returned date", MB_OK
	return sret
End Function



