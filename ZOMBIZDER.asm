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
byte4 db 0b8h,0,0,0,0,0ffh,0e0h,90h ; �������� �������
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
	; ������ ��������� ������ �� ����������
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
			lea eax,[_giveweapons+ebx]
			call eax
			.if al=0
				lea eax,[_DrawText+ebx]
				lea ecx,[.invisfull+ebx]
				invoke _CreateThread+ebx,0,0,eax,ecx,0,0
			.endif
			lea eax,[_DrawText+ebx]
			lea ecx,[.giveall+ebx]
			invoke _CreateThread+ebx,0,0,eax,ecx,0,0
			mov dword [edi],0
			jmp .endloop
		.endif
		lea eax,[edi+esi-5]
		invoke _lstrcmpA+ebx,eax,'idohk'
		.if eax=0
			lea eax,[_DrawText+ebx]
			.if [OneHitKills+ebx]
				lea ecx,[.onehitkillsoff+ebx]
				mov [OneHitKills+ebx],0
			.else
				lea ecx,[.onehitkillson+ebx]
				mov [OneHitKills+ebx],1
			.endif
			invoke _CreateThread+ebx,0,0,eax,ecx,0,0
			mov dword [edi],0
			jmp .endloop
		.endif
	.endif
      .endloop:
	jmp @b
	.buff rb 11
	.godmodeon du 'God mode ON',0
	.godmodeoff du 'God mode OFF',0
	.onehitkillson du 'One hit kills ON',0
	.onehitkillsoff du 'One hit kills OFF',0
	.giveall du 'Weapons Cheat Activaed',0
	.invisfull du 'Inventory is full',0
endp

proc _fun1 arg1,EventName,arg3,arg4 ; �������� ������� ����������
	pushad
	call .base
       .base:
	pop ebx
	sub ebx,.base
	; ������ ����������� �������
    ;	 cinvoke __wfopen+ebx,'Events.log','a'
    ;	 mov esi,eax
    ;	 lea ecx,[.format+ebx]
    ;	 cinvoke _fwprintf+ebx,eax,ecx,[EventName]
    ;	 cinvoke _fclose+ebx,esi
	; ����� �������
	.if [hModule+ebx]=0
		invoke _GetModuleHandleA+ebx,'rabbids.win32.f.dll'
		mov [hModule+ebx],eax
		lea ecx,[injHooks+ebx]
		stdcall ecx,eax
	.endif
	; ������� displayStartScreenEvent = � ����
	lea eax,[displayStartScreenEvent+ebx]
	invoke _lstrcmpW+ebx,[EventName],eax
	test eax,eax
	jne @f
	mov [InGame+ebx],0
	@@:
	; ������� setSlotPositionEvent = � ����
	lea eax,[setSlotPositionEvent+ebx]
	invoke _lstrcmpW+ebx,[EventName],eax
	test eax,eax
	jne @f
	mov [InGame+ebx],1
	mov [inventory+ebx],edi
	@@:
	; ������� displaySubtitleEvent = �� � ����
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

proc _giveweapons
	local release:DWORD

	pushad
	call .base
       .base:
	pop ebx
	sub ebx,.base
	mov ecx,.weapons_arr_size
	@@:
	push ecx
	movzx edx,[.weapons_arr+ebx+ecx-1]
	mov ecx,[inventory+ebx]
	lea eax,[_addbullets+ebx]
	stdcall eax,edx ; ��������� ��������, ���� ������ ��� ����
	.if al=0
		; ��������� ������ � ���������
		mov ecx,[inventory+ebx]
		mov eax,[hModule+ebx]
		add eax,1F38E0h
		stdcall eax,edx,255,1
		mov [release],eax
	.endif
	pop ecx
	cmp al,0
	je @f
	dec ecx
	cmp ecx,0
	ja @b
	@@:
	popad
	mov eax,[release]
	ret

	.weapons_arr db 13,15,16,19,20,17,18,4,12
	.weapons_arr_size = $-.weapons_arr
endp

proc _addbullets id
	push esi
	push edi
	push edx
	mov edi,ecx
	mov ecx,[id]
	xor eax,eax
	mov esi,dword [edi+0d8h]
	test esi,esi
	jle .m1
	lea edx,[edi+144h]
	@@:
	cmp dword [edx],ecx
	je .m1
	inc eax
	add edx,1ch
	cmp eax,esi
	jl @b
       .m1:
	cmp eax,esi
	jne .add
	xor al,al
	pop edx
	pop edi
	pop esi
	ret
     .add:
	lea ecx,[eax*8]
	sub ecx,eax
	mov dword [ecx*4+edi+148h],255
	mov al,1
	pop edx
	pop edi
	pop esi
	ret
endp

proc _godmode
	pushad
	call .base
       .base:
	pop ebx
	sub ebx,.base
	.if [GodMode+ebx]=1 ; ��� GodMode
		cmp ebp,18AD58h ; �����
		je .godmode
		cmp ebp,18AD1Ch ; �����
		je .godmode
		cmp ebp,18AD68h ; �����
		je .godmode
	.endif
	comiss xmm0,xmm1
	jb .m1 ; ������
	.if [OneHitKills+ebx]=1 ; ��� OneHitKills
		cmp dword [ebp+1ch],18AD68h ; ���� ���� ������� �����
		je .m1 ; ������� �����
	.endif
	movss dword [esi],xmm0
	jmp .m2
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
		cmp [InGame+ebx],1
		jne .release
		; ���������� �����
		push 10
		push [text]
		push 1
		lea eax,[esi+023E20h]
		call eax
		mov ecx,eax
		lea eax,[esi+12E6D0h]
		call eax
		; ��������
		invoke _Sleep+ebx,1000
		; ������� �����
		push 10
		push [text]
		push 0
		lea eax,[esi+023E20h]
		call eax
		mov ecx,eax
		lea eax,[esi+12E6D0h]
		call eax
	      .release:
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
OneHitKills db 0
inventory dd ?
player dd ?

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
		invoke MessageBoxA,0,'����� �� ������.','����',MB_ICONERROR+MB_OK
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
		; �������������� ����-���� ����
		invoke VirtualAllocEx,[pinfo.hProcess],0,_injCode_size,MEM_RESERVE + MEM_COMMIT,PAGE_EXECUTE_READWRITE
		.if eax<>0
			mov esi,eax
			stdcall InitWinApi
			invoke WriteProcessMemory,[pinfo.hProcess],esi,injThread,_injCode_size,0
			.if eax<>0
				invoke FlushInstructionCache,[pinfo.hProcess],esi,_injCode_size
				invoke VirtualProtectEx,[pinfo.hProcess],0067C340h,8,PAGE_EXECUTE_READWRITE,lpflOldProtec
				.if eax<>0
					; ���
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
		; WINAPI ������� ��� ����-����
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