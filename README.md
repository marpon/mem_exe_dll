# mem_exe_dll
embedd files in executable and launch win exe from memory or use dll from memory

Last version V4 give the possibility to embedd pre-encryped files and decrypt them directly in memory, when needed at run time.
That encrypt/decrypt is not very safe in terms of protection of the code, its a very minimal encrytion method.
It is just a proof of concept, but works well.
If more protection of the code is needed better to create your own encrypt/decrypt functions...

An exercice was also privided to embedd  dll into  static lib and use after as a 'normal' static lib.
What it is nice here, is you can "borrow" some existing dll, include it into your code (encoded if you want)
and use it from memory.

The only limitation of these tools is you can only use existing dll/exe 32bits when your main prog is 32bits
and same limitation on 64bits, only dll/exe 64bits with 64bits main prog.

Obviously, you cannot strip dll of code you don't use, so the resulting exe increase by the size of your embedded exe/dll.

Sure, you can add compression too to reduce the size of embedeed files, but you have in that case, hold some code to uncompress the the embedeed files at run time.

I let that extension as an exercice for the one who want to make it.

Last point, when executing exe from memory, some anti-virus react as false positive detection (Heuristic)
when testing on virus total got 5 AV tools heuristic detection.

Whith only dll from memory, no problem.


