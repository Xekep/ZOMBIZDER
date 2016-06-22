format pe gui 4.0
include '%fasm_inc%\include\win32ax.inc'

INVALID_FILE_ATTRIBUTES = -1

.data
byte1 db 0ebh
byte2 db 0c3h,90h
byte3 db 88h
byte4 db 0b8h,0,0,0,0,0ffh,0e0h,90h ; Перехват событий (Сплайсинг)

include 'Shellcode.asm'

pinfo PROCESS_INFORMATION
sinfo STARTUPINFO <sizeof.STARTUPINFO>

.code
proc start
	local path rb 512

	lea eax,[path]
	stdcall FindGamePath,eax,512
	.if eax=INVALID_FILE_ATTRIBUTES
		invoke MessageBoxA,0,'Игра не найдена.',0,MB_ICONERROR+MB_OK
		jmp .exit
	.endif

	lea eax,[path]
	invoke CreateProcessA,eax,0,0,0,0,CREATE_SUSPENDED,0,0,sinfo,pinfo
	.if eax<>0
		; Частичное отвязывание от Uplay, позволяющее играть без лицензии
		stdcall InjectCrack,[pinfo.hProcess]
		; Разблокировка дополнительного контента
		stdcall InjectUnlockExtraContent,[pinfo.hProcess]
		; Инъектирование шелл-кода чита
		stdcall InjectShellcode,[pinfo.hProcess]
		; Запуск основного потока на исполнение
		invoke ResumeThread,[pinfo.hThread]
		; Освобождение дескрипторов
		invoke CloseHandle,[pinfo.hThread]
		invoke CloseHandle,[pinfo.hProcess]
	.endif
   .exit:
	invoke ExitProcess,0
endp

proc FindGamePath buff, size
	local hKey:DWORD
	local size:DWORD

	lea eax,[hKey]
	invoke RegOpenKeyEx,HKEY_CURRENT_USER,.szRegSubKey,0,KEY_QUERY_VALUE,eax
	.if eax=0
		mov eax,[size]
		sub eax,.szSteamPath_size
		mov [size],eax
		lea eax,[size]
		invoke RegQueryValueExA,[hKey],.szRegKey,0,0,[buff],eax
		.if eax=0
			invoke lstrcatA,[buff],.szSteamPath
			invoke SetCurrentDirectoryA,[buff]
		.endif
		invoke RegCloseKey,[hKey]
	.endif
	invoke lstrcpyA,[buff],.szZombiExe
	invoke GetFileAttributes,[buff]
	ret

	.szSteamPath db '/steamapps/common/ZOMBI/',0
	.szSteamPath_size = $-.szSteamPath-1
	.szZombiExe db 'ZOMBI.EXE',0
	.szRegKey db 'SteamPath',0
	.szRegSubKey db 'Software\Valve\Steam',0

endp

proc InjectCrack hProcess
	local lpflOldProtec:DWORD
	
	lea esi,[lpflOldProtec]
	; Сигнатура 83 C4 08 83 F8 03 77 52 (JA SHORT 00XXXXXX)
	invoke VirtualProtectEx,[hProcess],005F5E16h,1,PAGE_EXECUTE_READWRITE,esi
	.if eax<>0
		invoke WriteProcessMemory,[hProcess],005F5E16h,byte1,1,esi
		.if eax<>0
			invoke FlushInstructionCache,[hProcess],005F5E16h,1
		.endif
	.endif
	; Сигнатура 83 C4 18 B8 01 00 00 00 5E 5D C3 33 C0 5D C3 CC
	; uplay_r1.UPLAY_WIN_SetActionsCompleted
	invoke VirtualProtectEx,[hProcess],009B3E28h,2,PAGE_EXECUTE_READWRITE,esi
	.if eax<>0
		invoke WriteProcessMemory,[hProcess],009B3E28h,byte2,2,esi
		.if eax<>0
			invoke FlushInstructionCache,[hProcess],009B3E28h,2
		.endif
	.endif
	; uplay_r1.UPLAY_Start
	invoke VirtualProtectEx,[hProcess],009B3E3Ah,2,PAGE_EXECUTE_READWRITE,esi
	.if eax<>0
		invoke WriteProcessMemory,[hProcess],009B3E3Ah,byte2,2,esi
		.if eax<>0
			invoke FlushInstructionCache,[hProcess],009B3E3Ah,2
		.endif
	.endif
	ret
endp

proc InjectUnlockExtraContent hProcess
	local lpflOldProtec:DWORD

	lea esi,[lpflOldProtec]
	; Сигнатура 8A 9C 86 84 00 00 00 (MOV BL,BYTE PTR DS:[ESI+EAX*4+84])
	invoke VirtualProtectEx,[hProcess],005F3641h,1,PAGE_EXECUTE_READWRITE,esi
	.if eax<>0
		invoke WriteProcessMemory,[hProcess],005F3641h,byte3,1,esi
		.if eax<>0
			invoke FlushInstructionCache,[hProcess],005F3641h,1
		.endif
	.endif
	ret
endp

proc InjectShellcode hProcess
	local lpflOldProtec:DWORD
	local lpAddress:DWORD

	invoke VirtualAllocEx,[hProcess],0,_injCode_size,MEM_RESERVE + MEM_COMMIT,PAGE_EXECUTE_READWRITE
	.if eax<>0
		mov [lpAddress],eax
		; Инициализация шелл-кода
		; Присвоение указателям на WINAPI функции, корректных значений адресов в памяти
		stdcall InitWinApi
		invoke WriteProcessMemory,[hProcess],[lpAddress],_injCode_begin,_injCode_size,0
		.if eax<>0
			invoke FlushInstructionCache,[hProcess],[lpAddress],_injCode_size
			; Сигнатура 8B 4D 08 3B 88 28 02 00 00 73 34 8B 80 24 02 00 00 8B 0C 88 (PUSH EBP)
			; Сплайсинг
			lea esi,[lpflOldProtec]
			invoke VirtualProtectEx,[hProcess],0067C770h,8,PAGE_EXECUTE_READWRITE,esi
			.if eax<>0
				mov eax,_fun1-_injCode_begin
				add eax,[lpAddress]
				mov dword [byte4+1],eax
				invoke WriteProcessMemory,[hProcess],0067C770h,byte4,8,esi
				.if eax<>0
					invoke FlushInstructionCache,[hProcess],0067C770h,8
					mov eax,[lpAddress]
					add eax,KeyboardSniffer-_injCode_begin
					invoke CreateRemoteThread,[hProcess],0,0,eax,0,0,0
				.else
					invoke VirtualFreeEx,[hProcess],[lpAddress],0,MEM_RELEASE
				.endif
			.endif
		 .else
			invoke VirtualFreeEx,[hProcess],[lpAddress],0,MEM_RELEASE
		 .endif
	.endif
	ret
endp

proc InitWinApi
		; WINAPI функции для шелл-кода
		mov eax,[ExitThread]
		mov [_ExitThread],eax
		mov eax,[Sleep]
		mov [_Sleep],eax
		mov eax,[GetAsyncKeyState]
		mov [_GetAsyncKeyState],eax
		mov eax,[MapVirtualKeyA]
		mov [_MapVirtualKeyA],eax
		mov eax,[GetModuleHandleA]
		mov [_GetModuleHandleA],eax
		mov eax,[CreateThread]
		mov [_CreateThread],eax
		mov eax,[CreateMutexA]
		mov [_CreateMutexA],eax
		mov eax,[WaitForSingleObject]
		mov [_WaitForSingleObject],eax
		mov eax,[ReleaseMutex]
		mov [_ReleaseMutex],eax
		mov eax,[fopen]
		mov [__wfopen],eax
		mov eax,[fprintf]
		mov [_fprintf],eax
		mov eax,[fwprintf]
		mov [_fwprintf],eax
		mov eax,[fclose]
		mov [_fclose],eax
		mov eax,[lstrcmpW]
		mov [_lstrcmpW],eax
		mov eax,[lstrlenA]
		mov [_lstrlenA],eax
		mov eax,[lstrcpyA]
		mov [_lstrcpyA],eax
		mov eax,[lstrcmpA]
		mov [_lstrcmpA],eax
		mov eax,[GetKeyboardState]
		mov [_GetKeyboardState],eax
		mov eax,[ToAscii]
		mov [_ToAscii],eax
		mov eax,[VirtualProtect]
		mov [_VirtualProtect],eax
		mov eax,[memcpy]
		mov [_memcpy],eax
		mov eax,[ActivateKeyboardLayout]
		mov [_ActivateKeyboardLayout],eax
		mov eax,[LoadKeyboardLayoutA]
		mov [_LoadKeyboardLayoutA],eax
		ret
endp
.end start