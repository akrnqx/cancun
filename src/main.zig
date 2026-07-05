const std = @import("std");
const efi = std.os.uefi;
const elf = std.elf;
const llog = @import("log.zig");
const arch = @import("arch.zig");

pub fn StatusResponse(comptime T: type) type {
    return struct {
        status: efi.Status,
        response: T,

        pub fn getResponse(self: @This()) T {
            return self.response;
        }

        pub fn getStatus(self: @This()) efi.Status {
            return self.status;
        }
    };
}

pub fn main() efi.Status {
    const con_out = getConout() catch {
        return .unsupported;
    };

    init_con_out(&con_out) catch {
        return .aborted;
    };

    const res = init();

    if (res.getStatus() != .success) {
        return res.getStatus();
    }

    const boot_service = res.getResponse() orelse return .aborted;

    arch.c_arch.map4kTo(
        0xFFFF_FFFF_DEAD_0000,
        0x10_0000,
        .read_write,
        boot_service,
    ) catch {
        return .aborted;
    };

    arch.c_arch.setLv4Writable(boot_service) catch {
        return .load_error;
    };

    while (true) {
        asm volatile ("hlt");
    }

    return .success;
}

fn getConout() !efi.protocol.SimpleTextOutput {
    const con_out = efi.system_table.con_out orelse return error.unsupported;
    return con_out.*;
}

fn init_con_out(con_out: *efi.protocol.SimpleTextOutput) !void {
    try con_out.reset(false);
    llog.init(con_out);
}

pub fn init() StatusResponse(?*efi.tables.BootServices) {
    const boot_service = efi.system_table.boot_services orelse {
        llog.log(.err, "failed to get boot services", .{});
        return .{
            .response = null,
            .status = .aborted,
        };
    };

    const fs_optional = boot_service.locateProtocol(efi.protocol.SimpleFileSystem, null) catch |err| {
        llog.log(.err, "locate protocol failed with {}", .{err});
        return .{ .response = boot_service, .status = .aborted };
    };

    var fs: *efi.protocol.SimpleFileSystem = fs_optional orelse {
        llog.log(.err, "locate protocol is null", .{});
        return .{ .response = boot_service, .status = .aborted };
    };

    const root_dir: *efi.protocol.File = fs.openVolume() catch |err| {
        llog.log(.err, "could not open volume {}", .{err});
        return .{ .response = boot_service, .status = .aborted };
    };

    const kernel = openFile(root_dir, "CAB.ELF") catch return .aborted;
    const header_size: usize = @sizeOf(elf.Elf64_Ehdr);
    var header_buffer: []align(8) u8 = boot_service.allocatePool(.loader_data, header_size) catch {
        llog.log(.err, "Failed to allocate memory for kernel ELF header.", .{});
        return .{ .response = boot_service, .status = .aborted };
    };

    const b_read = kernel.read(header_buffer) catch {
        llog.log(.err, "Failed to read kernel ELF header.", .{});
        return .{ .response = boot_service, .status = .aborted };
    };

    var fixed_reader = std.Io.Reader.fixed(header_buffer[0..b_read]);
    const elf_header = elf.Header.read(&fixed_reader) catch |err| {
        llog.log(.err, "Failed to parse kernel ELF header: {}", .{err});
        return .{ .response = boot_service, .status = .aborted };
    };

    _ = elf_header;

    return .{
        .response = boot_service,
        .status = .success,
    };
}

fn openFile(
    root: *efi.protocol.File,
    comptime name: [:0]const u8,
) !*efi.protocol.File {
    const file_ucs2 = std.unicode.utf8ToUtf16LeStringLiteral(name);

    const file: *efi.protocol.File = root.open(file_ucs2, efi.protocol.File.OpenMode.read, .{}) catch |err| {
        llog.log(.err, "Failed to open file: {s}: {}", .{ name, err });
        return error.Aborted;
    };

    return file;
}
