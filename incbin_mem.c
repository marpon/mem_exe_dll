#include <stdio.h>


/*

#ifdef _WIN64
 #define _UNDER_SCORED_ ""
#else
 #define _UNDER_SCORED_ "_"
#endif

#define _MYSTR(a) #a

#define _MY_INJECT_(name, file) \
asm(".section .inject"); \
asm(".balign 4" ); \
asm(_UNDER_SCORED_ "start_" #name ":"); \
asm(".incbin " _MYSTR(file)); \
asm(_UNDER_SCORED_ "end_" #name ":"); \
extern unsigned char start_##name[0] ; \
extern unsigned char end_##name[0] ; 

*/



#define INCBIN_EX(symname, sizename, filename, section)    \
	extern unsigned char symname[] asm ( #symname );       \
    extern unsigned int sizename asm ( #sizename );        \
    __asm__ (".section " #section );                       \
	__asm__ (".balign 4");                                 \
	__asm__ (".globl " #symname);                          \
    __asm__ (#symname ":");                                \
	__asm__ (".incbin \"" filename "\"");                  \
    __asm__ (".section " #section );                       \
	__asm__ (".balign 1");                                 \
    __asm__ (#symname "_end:");                            \
    __asm__ (".section " section);                         \
	__asm__ (".balign 4");                                 \
	__asm__ (".globl " #sizename);                         \
    __asm__ (#sizename ":");                               \
	__asm__ (".long " #symname "_end - " #symname ); 
    
    
#define INCFILE(symname, filename)                         \
	INCBIN_EX( symname , symname##_len , filename, ".rodata")


void show(unsigned char *s1 , size_t j)
{
	size_t i = 0;
	while (i < j)
	{
		printf("%c", s1[i]);
		i++;
	}
	printf("\n\n");
}




INCFILE(FILE0, "asm.txt")

int main( )
{
 
	printf(" FILE0 ptr %p   len %d \n\n\n ",  FILE0, FILE0_len);
	show(FILE0, FILE0_len);

    return 0;
}
