const builtin = @import("builtin");
pub const c_arch = switch (builtin.target.cpu.arch) {
    .x86_64 => @import("arch/x86/arch.zig"),
    else => @compileError("architecture not supported"),
};
