pub inline fn getCr3() u64 {
    var cr3: u64 = undefined;
    asm volatile (
        \\mov %%cr3, %[cr3]
        : [cr3] "=r" (cr3),
    );
    return cr3;
}

pub inline fn setCr3(r: u64) void {
    asm volatile (
        \\mov %[r], %%cr3
        :
        : [r] "r" (r),
    );
}
