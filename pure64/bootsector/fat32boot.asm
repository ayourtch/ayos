; This is an LBA-enabled FreeDOS FAT32 boot sector (single sector!).
; You can use and copy source code and binaries under the terms of the
; GNU Public License (GPL), version 2 or newer. See www.gnu.org for more.

; Based on earlier work by FreeDOS kernel hackers, modified heavily by
; Eric Auer and Jon Gentle in 7 / 2003.
;
; Edited for Pure64 by Ian Seyler (iseyler@gmail.com)
;
; Description : Loads the file in 'filename' to the memory address 0x0000:0x8000
; Only works with FAT32 filesystems
;
; For more information about this code please see the original at:
; http://freedos.svn.sourceforge.net/viewvc/freedos/kernel/trunk/boot/boot32lb.asm?view=markup


[BITS 16]
[ORG 0x7c00]		; this is a boot sector

start:
	jmp	short real_start
	nop

;       bp is initialized to 7c00h

%define bsOemName		bp+0x03 	; OEM label (8)
%define bsBytesPerSec	bp+0x0b 	; bytes/sector (dw)
%define bsSecPerClust	bp+0x0d 	; sectors/allocation unit (db)
%define bsResSectors	bp+0x0e 	; # reserved sectors (dw)
%define bsFATs			bp+0x10 	; # of fats (db)
%define bsRootDirEnts	bp+0x11 	; # of root dir entries (dw, 0 for FAT32)
									; (FAT32 has root dir in a cluster chain)
%define bsSectors		bp+0x13 	; # sectors total in image (dw, 0 for FAT32)
									; (if 0 use nSectorHuge even if FAT16)
%define bsMedia 		bp+0x15 	; media descriptor: fd=2side9sec, etc... (db)
%define sectPerFat		bp+0x16 	; # sectors in a fat (dw, 0 for FAT32)
									; (FAT32 always uses xsectPerFat)
%define sectPerTrack	bp+0x18 	; # sectors/track
%define nHeads			bp+0x1a 	; # heads (dw)
%define nHidden 		bp+0x1c 	; # hidden sectors (dd)
%define nSectorHuge		bp+0x20 	; # sectors if > 65536 (dd)
%define xsectPerFat		bp+0x24 	; Sectors/Fat (dd)
									; +0x28 dw flags (for fat mirroring)
									; +0x2a dw filesystem version (usually 0)
%define xrootClst		bp+0x2c 	; Starting cluster of root directory (dd)
									; +0x30 dw -1 or sector number of fs.-info sector
									; +0x32 dw -1 or sector number of boot sector backup
									; (+0x34 .. +0x3f reserved)
%define drive			bp+0x40 	; Drive number
;41h Unused (Could be High Byte of Previous Entry) 1 Byte
;42h Extended Signature (29h) 1 Byte
;43h Serial Number of Partition 1 Double Word
;47h Volume Name of Partition 11 Bytes
;52h FAT Name (FAT32) 8 Bytes
;5Ah Executable Code 420 Bytes
;1FEh Boot Record Signature (55h AAh) 2 Bytes




%define loadsegoff_60	bp+loadseg_off-start

%define LOADSEG 	0x0800	; 0x0800:0x0000 == 0x0000:0x8000

%define FATSEG		0x2000

%define fat_secshift	fat_afterss-1	; each fat sector describes 2^??
%define fat_sector	bp+0x44 	; last accessed FAT sector (dd)
%define fat_start	bp+0x48 	; first FAT sector (dd)
%define data_start	bp+0x4c 	; first data sector (dd)

		times	0x5a-$+$$ db 0
		; not used: [0x42] = byte 0x29 (ext boot param flag)
		; [0x43] = dword serial
		; [0x47] = label (padded with 00, 11 bytes)
		; [0x52] = "FAT32",32,32,32 (not used by Windows)
		; ([0x5a] is where FreeDOS parts start)

;-----------------------------------------------------------------------
; ENTRY
;-----------------------------------------------------------------------

real_start:
	cld
	cli
	sub	ax, ax
	mov	ds, ax
	mov	bp, 0x7c00

	mov	ax, 0x1FE0
	mov	es, ax
	mov	si, bp
	mov	di, bp
	mov	cx, 0x0100
	rep	movsw		; move boot code to the 0x1FE0:0x0000
	jmp	word 0x1FE0:cont

loadseg_off	dw	0, LOADSEG

; -------------

cont:
	mov	ds, ax
	mov	ss, ax		; stack and BP-relative moves up, too
	lea sp, [bp-0x20]
	sti
	mov	[drive], dl	; BIOS passes drive number in DL

	mov	si, msg_LoadFreeDOS
	call print		; modifies AX BX SI


; -------------
;       CALCPARAMS: figure out where FAT and DATA area starts
;       (modifies EAX EDX, sets fat_start and data_start variables)

calc_params:
	xor	eax, eax
	mov	[fat_sector], eax	; init buffer status

	; first, find fat_start:
	mov	ax, [bsResSectors]	; no movzx eax, word... needed
	add	eax, [nHidden]
	mov [fat_start], eax	; first FAT sector
	mov	[data_start], eax	; (only first part of value)

	; next, find data_start:
	mov	eax, [bsFATs]		; no movzx ... byte needed:
	; the 2 dw after the bsFATs db are 0 by FAT32 definition :-).
	imul	dword [xsectPerFat]	; (also changes edx)
	add	[data_start], eax	; first DATA sector

	; finally, find fat_secshift:
	mov	ax, 512 ; default sector size (means default shift)
				; shift = log2(secSize) - log2(fatEntrySize)
fatss_scan:
	cmp	ax, [bsBytesPerSec]
	jz	fatss_found
	add	ax,ax
	inc	word [fat_secshift]	;XXX    ; initially 9-2 (byte!)
	jmp short fatss_scan	; try other sector sizes
fatss_found:


; -------------
; FINDFILE:     Searches for the file in the root directory.
; Returns:      EAX = first cluster of file

	mov	eax, [xrootClst]	; root dir cluster

ff_next_clust:
	push eax			; save cluster
	call convert_cluster
	jc	boot_error		; EOC encountered
	; EDX is clust/sector, EAX is sector

ff_next_sector:
	les	bx, [loadsegoff_60]	; load to loadseg:0
	call readDisk
	xor	di, di			;XXX

; Search for KERNEL.SYS file name, and find start cluster.
ff_next_entry:
	mov	cx, 11
	mov	si, filename
	repe cmpsb
	jz ff_done		; note that di now is at dirent+11

	add	di, byte 0x20		;XXX
	and	di, byte -0x20 ; 0xffe0 ;XXX
	cmp	di, [bsBytesPerSec]	;XXX
	jnz	ff_next_entry

	dec dx		; next sector in cluster
	jnz	ff_next_sector

ff_walk_fat:
	pop	eax			; restore current cluster
	call next_cluster		; find next cluster
	jmp	ff_next_clust

ff_done:
	push word [es:di+0x14-11]	; get cluster number HI
	push word [es:di+0x1A-11]	; get cluster number LO
	pop	eax			; convert to 32bit

	sub	bx, bx			; ES points to LOADSEG
						; (kernel -> ES:BX)

; -------------

read_kernel:
	push eax
	call convert_cluster
	jc	boot_success		; EOC encountered - done
	; EDX is sectors in cluster, EAX is sector

rk_in_cluster:
	call readDisk
	dec	dx
	jnz	rk_in_cluster		; loop over sect. in cluster

rk_walk_fat:
	pop	eax
	call next_cluster
	jmp	read_kernel
	
;-----------------------------------------------------------------------

boot_success:
	mov	bl, [drive]
	jmp	0x0000:0x8000
	
;-----------------------------------------------------------------------

boot_error:
	mov	si, msg_BootError
	call print			; modifies AX BX SI

wait_key:
	xor	ah,ah
	int	0x16			; wait for a key
reboot:
	int	0x19			; reboot the machine

;-----------------------------------------------------------------------

; given a cluster number, find the number of the next cluster in
; the FAT chain. Needs fat_secshift and fat_start.
; input:        EAX - cluster
; output:       EAX - next cluster

next_cluster:
	push es
	push di
	push bx

	mov	di, ax
	shl	di, 2			; 32bit FAT

	push ax
	mov	ax, [bsBytesPerSec]
	dec	ax
	and	di, ax			; mask to sector size
	pop	ax

	shr	eax, 7			; e.g. 9-2 for 512 by/sect.
fat_afterss:
	; selfmodifying code: previous byte is patched!
	; (to hold the fat_secshift value)

	add	eax, [fat_start]	; absolute sector number now

	mov	bx, FATSEG
	mov	es, bx
	sub	bx, bx

	cmp	eax, [fat_sector]	; already buffered?
	jz cn_buffered
	mov	[fat_sector],eax	; number of buffered sector
	call readDisk

cn_buffered:
	and	byte [es:di+3],0x0f	; mask out top 4 bits
	mov	eax, [es:di]		; read next cluster number

	pop	bx
	pop di
	pop	es
	ret


;-----------------------------------------------------------------------
; Convert cluster number to the absolute sector number
; ... or return carry if EndOfChain! Needs data_start.
; input:        EAX - target cluster
; output:       EAX - absolute sector
;               EDX - [bsSectPerClust] (byte)
;               carry clear
;               (if carry set, EAX/EDX unchanged, end of chain)

convert_cluster:
	cmp	eax, 0x0ffffff8 ; if end of cluster chain...
	jnb	end_of_chain

	; sector = (cluster-2) * clustersize + data_start
	dec	eax
	dec	eax

	movzx edx, byte [bsSecPerClust]
	push edx
	mul	edx
	pop	edx
	add	eax, [data_start]
	; here, carry is unset (unless parameters are wrong)
	ret

end_of_chain:
	stc			; indicate EOC by carry
	ret

;-----------------------------------------------------------------------
; PRINT - prints string DS:SI
; modifies AX BX SI

printchar:
	xor	bx, bx		; video page 0
	mov	ah, 0x0e	; print it
	int	0x10		; via TTY mode
print:
	lodsb			; get token
	cmp	al, 0		; end of string?
	jne	printchar	; until done
	ret				; return to caller

;-----------------------------------------------------------------------
; Read a sector from disk, using LBA
; input:        EAX - 32-bit DOS sector number
;               ES:BX - destination buffer
;               (will be filled with 1 sector of data)
; output:       ES:BX points one byte after the last byte read.
;               EAX - next sector

readDisk:
	push dx
	push si
	push di

read_next:
	push eax	; would ax be enough?
	mov	di, sp	; remember parameter block end

	push byte 0		;XXX    ; other half of the 32 bits at [C]
					; (did not trust "o32 push byte 0" opcode)
	push byte 0		; [C] sector number high 32bit
	push eax		; [8] sector number low 32bit
	push es 		; [6] buffer segment
	push bx 		; [4] buffer offset
	push byte 1		; [2] 1 sector (word)
	push byte 16	; [0] size of parameter block (word)
	mov	si, sp
	mov	dl, [drive]
	mov	ah, 42h ; disk read
	int	0x13	

	mov	sp, di		; remove parameter block from stack
					; (without changing flags!)
	pop	eax			; would ax be enough?

	jnc	read_ok 	; jump if no error

	push ax 		; !!
	xor	ah, ah		; else, reset and retry
	int	0x13
	pop	ax			; !!
	jmp	read_next

read_ok:
	inc eax 		; next sector
	add	bx, word [bsBytesPerSec]
	jnc	no_incr_es		; if overflow...

	mov	dx, es
	add	dh, 0x10		; ...add 1000h to ES
	mov	es, dx

no_incr_es:
	pop	di
	pop si
	pop	dx
	ret


;-----------------------------------------------------------------------

msg_LoadFreeDOS db "Loading... ",0

	times 0x01ee-$+$$ db 0

msg_BootError	db "No "
		; currently, only "kernel.sys not found" gives a message,
		; but read errors in data or root or fat sectors do not.

filename	db "PURE64  SYS"

sign		dw 0x0000, 0xAA55
