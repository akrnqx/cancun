const std = @import("std");
const efi = std.os.uefi;
const llog = @import("log.zig");

pub fn bootmsg() efi.Status {
    const con_out = efi.system_table.con_out orelse return .aborted;

    con_out.clearScreen() catch unreachable;

    con_out.reset(false) catch unreachable;
    llog.init(con_out);
    switch (llog.log("hello cancun {} \n", .{64})) {
        .success => {},
        else => return .aborted,
    }

    return .success;
}
