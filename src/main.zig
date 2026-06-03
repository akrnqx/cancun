const std = @import("std");
const efi = std.os.uefi;

const bootf = @import("boot.zig");

pub fn main() efi.Status {
    const s = efi.system_table.con_out orelse return efi.Status.unsupported;

    s.reset(false) catch {
        return efi.Status.unsupported;
    };

    switch (bootf.bootmsg()) {
        .success => {},
        .no_response => {},
        else => return .aborted,
    }

    while (true) {
        asm volatile ("hlt");
    }

    return .success;
}
