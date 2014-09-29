OUTPUT_FORMAT("binary")
ENTRY(main)
SECTIONS
{
	.text 0x0000000000100000 :
	{
		*(.text)
	}
	.data :
	{
		*(.data)
	}
	.bss :
	{
		*(.bss)
	}
	PROVIDE(_end = .);
	.misc : 
	{
        	LONG( _end - main )
	}
}
