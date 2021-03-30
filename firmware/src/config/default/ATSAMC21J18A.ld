/**
 * \file
 *
 * \brief Linker script for running in internal FLASH on the SAMC21J18A
 * 
 *   Section Definitions   
 *   .text for code & constants
 *   .bss for uninitialized data
 *   .stack for our stack
 *   .data for initialized data
 *
**/


OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
SEARCH_DIR(.)

/* Memory Spaces Definitions */
MEMORY
{
  rom      (rx)  : ORIGIN = 0x00000000, LENGTH = 0x00040000
  ram      (rwx) : ORIGIN = 0x20000000, LENGTH = 0x00008000
}

/* The stack size used by the application. NOTE: you need to adjust according to your application.
As the stack contains no symbols, we must explicitly reserve space for it by indicating its size. */
STACK_SIZE = DEFINED(STACK_SIZE) ? STACK_SIZE : DEFINED(__stack_size__) ? __stack_size__ : 0x2000;

/*We also must align the stack on an 8-byte boundary per ARM Procedure Call Standards (AAPCS).
https://developer.arm.com/documentation/ihi0042/j/?lang=en#procedure-call-standard-for-the-armreg-architecture*/

/* Section Definitions */
SECTIONS
{
    /*For code and constants - Stored in ROM which is part of the Flash memory*/
    .text :
    {
        . = ALIGN(4);
        _sfixed = .;
        KEEP(*(.vectors .vectors.*))
        *(.text .text.* .gnu.linkonce.t.*)
        *(.glue_7t) *(.glue_7)
        *(.rodata .rodata* .gnu.linkonce.r.*)
        *(.ARM.extab* .gnu.linkonce.armextab.*)

        /* Support C constructors, and C destructors in both user code
           and the C library. This also provides support for C++ code. */
        . = ALIGN(4);
        KEEP(*(.init))
        . = ALIGN(4);
        __preinit_array_start = .;
        KEEP (*(.preinit_array))
        __preinit_array_end = .;

        . = ALIGN(4);
        __init_array_start = .;
        KEEP (*(SORT(.init_array.*)))
        KEEP (*(.init_array))
        __init_array_end = .;

        . = ALIGN(4);
        KEEP (*crtbegin.o(.ctors))
        KEEP (*(EXCLUDE_FILE (*crtend.o) .ctors))
        KEEP (*(SORT(.ctors.*)))
        KEEP (*crtend.o(.ctors))

        . = ALIGN(4);
        KEEP(*(.fini))

        . = ALIGN(4);
        __fini_array_start = .;
        KEEP (*(.fini_array))
        KEEP (*(SORT(.fini_array.*)))
        __fini_array_end = .;

        KEEP (*crtbegin.o(.dtors))
        KEEP (*(EXCLUDE_FILE (*crtend.o) .dtors))
        KEEP (*(SORT(.dtors.*)))
        KEEP (*crtend.o(.dtors))

        . = ALIGN(4);
        _efixed = .;            /* End of text section */
    } > rom

    /* .ARM.exidx is sorted, so has to go in its own output section.  */
    PROVIDE_HIDDEN (__exidx_start = .);
    .ARM.exidx :
    {
      *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    } > rom
    PROVIDE_HIDDEN (__exidx_end = .);

    . = ALIGN(4);
    _etext = .;

    .relocate : AT (_etext)
    {
        . = ALIGN(4);
        _srelocate = .;
        *(.ramfunc .ramfunc.*);
        *(.data .data.*);
        . = ALIGN(4);
        _erelocate = .;
    } > ram

    /* .bss section we put uninitialized static memory in. .bss must be 
        reserved in the memory map, but there is nothing to load, as all 
        variables are initialized to zero.
        
        *(COMMON). This is a special input section where the compiler puts 
        global uninitialized variables that go beyond file scope. int foo; 
        goes there, while static int foo; does not. This allows the linker 
        to merge multiple definitions into one symbol if they have the 
        same name.

        We indicate that this section is not loaded with the NOLOAD property.
        This is the only section property used in modern linker scripts. */
    .bss (NOLOAD) :
    {
        . = ALIGN(4);
        _sbss = . ;
        _szero = .;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = . ;
        _ezero = .;
    } > ram

    /* Stack section is in RAM and not loaded, therefore also use NOLOAD 
    keyword. As the stack contains no symbols, we must explicitly reserve 
    space for it by indicating its size.
     */
    .stack (NOLOAD):
    {
        . = ALIGN(8);
        _sstack = .;
        . = . + STACK_SIZE;
        . = ALIGN(8);
        _stack = .;
    } > ram

    . = ALIGN(4);
    _end = . ;
}
