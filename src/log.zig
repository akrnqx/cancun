const std = @import("std");
const option = @import("option");
const llevel = option.log_level;
const Level = std.log.Level;
const efi = std.os.uefi;
const Sto = efi.protocol.SimpleTextOutput;

var con_out: *Sto = undefined;

pub fn init(out: *Sto) void {
    con_out = out;
}

pub fn log(
    comptime level: Level,
    comptime fmt: []const u8,
    args: anytype,
) void {
    // basic log function

    if (!shouldLog(level)) return;

    const level_str = comptime switch (level) {
        .debug => "[DEBUG]",
        .info => "[INFO]",
        .warn => "[WARN]",
        .err => "[ERROR]",
    };
    var buf: [128]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, level_str ++ " " ++ fmt, args) catch {
        return;
    };

    _ = write(msg);
}

fn write(bytes: []const u8) usize {
    for (bytes) |b| {
        _ = con_out.outputString(&[_:0]u16{b}) catch unreachable;
    }
    return bytes.len;
}

fn shouldLog(comptime arglevel: Level) bool {
    const set_level = switch (llevel) {
        .debug => 0,
        .info => 1,
        .warn => 2,
        .err => 3,
    };

    const message_level = comptime switch (arglevel) {
        .debug => 0,
        .info => 1,
        .warn => 2,
        .err => 3,
    };

    return set_level <= message_level;
}
