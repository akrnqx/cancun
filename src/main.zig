const std = @import("std");
const efi = std.os.uefi;

const bootf = @import("boot.zig");

// pub fn panic(msg: []const u8, ert: ?*std.builtin.StackTrace, ret_a: ?usize) noreturn {
//     _ = msg;
//     _ = ert;
//     _ = ret_a;
//
//     while (true) {}
// }

pub fn main() efi.Status {
    // const s = efi.system_table.con_out orelse return efi.Status.unsupported;
    //
    // s.reset(false) catch {
    //     return efi.Status.unsupported;
    // };
    //
    // _ = s.outputString(&[_:0]u16{ 'H', 'e', 'l', 'l', 'o', ' ', 'f', 'r', 'o', 'm', ' ', 'Z', 'i', 'g', '\n' }) catch {
    //     return efi.Status.unsupported;
    // };

    // this should run hlt and after do a mp back to the adress of hlt
    switch (bootf.bootmsg()) {
        .success => {},
        else => return .aborted,
    }

    while (true) {
        asm volatile ("hlt");
    }
    return .success;
}
