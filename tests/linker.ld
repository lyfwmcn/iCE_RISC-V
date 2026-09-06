ENTRY(_start)

SECTIONS
{
    . = 0x0;

    .text :
    {
        *(.text)
    }

    . = 0x200;

    .text.system :
    {
        *(.text.system)
    }
}
