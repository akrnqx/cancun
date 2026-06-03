export fn kernel_entry() callconv(.naked) noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}
