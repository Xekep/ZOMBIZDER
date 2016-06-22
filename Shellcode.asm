_injCode_begin:
proc KeyboardSniffer arg
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

proc _fun1 arg1,EventName,arg3,arg4 ; Перехват событий интерфейса
	pushad
	call .base
       .base:
	pop ebx
	sub ebx,.base
	; Регион логирования событий
	;cinvoke __wfopen+ebx,'Events.log','a'
	;mov esi,eax
	;lea ecx,[.format+ebx]
	;cinvoke _fwprintf+ebx,eax,ecx,[EventName]
	;cinvoke _fclose+ebx,esi
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
	mov [inventory+ebx],edi
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
	mov eax,005F7810h
	call eax
	mov ecx,0067C778h ; Прыжок на MOV ECX,DWORD PTR SS:[EBP+8] (Сплайсинг)
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
	; Сплайсинг функции отвечающей за урон
	; Сигнатура 0F 2F C1 72 0A F3 0F 11 06 5E 5B 5D C2 0C 00 F3 0F 11 0E 5E 5B 5D C2 0C 00
	add [hModule],255369h
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
	stdcall eax,edx ; Добавляем патронов, если оружие уже есть
	.if al=0
		; Добавляем оружие в инвентарь
		mov ecx,[inventory+ebx]
		mov eax,[hModule+ebx]
		add eax,1F3720h ; Сигнатура 5F 33 C0 5B 8B E5 5D C2 10 00 CC CC CC CC CC CC CC CC 55 8B EC 83 EC 40
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

	.weapons_arr db 13,15,16,19,20,17,18,4,12,82
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
	.if [GodMode+ebx]=1 ; Чит GodMode
		; Регион логирования
		;cinvoke __wfopen+ebx,'Damage.log','a'
		;mov esi,eax
		;cinvoke _fprintf+ebx,eax,"%#08X",ebp
		;cinvoke _fclose+ebx,esi
		; Конец региона
		cmp ebp,18AD58h ; Игрок ?
		je .godmode
		cmp ebp,18AD1Ch ; Игрок ?
		je .godmode
		cmp ebp,18AD68h ; Игрок ?
		je .godmode
	.endif
	comiss xmm0,xmm1
	jb .m1 ; Смерть
	.if [OneHitKills+ebx]=1 ; Чит OneHitKills
		cmp dword [ebp+1ch],18AD68h ; Если урон наносит игрок ?
		je .m1 ; Убиваем зомби
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
		; Показываем текст
		push 10
		push [text]
		push 1
		lea eax,[esi+241F0h] ; Сигнатура 8B 40 44 8B 80 08 05 00 00 C3 33 C0 8B 80 08 05 00 00 C3 33 C0 C3
		call eax
		mov ecx,eax
		lea eax,[esi+12E530h] ; Сигнатура CC CC 55 8B EC 81 EC B8 00 00 00 83 CA FF 53
		call eax
		; Засыпаем
		invoke _Sleep+ebx,1000
		; Убираем текст
		push 10
		push [text]
		push 0
		lea eax,[esi+241F0h] ; Сигнатура 8B 40 44 8B 80 08 05 00 00 C3 33 C0 8B 80 08 05 00 00 C3 33 C0 C3
		call eax
		mov ecx,eax
		lea eax,[esi+12E530h] ; Сигнатура CC CC 55 8B EC 81 EC B8 00 00 00 83 CA FF 53
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
_fprintf dd ?
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

_injCode_size = $-_injCode_begin