

#ifndef __MEM_DLL_HEADER
	#define __MEM_DLL_HEADER
	#ifdef __FB_64BIT__

		#INCLIB "MemDll_64"   				' C  lib64  > libMemDll_64.a
	#else
		#INCLIB "MemDll_32"   				' C  lib32  > libMemDll_32.a
	#endif


	EXTERN "C"

		declare Function R_File alias "R_File"(byval fname as zstring ptr, byval ilen as long ptr) as zstring ptr
		declare Function W_File alias "W_File" (byval fname as zstring ptr, byval buffer as zstring ptr, byval ilen as long)as long
		DECLARE FUNCTION Encrypt alias "Encrypt"(byval input as zstring ptr, byval ilen as long ) as zstring ptr

	END EXTERN

#endif

dim as string fname = "Calendrier.dll"
dim as string fname_enc = "Calendrier_dll.enc"

dim as long ilen
dim as zstring ptr ps1 = R_File(strptr(fname), @ilen)

dim as zstring ptr pbuf = Encrypt(ps1, ilen)

W_File(strptr(fname_enc), pbuf ,ilen)
