#Include Once "windows.bi"

#ifdef __FB_64BIT__
	#error ======> error not allowed for 64bits compiler!
#endif
#INCLIB "Calendrier_enc_lib"    ' full name   libCalendrier_enc_lib.a

declare function dll_date1(byval day0 as long, byval month0 as long, byval year0 as long)as string
declare Sub free_calendrier()


dim as string sret = dll_date1(6, 5, 1985)

messagebox 0,  "Returned date = " & sret  , "From Calendrier_lib", 0

'optionnal but cleaner...
free_calendrier()


