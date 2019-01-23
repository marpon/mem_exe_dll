#Include Once "windows.bi"
'compile with or without console (if without the exe will add one to follow the sequence)


 /'
mem_exe_dll_light.bas          from marpon  23 jan 2019
test execute embedded exe from memory not from disk
test use embedded dll export functions from memory not from disk

the package (to simplify the compilation let all files in the same folder)
this bas file   mem_exe_dll_light.bas
2 static libs  libMem_Exe_Dll64.a and libMem_Exe_Dll32.a are available

2 exe files  "inputbox_generic64.exe"  for 64   and   "exe_test.exe" for 32 bits
2 dll files  "my_dll64.dll" for 64 and "Calendrier.dll" for 32 bits

if you want to use any else exe  (what you want),  change the name on the define under
same for any else dll, but you have to modify the sub dll_32()  / sub dll_64() to follow the export function declaration

remember to place the new exe or dll on the same folder as the bas file to compile correctly

you can add any exe or/and dll you want, it only increases the size of the resulting compiled exe

to verify the resulting compiled exe has effectively embedded the exe... dll place the resulting exe in different folder
	and launch it from that folder , you will see not duplication of embedded files ... only working from memory


last important point, and limitation!
	if you compile in 64 bits you can only use dll 64 bits that is obvious  but only exe 64 bits too
	oposite when you compile in 32 bits you can only use dll 32 bits and exe 32 bits

'/


'put under the files you want to test according 64 or 32 bits
#ifdef __FB_64BIT__
	#define _ExeFullPath "inputbox_generic64.exe"
	#define _DllFullPath "my_dll64.dll"
#else
	#define _ExeFullPath "exe_test.exe"
	#define _DllFullPath "Calendrier.dll"
#endif


#ifndef __MEM_EXE_DLL_HEADER
	#define __MEM_EXE_DLL_HEADER
	#ifdef __FB_64BIT__
		#INCLIB "Mem_Exe_Dll64"   				' C  lib64  > libMem_Exe_Dll64.a
	#else
		#INCLIB "Mem_Exe_Dll32"   				' C  lib32  > libMem_Exe_Dll32.a
	#endif

	EXTERN "C"

		'EXE from memory functions
		'========================================================
	  #ifdef __FB_64BIT__
		'will work only with 64 bits program with 64 included
		DECLARE FUNCTION ExecMemFile alias "ExecFile64"(byval nameprog as zstring ptr, byval dataU as any ptr) as long  'return pid
	  #else
		'will work only with 32 bits program with 32 included
		DECLARE FUNCTION ExecMemFile alias "ExecFile32"(byval nameprog as zstring ptr, byval dataU as any ptr) as long  'return pid
	  #endif

		'DLL from memory functions/subs
		'========================================================
		'attach the Dll in memory, return handle ptr
		DECLARE FUNCTION DllMemoryLoad alias "DllMemoryLoad"(byval dllname as any ptr) as any ptr

		'declare export Function/sub from dll
		DECLARE FUNCTION DllMemoryGetProc alias "DllMemoryGetProc"(byval phandle as any ptr, byval exportname as zstring ptr) as any ptr

		'detach the dll from memory
		DECLARE SUB      DllMemoryFree alias "DllMemoryFree"(byval phandle as any ptr)

		'Helper functions/subs
		'========================================================
		'if pid0 exists returns same value as pid0  or 0 if not
		DECLARE FUNCTION pid4procpid alias "Pid4ProcPid"(byval pid0 as integer) as long

		'kill process by pid
		DECLARE FUNCTION killprocess alias "killProcess"(byval pid0 as integer) as long

		'get running pid
		DECLARE FUNCTION actualpid alias "ActualPid"() as long

		'to check if exe/dll is 32 or 64  if 32 returns 32  , if 64 returns 64  , error returns 0
		DECLARE FUNCTION Check_Bits alias "Check_Bits"(byval dataU as any ptr , byval len1 as Long) as long

	END EXTERN

	' to adapt to your needs, to execute exe from memory and wait until it is finished
	Function ExecWaitMem(byval str_name as zstring ptr, byval pdata as any ptr) As long
	   dim as long pid
	   pid = ExecMemFile(str_name, pdata)
	   if pid = 0 THEN return 0
	   dim  as long pid2 = pid
	   Do while pid2 = pid
		  sleep 20
		  pid2 = pid4procpid(pid)
	   LOOP
	   return pid
	End Function

#endif


'simplified version of incbin files in exe
#IfnDef INCFILE_LIGHT_
 #Define INCFILEX_LIGHT_

 #Macro __MACRO__INCLIGHT__(label, file)
  #If __FUNCTION__ = "__FB_MAINPROC__"
	#error =====> error  outside Sub/Function!
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


function prog_bits() as long
  #ifdef __FB_64BIT__
	return 64
  #else
	return 32
  #endif
END FUNCTION


' to show usage
#ifdef __FB_64BIT__

	sub exe_64()
		__MACRO__INCLIGHT__(EXE64, _ExeFullPath)
		if check_bits(EXE64, EXE64_len) <>  prog_bits() THEN   'prog_bits()
		   messagebox 0, "Not valid " & prog_bits() & " Exe included ! " & chr(10,10) & "Closing now.", "Error", MB_OK + MB_ICONERROR
		   'messagebox 0, "Not valid " & "PE32+" & " Exe included ! " & chr(10,10) & "Closing now.", "Error", MB_OK + MB_ICONERROR
		   error 150
		end if
	   dim as long dret = ExecWaitMem( _ExeFullPath, EXE64)
	   print "included exe Pid " ; dret
	   print "end EXE64"
	END SUB

	sub dll_64()
	   __MACRO__INCLIGHT__(DLL64, _DllFullPath)
	   if check_bits(DLL64, DLL64_len) <> prog_bits() THEN
		   messagebox 0, "Not valid " & prog_bits() & " Dll included ! " & chr(10,10) & "Closing now.", "Error", MB_OK + MB_ICONERROR
		   error 150
		end if

	   dim as any ptr hhd64 = DllMemoryLoad(DLL64)
	   if hhd64 = NULL THEN
		   messagebox 0, "Wrong Dll ", "Error", MB_OK + MB_ICONERROR
		   exit sub
		end if
	   dim jour as function(ByVal Titre1 as String, ByVal Valeur1 as String, ByVal Info1 as String) As Zstring Ptr
									jour = DllMemoryGetProc(hhd64, "FF3_Dll")

		if jour = 0 THEN
			messagebox 0, "Wrong Dll or wrong function name", "Error", MB_OK + MB_ICONERROR
		else
			messagebox 0, jour("coucou", "val", "info"), "from dll34", MB_OK
	   end if
	   DllMemoryFree(hhd64)
	   print "end DLL64"
	END SUB

#else

	sub exe_32()
		__MACRO__INCLIGHT__(EXE32, _ExeFullPath)
		 if check_bits(EXE32, EXE32_len) <>  prog_bits() THEN   'prog_bits()
		   messagebox 0, "Not valid " & prog_bits() & " Exe included ! " & chr(10,10) & "Closing now.", "Error", MB_OK + MB_ICONERROR
		   error 150
		end if

	   dim as long dret = ExecWaitMem( _ExeFullPath, EXE32)
	   print "included exe Pid " ; dret
	   print "end EXE32"
	END SUB

	sub dll_32()
	   __MACRO__INCLIGHT__(DLL32, _DllFullPath)

	   if check_bits(DLL32, DLL32_len) <> prog_bits() THEN
		   messagebox 0, "Not valid " & prog_bits() & " Dll included ! " & chr(10,10) & "Closing now.", "Error", MB_OK + MB_ICONERROR
		   error 150
		end if

	   dim  as any ptr hhdll = DllMemoryLoad(DLL32)
	   if hhdll = NULL THEN
		   messagebox 0, "Wrong Dll ", "Error", MB_OK + MB_ICONERROR
		   exit sub
		end if
	   dim jour as function (Byval  As UShort, Byval  As UShort, Byval  As UShort) As ZString Ptr _
									= DllMemoryGetProc(hhdll, "Date1")

		if jour = 0 THEN
			messagebox 0, "Wrong Dll or wrong function name", "Error", MB_OK + MB_ICONERROR
		else
			messagebox 0, jour(06, 5, 1985), "Selected date", MB_OK
		end if
	   DllMemoryFree(hhdll)
	   print "end DLL32"
	END SUB

#endif



if GetConsoleWindow() < 1 then AllocConsole()

print "main prog PID", "pid = " & actualpid()

'tests to verify
#ifdef __FB_64BIT__
	dll_64()
	exe_64()
#else
	dll_32()
	exe_32()
#endif


print "main prog PID", "pid = " & actualpid()

if GetConsoleWindow() > 0 Then
	print: print: print "Press any key to close,   or program will close in 25s"
	sleep 25000
end if



