ENTRY(_start)

SECTIONS
{
    . = 0x0;

    .text :
    {
        *(.text.boot)
        *(.text*)
    }

    .rodata : ALIGN(16)
    {
        *(.rodata*)
    }

    .data : ALIGN(16)
    {
        *(.data*)
    }

    .bss : ALIGN(16)
    {
        *(.bss*)
        *(COMMON)
    }

    . = ALIGN(16);
    . += 1K;
    stack_top = .;
}
