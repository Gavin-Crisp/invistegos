pub const DmTarget = extern struct {
    table: ?*DmTable,
    type: ?*TargetType,
    begin: u64,
    len: u64,
    max_io_len: u32,
    num_flush_bios: c_uint,
    num_discard_bios: c_uint,
    num_secure_erase_bios: c_uint,
    num_write_zeroes_bios: c_uint,
    per_io_data_size: c_uint,
    private: ?*anyopaque,
    @"error": [*:0]c_char,
    flags: Flags,

    pub const Flags = packed struct(u16) {
        flush_supported: bool,
        discards_supported: bool,
        zone_reset_all_supported: bool,
        max_discard_granuality: bool,
        limit_swap_bios: bool,
        emulate_zone_append: bool,
        accounts_remapped_io: bool,
        needs_bio_set_dev: bool,
        flush_bypasses_map: bool,
        mempool_needs_integrity: bool,
        __padding: u6,
    };
};

pub const DmTable = opaque {};
pub const TargetType = opaque {};
pub const DmDev = opaque {};

pub const Bio = extern struct {
    next: ?*Bio,
    bdev: ?*BlockDevice,
    opf: BlkOpf,
    flags: c_ushort,
    ioprio: c_ushort,
    write_hint: RwHint,
    write_stream: u8,
    status: BlkStatus,
    bvec_gap_bit: u8,
    __remaining: Atomic,
    io_vec: ?[*]BioVec,
    iter: BvecIter,
    // TODO: name
    unnamed: extern union {
        cookie: BlkQc,
        __nr_segments: c_uint,
    },
    end_io: ?*BioEndIo,
    private: ?*anyopaque,
    /// WARNING: The position or existence of this field is
    /// dependant on config flags that are not known. Use at risk.
    blkg: ?*BlkcgGq,
    /// WARNING: The position or existence of this field is
    /// dependant on config flags that are not known. Use at risk.
    issue_time_ns: u64,
    /// WARNING: The position or existence of this field is
    /// dependant on config flags that are not known. Use at risk.
    iocost_cost: u64,
    /// WARNING: The position or existence of this field is
    /// dependant on config flags that are not known. Use at risk.
    crypt_context: ?*BioCryptCtx,
    /// WARNING: The position or existence of this field is
    /// dependant on config flags that are not known. Use at risk.
    integrity: ?*BioIntegrityPayload,
    /// WARNING: The position or existence of this field is
    /// dependant on config flags that are not known. Use at risk.
    vcnt: c_ushort,
    /// WARNING: The position or existence of this field is
    /// dependant on config flags that are not known. Use at risk.
    max_vecs: c_ushort,
    /// WARNING: The position or existence of this field is
    /// dependant on config flags that are not known. Use at risk.
    __cnt: Atomic,
    /// WARNING: The position or existence of this field is
    /// dependant on config flags that are not known. Use at risk.
    pool: ?*BioSet,
};

pub const BlockDevice = opaque {};
pub const BlkOpf = u32;

pub const RwHint = enum(u8) {
    write_life_not_set = 0,
    write_life_none = 1,
    write_life_short = 2,
    write_life_medium = 3,
    write_life_long = 4,
    write_life_extreme = 5,
    write_life_hint_nr,
};

pub const BlkStatus = enum(u8) {
    ok = 0,
    not_supp = 1,
    timeout = 2,
    no_spc = 3,
    transport = 4,
    target = 5,
    resv_conflict = 6,
    medium = 7,
    protection = 8,
    resource = 9,
    ioerr = 10,
    dm_requeue = 11,
    again = 12,
    dev_resource = 13,
    open_resource = 14,
    active_resource = 15,
    offline = 16,
    duration_limit = 17,
    inval = 19,
};

pub const Atomic = extern struct {
    counter: c_int,
};

pub const BioVec = extern struct {
    page: ?*Page,
    len: c_uint,
    offset: c_uint,
};

pub const Page = opaque {};

pub const BvecIter = extern struct {
    sector: u64,
    size: c_uint,
    idx: c_uint,
    bvec_done: c_uint,
};

pub const BlkQc = c_uint;
pub const BioEndIo = opaque {};
pub const BlkcgGq = opaque {};
pub const BioCryptCtx = opaque {};
pub const BioIntegrityPayload = opaque {};
pub const BioSet = opaque {};

pub const printk = @extern(fn ([*:0]const c_char, ...) c_int, .{ .name = "_printk" });
pub const dmGetDevice = @extern(fn (*DmTarget, [*:0]const c_char, BlkMode, **DmDev) c_int, .{ .name = "dm_get_device" });
pub const dmPutDevice = @extern(fn (*DmTarget, *DmDev) void, .{ .name = "dm_put_device" });
pub const dmTableGetMode = @extern(fn (*DmTable) BlkMode, .{ .name = "dm_tabe_get_mode" });
pub const dmTargetOffset = @extern(fn (*DmTable) BlkMode, .{ .name = "dm_tabe_get_mode" });

pub const BlkMode = c_int;

