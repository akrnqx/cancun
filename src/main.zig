const std = @import("std");
const efi = std.os.uefi;
const elf = std.elf;
const llog = @import("log.zig");

pub fn main() efi.Status {
    const con_out = efi.system_table.con_out orelse return efi.Status.unsupported;

    con_out.reset(false) catch {
        return .unsupported;
    };

    llog.init(con_out);

    const boot_service = efi.system_table.boot_services orelse {
        llog.log(.err, "failed to get boot services", .{});
        return .aborted;
    };

    const fs_optional = boot_service.locateProtocol(efi.protocol.SimpleFileSystem, null) catch |err| {
        llog.log(.err, "locate protocol failed with {}", .{err});
        return .aborted;
    };

    var fs: *efi.protocol.SimpleFileSystem = fs_optional orelse {
        llog.log(.err, "locate protocol is null", .{});
        return .aborted;
    };

    const root_dir: *efi.protocol.File = fs.openVolume() catch |err| {
        llog.log(.err, "could not open volume {}", .{err});
        return .aborted;
    };

    const kernel = openFile(root_dir, "cab.elf") catch return .aborted;
    const header_size: usize = @sizeOf(elf.Elf64_Ehdr);
    var header_buffer: []align(8) u8 = boot_service.allocatePool(.loader_data, header_size) catch {
        llog.log(.err, "Failed to allocate memory for kernel ELF header.", .{});
        return .aborted;
    };

    const b_read = kernel.read(header_buffer) catch {
        llog.log(.err, "Failed to read kernel ELF header.", .{});
        return .aborted;
    };

    var fixed_reader = std.Io.Reader.fixed(header_buffer[0..b_read]);
    const elf_header = elf.Header.read(&fixed_reader) catch |err| {
        llog.log(.err, "Failed to parse kernel ELF header: {}", .{err});
        return .aborted;
    };

    llog.log(
        .debug,
        \\Kernel ELF information:
        \\  Entry Point         : 0x{X}
        \\  Is 64-bit           : {d}
        \\  # of Program Headers: {d}
        \\  # of Section Headers: {d}
    ,
        .{
            elf_header.entry,
            @intFromBool(elf_header.is_64),
            elf_header.phnum,
            elf_header.shnum,
        },
    );

    while (true) {
        asm volatile ("hlt");
    }

    return .success;
}

inline fn toUcs2(comptime s: [:0]const u8) [s.len:0]u16 {
    var ucs2: [s.len:0]u16 = undefined;
    for (s, 0..) |c, i| {
        ucs2[i] = c;
    }
    return ucs2;
}

fn openFile(
    root: *efi.protocol.File,
    comptime name: [:0]const u8,
) !*efi.protocol.File {
    const file: *efi.protocol.File = root.open(
        &toUcs2(name),
        efi.protocol.File.OpenMode.read,
        .{},
    ) catch |err| {
        llog.log(.err, "Failed to open file: {s}: {}", .{ name, err });
        return error.Aborted;
    };
    return file;
}
