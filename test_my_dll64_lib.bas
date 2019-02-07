#Include Once "windows.bi"

#ifndef __FB_64BIT__
	#error ======> error not allowed for 32bits compiler!
#endif
#INCLIB "my_dll64_lib"    ' full name   libmy_dll64_lib.a

declare function dll_FF3_Dll(ByVal Titre1 as String, ByVal Valeur1 as String, ByVal Info1 as String)as string
declare Sub free_my_dll64()


dim as string sret = dll_FF3_Dll("It is my title", "My initial value", "Here is the initial information")

messagebox 0,  "Returned value = " & sret  , "From my_dll64_lib", 0

'optionnal but cleaner...
free_my_dll64()


