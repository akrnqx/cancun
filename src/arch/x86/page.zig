const TableLevel = enum {
    lv4,
    lv3,
    lv2,
    lv1,
};

fn EntryBase(tl: TableLevel) type {
    return packed struct(u64) {
        const Self = @This();
        const level = tl;

        present: bool = true,
        rw: bool,
        us: bool,
        pwt: bool = false,
        pcd: bool = false,
        accessed: bool = false,
        dirty: bool = false,
        ps: bool,
        global: bool = true,
        _ignored1: u2 = 0,
        restart: bool = false,
        phys: u51,
        xd: bool = false,

        pub const Phys = u64;
        pub const Virt = u64;

        pub inline fn address(self: Self) Phys {
            return @as(u64, @intCast(self.phys)) << 12;
        }

        pub fn newMapPage(phys: Phys, present: bool) Self {
            if (level == .lv4) @compileError("understand");
            return Self{
                .present = present,
                .rw = true,
                .us = false,
                .ps = true,
                .phys = @truncate(phys >> 12),
            };
        }

        const TypeDec = switch (level) {
            .lv4 => Lv3Entry,
            .lv3 => Lv2Entry,
            .lv2 => Lv1Entry,
            .lv1 => struct {},
        };

        pub fn newMapTable(table: [*]TypeDec, present: bool) Self {
            if (level == .lv1) @compileError("lv1  cannot be dec");
            return Self{
                .present = present,
                .rw = true,
                .us = false,
                .ps = false,
                .phys = @truncate(@intFromPtr(table) >> 12),
            };
        }
    };
}

const Lv4Entry = EntryBase(.lv4);
const Lv3Entry = EntryBase(.lv3);
const Lv2Entry = EntryBase(.lv2);
const Lv1Entry = EntryBase(.lv1);
