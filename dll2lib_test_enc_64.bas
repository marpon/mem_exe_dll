

#Include Once "windows.bi"

' compile with "PATH_TO_COMPILER" -x "libmy_dll64_enc_lib.a" -v -lib "dll2lib_test_enc_64.bas" > "dll2lib_test_enc_64.log" 2>&1
' replace PATH_TO_COMPILER by your own compiler path  ex   c:\freebasic\fbc.exe

#ifndef __FB_64BIT__
	#error ======> error not allowed for 32bits compiler!
#endif

'	cmdline to CSED_FB editor, seen as comment into source code so no effect on other editors
_:[CSED_COMPIL_NAME]:   libmy_dll64_enc_lib.a


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
dim shared as any ptr g_h_dll_my_dll64_ = NULL

' to incorpotate the dll into the created lib and get handle to the dll
sub init_my_dll64()

	__MACRO__INCLIGHT__(DLL64, "my_dll64_dll.enc")

	dim as ubyte ptr p1 = allocate(DLL64_len)
	p1 = Decrypt(DLL64, DLL64_len)
	memcpy(DLL64, p1, DLL64_len)
	deallocate(p1)
	if dllcheck_bits(DLL64, DLL64_len) <> dllCompilBits() THEN
		messagebox 0, "Not valid " & dllCompilBits() & " Dll included ! " & chr(10,10) & "Closing now.", "Error", MB_OK + MB_ICONERROR
		error 150
		exit sub
	end if
	'print "Loading embedded dll  DLL64 " , "my_dll64.dll" : print
	g_h_dll_my_dll64_ = DllMemLoad(DLL64)
	if g_h_dll_my_dll64_ = NULL THEN
		messagebox 0, "Wrong Dll ", "Error", MB_OK + MB_ICONERROR
		error 150
	end if
End Sub

'to "detach" the dll it is optionnal because it is done when prog close,
'		but cleaner to use it to reduce the amount of memory when no more used
Sub free_my_dll64()
	if g_h_dll_my_dll64_ <> NULL THEN DllMemFree(g_h_dll_my_dll64_)
End Sub







'to reproduce the exported function FF3_Dll in my_dll64.dll
Function dll_FF3_Dll(ByVal Titre1 as String, ByVal Valeur1 as String, ByVal Info1 as String)as string

	if g_h_dll_my_dll64_ = NULL THEN init_my_dll64()

	dim FF3_Dll as function(ByVal Titre1 as String, ByVal Valeur1 as String, ByVal Info1 as String) As Zstring Ptr _
				 = DllMemGetProc(g_h_dll_my_dll64_, "FF3_Dll")

	if FF3_Dll = 0 THEN
		messagebox 0, "Wrong dll function name", "Error", MB_OK + MB_ICONERROR
		error 150
		return ""
	end if
	dim as string sret = *FF3_Dll(Titre1, Valeur1, Info1)
	'messagebox 0, sret, "Returned date", MB_OK
	return sret
End Function



