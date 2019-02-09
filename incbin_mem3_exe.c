
#include <windows.h>
#include <tlhelp32.h>
#include <process.h>
#include <stdio.h>





#ifdef _WIN64
 typedef LONG(__stdcall* NtUnmapViewOfSectionF)(HANDLE , PVOID);
 #define _COMPIL_BITS_  64
#else
 typedef int (__stdcall* NtUnmapViewOfSectionF)(HANDLE , PVOID);
 #define _COMPIL_BITS_  32
#endif

/*
#define _MYSTR(a) #a

#define _MY_INJECT_(name, file) \
asm(".section .inject"); \
asm(".balign 4" ); \
asm(_UNDER_SCORED_ "start_" #name ":"); \
asm(".incbin " _MYSTR(file)); \
asm(_UNDER_SCORED_ "end_" #name ":"); \
extern unsigned char start_##name[0]; \
extern unsigned char end_##name[0]; */

#define INCBIN(symname, sizename, filename, section)       \
	extern unsigned char symname[] asm ( #symname );       \
    extern unsigned int sizename asm ( #sizename );\
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
	INCBIN( symname , symname##_len , filename, ".rodata")



/* 
_MY_INJECT_(bin0, "test99.txt")
_MY_INJECT_(bin1, "lorem.txt")
_MY_INJECT_(bin2, "test99.txt")

*/
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

void getcmdline(char *cmdline, char *pProcessName, char *pCmd)
{
	int j = 0;
	char *temp = cmdline;
	while(pProcessName[j])
	{
		temp[j] = pProcessName[j];
		j++;
	}
	if(pCmd != NULL)
	{
		temp[j] = 32;
		j++;
	}	
	int i = 0;
	while(pCmd[i])
	{		
		temp[j + i] = pCmd[i];
		i++;
	}	
	temp[j + i] = 0;	
	cmdline = temp;
	return;
}

// Fork Process
// Dynamically create a process based on the parameter 'lpImage'. The parameter should have the entire
// image of a portable executable file from address 0 to the end.
DWORD ForkProcess(LPVOID lpImage, char *pCmd)
{		
    NtUnmapViewOfSectionF NtUnmapViewOfSection = (NtUnmapViewOfSectionF)GetProcAddress(LoadLibrary("ntdll.dll"), "NtUnmapViewOfSection");

    // Variables for Process Forking
    SIZE_T              lWritten;
    int                	lHeaderSize;
    int                	lImageSize;
    int                	lSectionCount;
    int                	lSectionSize;
    int                	lFirstSection;
    SIZE_T              lPreviousProtection;
    int                	lJumpSize;

    int                 bReturnValue;
    LPVOID              lpImageMemory;
    LPVOID              lpImageMemoryDummy;
    
    IMAGE_DOS_HEADER    dsDosHeader;
    IMAGE_NT_HEADERS    ntNtHeader;     		
        
    // Variables for Local Process
    FILE*               fFile;
    char*               pProcessName;
    int                	lFileSize;
    int                	lLocalImageBase;
    int                	lLocalImageSize;
    LPVOID              lpLocalFile;
    IMAGE_DOS_HEADER    dsLocalDosHeader;
    IMAGE_NT_HEADERS    ntLocalNtHeader; 
    
    IMAGE_SECTION_HEADER    shSections[512 * 2];
    PROCESS_INFORMATION     piProcessInformation;
    STARTUPINFO             suStartUpInformation;
    CONTEXT                 cContext;
    
    DWORD               ValPid;

    bReturnValue = 0;
    ValPid = 0;
    pProcessName = (char*)malloc(MAX_PATH);
    ZeroMemory(pProcessName,MAX_PATH);
    // Get the file name for the dummy process
    if(GetModuleFileName(NULL, pProcessName, MAX_PATH) == 0)
    {
        free (pProcessName);
        return ValPid;
    }
    // Open the dummy process in binary mode
    fFile = fopen(pProcessName,"rb");
    if(!fFile)
    {
        free (pProcessName);
        return ValPid;
    }
    fseek(fFile,0,SEEK_END);
    // Get file size
    lFileSize = ftell(fFile);
    rewind(fFile);
    // Allocate memory for dummy file
    lpLocalFile = (char*)malloc(lFileSize);
    ZeroMemory(lpLocalFile, lFileSize);
    // Read memory of file
    fread(lpLocalFile,lFileSize,1,fFile);
    // Close file
    fclose(fFile);
    // Grab the DOS Headers
    memcpy(&dsLocalDosHeader, lpLocalFile, sizeof(dsLocalDosHeader));
    if(dsLocalDosHeader.e_magic != IMAGE_DOS_SIGNATURE)
    {
        free(pProcessName);
        free(lpLocalFile);
        return ValPid;
    }
    // Grab NT Headers
    memcpy(&ntLocalNtHeader, (LPVOID)((size_t)(lpLocalFile + dsLocalDosHeader.e_lfanew)), sizeof(ntNtHeader)); //sizeof(dsLocalDosHeader));
    if(ntLocalNtHeader.Signature != IMAGE_NT_SIGNATURE)
    {
        free(pProcessName);
        free(lpLocalFile);
        return ValPid;
    }
    // Get Size and Image Base
    lLocalImageBase = ntLocalNtHeader.OptionalHeader.ImageBase;
    lLocalImageSize = ntLocalNtHeader.OptionalHeader.SizeOfImage;
    // Deallocate
    free(lpLocalFile);
    lpLocalFile = NULL;
    // Grab DOS Header for Forking Process
    memcpy(&dsDosHeader, lpImage, sizeof(dsDosHeader));
    if(dsDosHeader.e_magic != IMAGE_DOS_SIGNATURE)
    {
        free(pProcessName);
        return ValPid;
    }
    // Grab NT Header for Forking Process
    memcpy(&ntNtHeader, (LPVOID)((size_t)(lpImage + dsDosHeader.e_lfanew)), sizeof(ntNtHeader));
    if(ntNtHeader.Signature != IMAGE_NT_SIGNATURE)
    {
        free(pProcessName);
        return ValPid;
    }
    // Get proper sizes
    lImageSize = ntNtHeader.OptionalHeader.SizeOfImage;
    lHeaderSize = ntNtHeader.OptionalHeader.SizeOfHeaders;
    // Allocate memory for image
    lpImageMemory = (char*)malloc(lImageSize);
    ZeroMemory(lpImageMemory, lImageSize);
    lpImageMemoryDummy = lpImageMemory;
    lFirstSection = (size_t)(lpImage + dsDosHeader.e_lfanew + sizeof(IMAGE_NT_HEADERS));

    memcpy(shSections, (LPVOID)(size_t)(lFirstSection), sizeof(IMAGE_NT_HEADERS) * ntNtHeader.FileHeader.NumberOfSections);
    memcpy(lpImageMemoryDummy, lpImage, lHeaderSize);
    // Get Section Alignment
    if((ntNtHeader.OptionalHeader.SizeOfHeaders % ntNtHeader.OptionalHeader.SectionAlignment) == 0)
    {
        lJumpSize = ntNtHeader.OptionalHeader.SizeOfHeaders;
    }
    else
    {
        lJumpSize  = (ntNtHeader.OptionalHeader.SizeOfHeaders / ntNtHeader.OptionalHeader.SectionAlignment);
        lJumpSize += 1;
        lJumpSize *= (ntNtHeader.OptionalHeader.SectionAlignment);
    }
    lpImageMemoryDummy = (LPVOID)((size_t)(lpImageMemoryDummy + lJumpSize));
    // Copy Sections To Buffer
    for(lSectionCount = 0; lSectionCount < ntNtHeader.FileHeader.NumberOfSections; lSectionCount++)
    {
        lJumpSize = 0;
        //printf("lSectionCount %d\n",lSectionCount );
        lSectionSize = shSections[lSectionCount].SizeOfRawData;
        memcpy(lpImageMemoryDummy, (LPVOID)((size_t)(lpImage + shSections[lSectionCount].PointerToRawData)), lSectionSize);
        if((shSections[lSectionCount].Misc.VirtualSize % ntNtHeader.OptionalHeader.SectionAlignment) == 0)
        {
            lJumpSize = shSections[lSectionCount].Misc.VirtualSize;
        }
        else
        {
            lJumpSize  = (shSections[lSectionCount].Misc.VirtualSize / ntNtHeader.OptionalHeader.SectionAlignment);
            lJumpSize += 1;
            lJumpSize *= (ntNtHeader.OptionalHeader.SectionAlignment);
        }
        lpImageMemoryDummy = (LPVOID)((size_t)(lpImageMemoryDummy + lJumpSize));
    }
    ZeroMemory(&suStartUpInformation, sizeof(STARTUPINFO));
    ZeroMemory(&piProcessInformation, sizeof(PROCESS_INFORMATION));
    ZeroMemory(&cContext, sizeof(CONTEXT));
    suStartUpInformation.cb = sizeof(suStartUpInformation);
    // Create Process
    char cmdline[4096];
    char *DummyName = "DummyMemProg.exe";
	getcmdline(&cmdline[0], DummyName, pCmd);
    if(CreateProcess(pProcessName, &cmdline[0], NULL, NULL, FALSE, CREATE_SUSPENDED, NULL, NULL, &suStartUpInformation, &piProcessInformation))
    {
        cContext.ContextFlags = CONTEXT_FULL;
        GetThreadContext(piProcessInformation.hThread,&cContext);
        // Check image base and image size
        if(lLocalImageBase == (int)(ntNtHeader.OptionalHeader.ImageBase) && lImageSize <= lLocalImageSize)
        {
            VirtualProtectEx(piProcessInformation.hProcess,(LPVOID)((size_t)ntNtHeader.OptionalHeader.ImageBase), lImageSize,PAGE_EXECUTE_READWRITE, (PDWORD)&lPreviousProtection);
        	//printf("here9\n" );
		}
        else
        {
            if(!NtUnmapViewOfSection(piProcessInformation.hProcess, (LPVOID)((size_t)lLocalImageBase)))
			{
            	VirtualAllocEx(piProcessInformation.hProcess, (LPVOID)((size_t)ntNtHeader.OptionalHeader.ImageBase), lImageSize, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
            	//printf("here10\n" );
			}               	
		}
        // Write Image to Process
        if(WriteProcessMemory(piProcessInformation.hProcess, (LPVOID)((size_t)ntNtHeader.OptionalHeader.ImageBase), lpImageMemory, lImageSize, &lWritten))
        {
            bReturnValue = 1;
            ValPid = piProcessInformation.dwProcessId;
        }
        // Set Image Base
	#ifdef _WIN64
		if(WriteProcessMemory(piProcessInformation.hProcess, (LPVOID)((size_t)(cContext.Rdx + 16)), &ntNtHeader.OptionalHeader.ImageBase, sizeof(int*), &lWritten))
    #else
   		if(WriteProcessMemory(piProcessInformation.hProcess, (LPVOID)((size_t)(cContext.Ebx + 8)), &ntNtHeader.OptionalHeader.ImageBase, sizeof(int*), &lWritten))
    #endif
        {
            if(bReturnValue == 1)
                ValPid = piProcessInformation.dwProcessId;
        }
        if(bReturnValue == 0)
        {
            free(pProcessName);
            free(lpImageMemory);
            return ValPid;
        }
        // Set the new entry point
    #ifdef _WIN64
   		cContext.Rcx = ntNtHeader.OptionalHeader.ImageBase + ntNtHeader.OptionalHeader.AddressOfEntryPoint;
    #else
   		cContext.Eax = ntNtHeader.OptionalHeader.ImageBase + ntNtHeader.OptionalHeader.AddressOfEntryPoint;
    #endif
        SetThreadContext(piProcessInformation.hThread, &cContext);
        if(lLocalImageBase == (int)ntNtHeader.OptionalHeader.ImageBase && lImageSize <= lLocalImageSize)
            VirtualProtectEx(piProcessInformation.hProcess, (LPVOID)((size_t)ntNtHeader.OptionalHeader.ImageBase), lImageSize, lPreviousProtection, 0);
        // Resume the process
        ResumeThread(piProcessInformation.hThread);
    }
    free(pProcessName);
    free(lpImageMemory);
    return ValPid;
}

int Exe_Memory(LPVOID lpImage)
{
    return (int)ForkProcess(lpImage, "");
}


/*
Can be used like this:

 	ForkProcess(pointer to executable memory);
   	or
    Exe_Memory(pointer to executable memory); retourne  0 si erreur,  pid si Ok
*/


int Pid4ProcPid( DWORD Pid)
{
	DWORD exists = 0;
    PROCESSENTRY32 entry;
    entry.dwSize = sizeof(PROCESSENTRY32);

    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

    if (Process32First(snapshot, &entry))
        while (Process32Next(snapshot, &entry))
            if (entry.th32ProcessID == Pid)
                exists = Pid;
    CloseHandle(snapshot);
    return exists;
}

int killProcess( int dwProcessId)
{
    int inf1 = 0;
    DWORD dwDesiredAccess = PROCESS_TERMINATE;
    int  bInheritHandle  = 0;
    HANDLE hProcess = OpenProcess(dwDesiredAccess, bInheritHandle, (DWORD)dwProcessId);
    if (hProcess == NULL)
        return inf1;

    BOOL result = TerminateProcess(hProcess, 0);

    CloseHandle(hProcess);
    if (result == FALSE) inf1 = 1;
    return inf1;
}




DWORD CheckPid( DWORD Pid)
{
	DWORD exists = 0;
    PROCESSENTRY32 entry;
    entry.dwSize = sizeof(PROCESSENTRY32);

    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

    if (Process32First(snapshot, &entry))
        while (Process32Next(snapshot, &entry))
            if (entry.th32ProcessID == Pid)
                exists = Pid;
    CloseHandle(snapshot);
    return exists;
}

int CheckBits(unsigned char* bArr , int len1)
{
	if (len1 < 62) return 0;
	int iret = bArr[60] + bArr[61] * 256;
    if (iret > len1) return 0;
	if (bArr[iret] == 80 &&  bArr[iret + 1] == 69 
            &&  bArr[iret + 2] == 0 &&  bArr[iret + 3] == 0)
    {
    	if (bArr[iret + 4] == 76 &&  bArr[iret + 5] == 1) return 32;
        if (bArr[iret + 4] == 100 &&  bArr[iret + 5] == 134) return 64;
    } 
	return 0;  
}


DWORD Exe_WaitMemory(LPVOID lpImage, char *pCmd)
{
    DWORD vv = 0;
    vv = ForkProcess(lpImage, pCmd);
    if (vv == 0)return 0;
    DWORD tt = vv;
    while (vv == tt)
    {
        Sleep(20) ;
		tt = Pid4ProcPid(vv);
    }
    return vv ;
}

DWORD select_mode(unsigned char* bArr, int len1, char *pCmd)
{
	int temp = CheckBits(bArr , len1);
	printf("CheckBits = %d\n", temp);
	printf("_COMPIL_BITS_ = %d\n", _COMPIL_BITS_);
	if (temp == _COMPIL_BITS_)
		return Exe_WaitMemory( (LPVOID) bArr , pCmd);
	return 0;
}


#ifdef _WIN64
# define EX0_FILE "test64.exe"
#else
# define EX0_FILE "test32.exe"
#endif

//_MY_INJECT_(EXE0, EX0_FILE )
INCFILE(EXE0, EX0_FILE)

int main( )
{
    /*
int len0 = end_bin0 - start_bin0;
    printf("ptr data %p    len %d\n\n", start_bin0, len0);
	show(start_bin0, len0);
    _MYSTR(file)
    int len1 = end_bin1 - start_bin1;
    printf("ptr data %p    len %d\n\n", start_bin1, len1);
	show(start_bin1, len1);
	
	int len2 = end_bin2 - start_bin2;
	printf("ptr data %p    len %d\n\n", start_bin2, len2);
	show(start_bin2, len2);*/
	printf(" EX0_FILE    %s \n ",  EX0_FILE);
	int len0 = EXE0_len;
	printf("EXE0_len = %d\n\n\n", EXE0_len); 
	printf("Actual pid = %d\n", _getpid());
	printf("===> lauching without cmdline \n ");
	DWORD ret = select_mode(EXE0, len0, "");
	printf("From_Memory pid = %d\n\n\n", (int)ret);
	
	char *cmdline = "\"test cmdline\" \"   coucou from here\" &more";
	printf("Actual pid = %d\n", _getpid());
	printf("===> lauching with cmdline :  %s\n ", cmdline);
	ret = select_mode(EXE0, len0, cmdline);
	printf("From_Memory pid = %d\n\n\n", (int)ret);
	printf("Actual pid = %d\n", _getpid());
	
	
	Sleep(3000);
    return 0;
}
