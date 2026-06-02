const std = @import("std");
const efi = std.os.uefi;
const Sto = efi.protocol.SimpleTextOutput;

var con_out: *Sto = undefined;

pub fn init(out: *Sto) void {
    con_out = out;
}

pub fn log(
    comptime fmt: []const u8,
    args: anytype,
) efi.Status {
    var buf: [128]u8 = undefined;
    // this should be used to format the string in a way we want
    const msg = std.fmt.bufPrint(&buf, fmt, args) catch {
        return .buffer_too_small;
    };
    const b_wrote = write(msg);

    return switch (b_wrote) {
        0 => .aborted,
        else => .success,
    };
}

fn write(bytes: []const u8) usize {
    for (bytes) |b| {
        _ = con_out.outputString(&[_:0]u16{b}) catch unreachable;
    }
    return bytes.len;
}
