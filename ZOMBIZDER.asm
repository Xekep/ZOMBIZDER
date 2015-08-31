format pe gui 4.0
include '%fasm_inc%\include\win32ax.inc'

.data
pinfo PROCESS_INFORMATION
sinfo STARTUPINFO
lpflOldProtec dd ?
ZombiPath db '%s/steamapps/common/ZOMBI/',0
ZombiExe db 'ZOMBI.EXE',0
SteamOverlayExe db 'GameOverlayUI.exe',0
RegSubKey db 'Software\Valve\Steam',0
RegKey db 'SteamPath',0
byte1 db 0ebh
byte2 db 0c3h,90h
byte3 db 88h
SteamPath rb 512
StartPath rb 512
HKey dd ?
sz dd 512
steam db 0

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
	.else
		invoke MessageBoxA,0,'Стимопуть не найден.','Ирар',MB_ICONERROR+MB_OK
		jmp .exit
	.endif
	invoke lstrcatA,StartPath,ZombiExe
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
		invoke ResumeThread,[pinfo.hThread]
		invoke CloseHandle,[pinfo.hThread]
		invoke CloseHandle,[pinfo.hProcess]
	.endif
       .exit:
	invoke ExitProcess,0
.end start