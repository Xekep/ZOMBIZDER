format pe gui 4.0
include '%fasm_inc%\include\win32ax.inc'

.data
pinfo PROCESS_INFORMATION
sinfo STARTUPINFO
lpflOldProtec dd ?
ZombiPath db '%s/steamapps/common/ZOMBI/',0
ZombiExe db 'ZOMBI.EXE',0
RegSubKey db 'Software\Valve\Steam',0
RegKey db 'SteamPath',0
byte1 db 0ebh
byte2 db 0c3h,90h
byte3 db 88h
byte4 db 0b8h,0,0,0,0,0ffh,0e0h,90h ; Перехват событий
SteamPath rb 512
StartPath rb 512
HKey dd ?
sz dd 512
steam db 0

proc injThread arg
	local VirtKey:DWORD
	local ScanCode:DWORD
	local KeyState rb 256

	call .base
       .base:
	pop ebx
	sub ebx,.base
	invoke _CreateMutexA+ebx,0,0,0
	mov [hMutex+ebx],eax
	; Меняем раскладку потока на английскую
	invoke _LoadKeyboardLayoutA+ebx,'00000409',0
	invoke _ActivateKeyboardLayout+ebx,eax,0
	@@:
	invoke _Sleep+ebx,10
	mov ecx,5Ah
	lea edi,[.buff+ebx]
      .loop:
	dec ecx
	mov [VirtKey],ecx
	cmp [InGame+ebx],0
	je .endloop
	push ecx
	invoke _GetAsyncKeyState+ebx,ecx
	.if eax=-32767
		invoke _lstrlenA+ebx,edi
		.if eax=10
			lea esi,[edi+eax-1]
			lea eax,[edi+1]
			invoke _lstrcpyA+ebx,edi,eax
		.else
			lea esi,[edi+eax]
		.endif
		MAPVK_VSC_TO_VK_EX = 3
		invoke _MapVirtualKeyA+ebx,[VirtKey],MAPVK_VSC_TO_VK_EX
		mov [ScanCode],eax
		lea eax,[KeyState]
		invoke _GetKeyboardState+ebx,eax
		lea eax,[KeyState]
		invoke _ToAscii+ebx,[VirtKey],[ScanCode],eax,esi,0
		mov byte [esi+1],0
	.endif
	pop ecx
	cmp ecx,11
	ja .loop
       .check:
	invoke _lstrlenA+ebx,edi
	mov esi,eax
	.if eax>=5
		lea eax,[edi+esi-5]
		invoke _lstrcmpA+ebx,eax,'iddqd'
		.if eax=0
			lea eax,[_DrawText+ebx]
			.if [GodMode+ebx]
				lea ecx,[.godmodeoff+ebx]
				mov [GodMode+ebx],0
			.else
				lea ecx,[.godmodeon+ebx]
				mov [GodMode+ebx],1
			.endif
			invoke _CreateThread+ebx,0,0,eax,ecx,0,0
			mov dword [edi],0
			jmp .endloop
		.endif
		lea eax,[edi+esi-5]
		invoke _lstrcmpA+ebx,eax,'idkfa'
		.if eax=0
			lea eax,[_DrawText+ebx]
			lea ecx,[.giveall+ebx]
			invoke _CreateThread+ebx,0,0,eax,ecx,0,0
			mov dword [edi],0
			jmp .endloop
		.endif
	.endif
      .endloop:
	jmp @b
	.buff rb 11
	.godmodeon du 'God mode on',0
	.godmodeoff du 'God mode off',0
	.giveall du 'All Weapons',0
endp

proc _fun1 arg1,EventName,arg3,arg4; Перехват событий интерфейса
	pushad
	call .base
       .base:
	pop ebx
	sub ebx,.base
	; Регион логирования событий
	cinvoke __wfopen+ebx,'Events.log','a'
	mov esi,eax
	lea ecx,[.format+ebx]
	cinvoke _fwprintf+ebx,eax,ecx,[EventName]
	cinvoke _fclose+ebx,esi
	; Конец региона
	.if [hModule+ebx]=0
		invoke _GetModuleHandleA+ebx,'rabbids.win32.f.dll'
		mov [hModule+ebx],eax
		lea ecx,[injHooks+ebx]
		stdcall ecx,eax
	.endif
	; Событие displayStartScreenEvent = в меню
	lea eax,[displayStartScreenEvent+ebx]
	invoke _lstrcmpW+ebx,[EventName],eax
	test eax,eax
	jne @f
	mov [InGame+ebx],0
	@@:
	; Событие setSlotPositionEvent = в игре
	lea eax,[setSlotPositionEvent+ebx]
	invoke _lstrcmpW+ebx,[EventName],eax
	test eax,eax
	jne @f
	mov [InGame+ebx],1
	@@:
	; Событие displaySubtitleEvent = не в игре
	lea eax,[displaySubtitleEvent+ebx]
	invoke _lstrcmpW+ebx,[EventName],eax
	test eax,eax
	jne @f
	mov [InGame+ebx],0
	@@:
      .pass:
	popad
	mov eax,005F72D0h
	call eax
	mov ecx,0067C348h
	jmp ecx
	ret
	.format db '%',0,'s',0,13,0,10,0,0,0
endp

proc injHooks hModule
	local lpflOldProtec:DWORD

	pushad
	call .base
       .base:
	pop ebx
	sub ebx,.base
	add [hModule],2557C9h
	lea eax,[lpflOldProtec]
	invoke _VirtualProtect+ebx,[hModule],2,PAGE_EXECUTE_READWRITE,eax
	.if eax<>0
		lea eax,[_godmode+ebx]
		mov dword [.byte+ebx+1],eax
		lea eax,[.byte+ebx]
		cinvoke _memcpy+ebx,[hModule],eax,10
	.endif
	popad
	ret
	.byte db 0b8h,0,0,0,0,0ffh,0e0h,90h,90h,90h
endp

proc _godmode
	pushad
	call .base
       .base:
	pop ebx
	sub ebx,.base
	cmp [GodMode+ebx],1
	jne .godmodeoff
	cmp ebp,18AD1Ch
	je .godmode
	cmp ebp,18AD68h
	je .godmode
     .godmodeoff:
	comiss xmm0,xmm1
	jb .m1 ; ON DEATH XXM1
	movss dword [esi],xmm0
	jmp .m2 ; ON NEARBY POP'S AND RET
     .godmode:
	push edi
	mov edi,dword [esi+4]
	mov dword [esi],edi
	pop edi
	jmp .m2
     .m1:
	movss dword [esi],xmm1
     .m2:
	popad
	pop esi
	pop ebx
	pop ebp
	retn 0Ch
endp

proc _DrawText text
	call .base
       .base:
	pop ebx
	sub ebx,.base
	@@:
	mov esi,[hModule+ebx]
	.if esi<>0 & [InGame+ebx]=1
		invoke _WaitForSingleObject+ebx,[hMutex+ebx],-1
		cmp eax,WAIT_OBJECT_0
		jne .exit
		; Показываем текст
		push 10
		push [text]
		push 1
		lea eax,[esi+023E20h]
		call eax
		mov ecx,eax
		lea eax,[esi+12E6D0h]
		call eax
		; Засыпаем
		invoke _Sleep+ebx,900
		; Убираем текст
		push 10
		push [text]
		push 0
		lea eax,[esi+023E20h]
		call eax
		mov ecx,eax
		lea eax,[esi+12E6D0h]
		call eax
		invoke _ReleaseMutex+ebx,[hMutex+ebx]
	.endif
      .exit:
	invoke _ExitThread+ebx,0
endp

_VirtualProtect dd ?
_WaitForSingleObject dd ?
_ReleaseMutex dd ?
_CreateMutexA dd ?
_CreateThread dd ?
_GetModuleHandleA dd ?
_Sleep dd ?
_GetAsyncKeyState dd ?
_MapVirtualKeyA dd ?
_ExitThread dd ?
__wfopen dd ?
_fwprintf dd ?
_fclose dd ?
_lstrcmpW dd ?
_lstrlenA dd ?
_lstrcpyA dd ?
_lstrcmpA dd ?
_GetKeyboardState dd ?
_ToAscii dd ?
_memcpy dd ?
_ActivateKeyboardLayout dd ?
_LoadKeyboardLayoutA dd ?

displayActiveText2Event du 'displayActiveText2Event',0
setSlotPositionEvent du 'setSlotPositionEvent',0
displayStartScreenEvent du 'displayStartScreenEvent',0
displaySubtitleEvent du 'displaySubtitleEvent',0

hModule dd 0
hMutex dd ?
InGame db 0
GodMode db 0

_injCode_size = $-injThread


.code
start:
	invoke RegOpenKeyEx,HKEY_CURRENT_USER,RegSubKey,0,KEY_QUERY_VALUE,HKey
	.if eax=0
		invoke RegQueryValueExA,[HKey],RegKey,0,0,SteamPath,sz
		.if eax=0
			mov [steam],1
			cinvoke wsprintfA,StartPath,ZombiPath,SteamPath
			invoke SetCurrentDirectoryA,StartPath
		.endif
		invoke RegCloseKey,[HKey]
	.endif
	invoke lstrcatA,StartPath,ZombiExe
	INVALID_FILE_ATTRIBUTES = -1
	invoke GetFileAttributes,StartPath
	.if eax=INVALID_FILE_ATTRIBUTES
		invoke MessageBoxA,0,'Гамес не найден.','Ирар',MB_ICONERROR+MB_OK
		jmp .exit
	.endif
	invoke CreateProcessA,StartPath,0,0,0,0,CREATE_SUSPENDED,0,0,sinfo,pinfo
	.if eax<>0
		invoke VirtualProtectEx,[pinfo.hProcess],005F58D6h,1,PAGE_EXECUTE_READWRITE,lpflOldProtec
		.if eax<>0
			invoke WriteProcessMemory,[pinfo.hProcess],005F58D6h,byte1,1,lpflOldProtec
			.if eax<>0
				invoke FlushInstructionCache,[pinfo.hProcess],005F58D6h,1
			.endif
		.endif
		invoke VirtualProtectEx,[pinfo.hProcess],009B3958h,2,PAGE_EXECUTE_READWRITE,lpflOldProtec
		.if eax<>0
			invoke WriteProcessMemory,[pinfo.hProcess],009B3958h,byte2,2,lpflOldProtec
			.if eax<>0
				invoke FlushInstructionCache,[pinfo.hProcess],009B3958h,2
			.endif
		.endif
		invoke VirtualProtectEx,[pinfo.hProcess],009B396Ah,2,PAGE_EXECUTE_READWRITE,lpflOldProtec
		.if eax<>0
			invoke WriteProcessMemory,[pinfo.hProcess],009B396Ah,byte2,2,lpflOldProtec
			.if eax<>0
				invoke FlushInstructionCache,[pinfo.hProcess],009B396Ah,2
			.endif
		.endif
		invoke VirtualProtectEx,[pinfo.hProcess],005F3101h,1,PAGE_EXECUTE_READWRITE,lpflOldProtec
		.if eax<>0
			invoke WriteProcessMemory,[pinfo.hProcess],005F3101h,byte3,1,lpflOldProtec
			.if eax<>0
				invoke FlushInstructionCache,[pinfo.hProcess],005F3101h,1
			.endif
		.endif
		; Инъектирование шелл-кода чита
		invoke VirtualAllocEx,[pinfo.hProcess],0,_injCode_size,MEM_RESERVE + MEM_COMMIT,PAGE_EXECUTE_READWRITE
		.if eax<>0
			mov esi,eax
			stdcall InitWinApi
			invoke WriteProcessMemory,[pinfo.hProcess],esi,injThread,_injCode_size,0
			.if eax<>0
				invoke FlushInstructionCache,[pinfo.hProcess],esi,_injCode_size
				invoke VirtualProtectEx,[pinfo.hProcess],0067C340h,8,PAGE_EXECUTE_READWRITE,lpflOldProtec
				.if eax<>0
					; Хук
					lea eax,[_fun1-injThread]
					add eax,esi
					mov dword [byte4+1],eax
					invoke WriteProcessMemory,[pinfo.hProcess],0067C340h,byte4,8,lpflOldProtec
					.if eax<>0
						invoke FlushInstructionCache,[pinfo.hProcess],0067C340h,8
						invoke CreateRemoteThread,[pinfo.hProcess],0,0,esi,0,0,0
					.else
						invoke VirtualFreeEx,[pinfo.hProcess],esi,0,MEM_RELEASE
					.endif
				.endif
			 .else
				invoke VirtualFreeEx,[pinfo.hProcess],esi,0,MEM_RELEASE
			 .endif
		.endif
		invoke ResumeThread,[pinfo.hThread]
		invoke CloseHandle,[pinfo.hThread]
		invoke CloseHandle,[pinfo.hProcess]
	.endif
       .exit:
	invoke ExitProcess,0

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