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
    };
}

const Lv4Entry = EntryBase(.lv4);
const Lv3Entry = EntryBase(.lv3);
const Lv2Entry = EntryBase(.lv2);
const Lv1Entry = EntryBase(.lv1);
