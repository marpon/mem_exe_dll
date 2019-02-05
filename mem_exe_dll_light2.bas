#Include Once "windows.bi"
'compile with or without console (if without the exe will add one to follow the sequence)


 /'
mem_exe_dll_light.bas          from marpon  23 jan 2019
test execute embedded exe from memory not from disk
test use embedded dll export functions from memory not from disk

the package (to simplify the compilation let all files in the same folder)
this bas file   mem_exe_dll_light.bas
2 static libs  libMemExeDll_32.a and libMemExeDll_64.a are available

4 exe files  "inputbox_generic64.exe" & "test64.exe" for 64   and   "exe_test.exe" & "test32.exe" for 32 bits
2 dll files  "my_dll64.dll" for 64 and "Calendrier.dll" for 32 bits

if you want to use any else exe  (what you want),  change the name on the define under
same for any else dll, but you have to modify the sub dll_32()  / sub dll_64() to follow the export function declaration

remember to place the new exe or dll on the same folder as the bas file to compile correctly

you can add any exe or/and dll you want, it only increases the size of the resulting compiled exe

to verify the resulting compiled exe has effectively embedded the exe... dll place the resulting exe in different folder
	and launch it from that folder , you will see not duplication of embedded files ... only working from memory


last important point, and limitation!
	if you compile in 64 bits you can only use dll 64 bits that is obvious  but only run exe 64 bits too
	in opposite when you compile in 32 bits you can only use dll 32 bits and run exe 32 bits

"inputbox_generic64.exe"                  	"test64.exe"
"exe_test.exe"								"test32.exe"
'/


'put under the files you want to test according 64 or 32 bits
#ifdef __FB_64BIT__
	#define _ExeFullPath "test64.exe"
	#define _DllFullPath "my_dll64.dll"
#else
	#define _ExeFullPath "test32.exe"
	#define _DllFullPath "Calendrier.dll"
#endif
#define _ExeFullPath32 "exe_test.exe"

#ifndef __MEM_EXE_DLL_HEADER
	#define __MEM_EXE_DLL_HEADER
	#ifdef __FB_64BIT__
		#INCLIB "MemExeDll_64"   				' C  lib64  > libMem_Exe_Dll64.a
	#else
		#INCLIB "MemExeDll_32"   				' C  lib32  > libMem_Exe_Dll32.a
	#endif


	EXTERN "C"

		'EXE from memory functions       ifConsoleshow  if <> 0 allows embedded console exe to show console content,  else  hide console content
		'========================================================
		DECLARE FUNCTION ExecMemExe alias "C_Fork"(byval dataU as any ptr, byval cmdline as zstring ptr , byval ifConsoleshow as long = 0) as Ulong  'return pid

		DECLARE FUNCTION Exe_Memory alias "C_ExeMem"(byval dataU as any ptr) as Ulong  'return pid

		DECLARE FUNCTION Exe_WaitMemory alias "C_ExeWaitMem"(byval dataU as any ptr, byval cmdline as zstring ptr , byval ifConsoleshow as long = 0) as Ulong ' execute and return to the line after when finish the exe

		'DLL from memory functions/subs
		'========================================================
		DECLARE FUNCTION DllMemoryLoad alias "C_DllMemLoad"(byval dllname as any ptr) as any ptr
		'attach the Dll in memory, return handle ptr

		DECLARE FUNCTION DllMemoryGetProc alias "C_DllMemGetProc"(byval phandle as any ptr, byval exportname as zstring ptr) as any ptr
		'declare export Function/sub from dll

		DECLARE SUB      DllMemoryFree alias "C_DllMemFree"(byval phandle as any ptr)
		'detach the dll from memory


		'Helper functions/subs
		'========================================================
		DECLARE FUNCTION Check_Bits alias "C_CheckBits"(byval dataU as any ptr , byval len1 as Long) as long
		'to check if exe/dll is 32 or 64  if 32 returns 32  , if 64 returns 64  , error returns 0

		DECLARE FUNCTION CompilBits alias "C_CompilBits"() as long
		'to check if compiled in  32 or 64  if 32 returns 32  , if 64 returns 64

		DECLARE FUNCTION ChekPid alias "C_CheckPid"(byval pid0 as Ulong) as Ulong  'if pid0 exists returns same value as pid0  or 0 if not

		DECLARE SUB killprocess alias "C_KillPid"(byval pid0 as Ulong) ' kill process by pid

		DECLARE FUNCTION actualpid alias "C_ActualPid"() as Ulong
		'get running pid

	END EXTERN

	dim shared consolemode as long

	'same as Exe_WaitMemory to adapt to your needs, to execute exe from memory and wait until it is finished
	Private	Function ExecWaitMem overload ( byval pdata as any ptr, byval str_cmd as zstring ptr, byval ifConsoleshow as long = 0) As Ulong
	    dim as Ulong pid
	    pid = ExecMemExe(pdata, str_cmd, ifConsoleshow )
	    if pid = 0 THEN return 0
	    dim  as Ulong pid2 = pid
	    Do while pid2 = pid
		    sleep 20
		    pid2 = ChekPid(pid)
	    LOOP
	    return pid
	End Function


	Private	Function ExecWaitMem overload ( byval pdata as any ptr) As Ulong
	    dim as Ulong pid
	    pid = Exe_Memory(pdata)
	    if pid = 0 THEN return 0
	    dim  as Ulong pid2 = pid
	    Do while pid2 = pid
		    sleep 20
		    pid2 = ChekPid(pid)
	    LOOP
	    return pid
	End Function
#endif





'simplified version of incbin files in exe
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


' to show usage
#ifdef __FB_64BIT__

	sub dll_64()
	    __MACRO__INCLIGHT__(DLL64, _DllFullPath)
	    if check_bits(DLL64, DLL64_len) <> CompilBits() THEN
		    messagebox 0, "Not valid " & CompilBits() & " Dll included ! " & chr(10,10) & "Closing now.", "Error", MB_OK + MB_ICONERROR
		    error 150
		end if
		print "Loading embedded dll  DLL64 " , _DllFullPath : print
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
	    print "end DLL64" : print : print
	END SUB

#else

	sub dll_32()
	    __MACRO__INCLIGHT__(DLL32, _DllFullPath)

	    if check_bits(DLL32, DLL32_len) <> CompilBits() THEN
		    messagebox 0, "Not valid " & CompilBits() & " Dll included ! " & chr(10,10) & "Closing now.", "Error", MB_OK + MB_ICONERROR
		    error 150
		end if
		print "Loading embedded dll  DLL32 " , _DllFullPath : print
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
	    print "end DLL32" : print : print
	END SUB

#endif

sub exe_64_32()
	__MACRO__INCLIGHT__(EXE64_32, _ExeFullPath)
	consolemode +=1
	if check_bits(EXE64_32, EXE64_32_len) <>  CompilBits() THEN   'prog_bits()
		messagebox 0, "Not valid " & CompilBits() & " Exe included ! " & chr(10,10) & "Closing now.", "Error", MB_OK + MB_ICONERROR
		error 150
	end if
	print "Executing embedded exe  EXE64_32 " , _ExeFullPath
	dim as long dret = ExecWaitMem(EXE64_32, "", 1)
	print "Included exe Pid " ; dret
	print "end EXE64_32": print : print
END SUB


sub exe_32_64()
	__MACRO__INCLIGHT__(EXE32_64, _ExeFullPath)
	dim as long  dret
	consolemode +=1
	dim as string cmdline = """  Hello world, how are you?"" ""Test to see"" ""cmd line input"" """" bye-bye ""Asta la vista baby!"""
	if check_bits(EXE32_64, EXE32_64_len) = CompilBits() THEN
		print "Executing embedded exe  EXE32_64 " , _ExeFullPath
		print " EXE32_64 with cmdline :  "; cmdline : print : print
		dret = Exe_WaitMemory( EXE32_64, cmdline )
	else
		messagebox 0, "Not valid " & CompilBits() & " Exe included ! " & chr(10,10) & "Closing now.", "Error", MB_OK + MB_ICONERROR
		error 150
	end if

	print "Included exe Pid " ; dret
	print "end EXE32_64" : print : print
END SUB



Private sub InConsole(byval t as long = 0, byref st1 as string = "")
	dim as HWND consol = GetConsoleWindow()
	if consol = NULL  and consolemode = 0  and t = 0 then
		AllocConsole()
		consol = GetConsoleWindow()
	end if
	if consol = NULL THEN exit sub
	if consolemode = 0 then
		if st1  <> "" THEN
			print: print: print st1  : print: print
			exit sub
		end if
	end if
	if t < 1 and st1 = "" THEN exit sub
	if st1  <> "" THEN
		print: print: print st1
		if t > 0  THEN
			print "   Or wait " & t & " secondes"
			sleep(t * 1000)
		end if
    END IF
End Sub



InConsole(, "In console mode!" )



print "starting here."
print "Main prog PID", "pid = " & actualpid(): print : print


'tests to verify
#ifdef __FB_64BIT__
	exe_64_32()
	dll_64()
	exe_32_64()
#else
	exe_64_32()
	dll_32()
	exe_32_64()
#endif



print "Main prog PID", "pid = " & actualpid()

InConsole(45, "Press any key to close.")


