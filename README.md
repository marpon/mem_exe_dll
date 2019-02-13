# mem_exe_dll
embedd files in executable and launch win exe from memory or use dll from memory

Last version V4 give the possibility to embedd pre-encryped files and decrypt them directly in memory, when needed at run time.
That encrypt/decrypt feature is not intended to be very safe in terms of protection of the code, it's a very minimal encrytion method.
Just a proof of concept, but works well.
If more protection of the code is needed better to create your own encrypt/decrypt functions...

I tried not to increase the memory permanently, so I've put the decoded part at the same
memory place as it was encoded, freeing the temporary buffer after usage.

An exercice was also privided to embedd  dll into  static lib and used after as a 'normal' static lib.
What it is nice here, is you can "borrow" some existing dll, include it into your code (encoded if you want)
and use it from memory. (you only have to reproduce the declaration of the exported functions you want to use)

The only limitation of these tools is you can only use existing dll/exe 32bits when your main prog is 32bits
and same limitation on 64bits, only dll/exe 64bits with 64bits main prog.
I've tried to execute 32bits exe into 64bits but did not succeed, if somebody knows how to do...

Obviously, you cannot strip from dll the code you don't use, so the resulting exe will increase by the size of your embedded exe/dll.

Sure, you can add compression too to reduce the size of embedeed files, but you have in that case, to hold some code to uncompress the embedeed files at run time.

I let that extension as an exercice for the one's who want to make it.

Last point, when executing exe from memory, some anti-virus react as false positive virus,
when testing on virus total got 5 AV tools heuristic detection.

With only dll from memory, no problem.

interrested on your remarks  marpon@aliceadsl.fr


