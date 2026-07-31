const std = @import("std");
const linux = @import("linux.zig");

pub const k_alloc = struct {
    const Allocator = std.mem.Allocator;
    const Alignment = std.mem.Alignment;

    fn alloc(_: *anyopaque, len: usize, _: Alignment, _: usize) ?[*]u8 {
        return @ptrCast(linux.kernelMalloc(len));
    }

    fn remap(_: *anyopaque, memory: []u8, _: Alignment, new_len: usize, _: usize) ?[*]u8 {
        return @ptrCast(linux.kernelRealloc(memory.ptr, new_len));
    }

    fn free(_: *anyopaque, memory: []u8, _: Alignment, _: usize) void {
        linux.kernelFree(memory.ptr);
    }

    const vtable: Allocator.VTable = .{
        .alloc = alloc,
        .resize = Allocator.noResize,
        .remap = remap,
        .free = free,
    };

    pub const allocator: Allocator = .{
        .ptr = undefined,
        .vtable = &vtable,
    };
}.allocator;

pub const LinuxErr = struct {
    pub const perm = 1; // Operation not permitted
    pub const noent = 2; // No such file or directory
    pub const srch = 3; // No such process
    pub const intr = 4; // Interrupted system call
    pub const io = 5; // I/O error
    pub const nxio = 6; // No such device or address
    pub const too_big = 7; // Argument list too long
    pub const noexec = 8; // Exec format error
    pub const badf = 9; // Bad file number
    pub const child = 10; // No child processes
    pub const again = 11; // Try again
    pub const nomem = 12; // Out of memory
    pub const acces = 13; // Permission denied
    pub const fault = 14; // Bad address
    pub const notblk = 15; // Block device required
    pub const busy = 16; // Device or resource busy
    pub const exist = 17; // File exists
    pub const xdev = 18; // Cross-device link
    pub const nodev = 19; // No such device
    pub const notdir = 20; // Not a directory
    pub const isdir = 21; // Is a directory
    pub const inval = 22; // Invalid argument
    pub const nfile = 23; // File table overflow
    pub const mfile = 24; // Too many open files
    pub const notty = 25; // Not a typewriter
    pub const txtbsy = 26; // Text file busy
    pub const fbig = 27; // File too large
    pub const nospc = 28; // No space left on device
    pub const spipe = 29; // Illegal seek
    pub const rofs = 30; // Read-only file system
    pub const mlink = 31; // Too many links
    pub const pipe = 32; // Broken pipe
    pub const dom = 33; // Math argument out of domain of func
    pub const range = 34; // Math result not representable
    pub const deadlk = 35; // Resource deadlock would occur
    pub const nametoolong = 36; // File name too long
    pub const nolck = 37; // No record locks available
// This error code is special: arch syscall entry code will return
// -ENOSYS if users try to call a syscall that doesn't exist.  To keep
// failures of syscalls that really do exist distinguishable from
// failures due to attempts to use a nonexistent syscall, syscall
// implementations should refrain from returning -ENOSYS.
    pub const nosys = 38; // Invalid system call number
    pub const notempty = 39; // Directory not empty
    pub const loop = 40; // Too many symbolic links encountered
    pub const wouldblock = again; // Operation would block
    pub const nomsg = 42; // No message of desired type
    pub const idrm = 43; // Identifier removed
    pub const chrng = 44; // Channel number out of range
    pub const l2nsync = 45; // Level 2 not synchronized
    pub const l3hlt = 46; // Level 3 halted
    pub const l3rst = 47; // Level 3 reset
    pub const lnrng = 48; // Link number out of range
    pub const unatch = 49; // Protocol driver not attached
    pub const nocsi = 50; // No CSI structure available
    pub const l2hlt = 51; // Level 2 halted
    pub const bade = 52; // Invalid exchange
    pub const badr = 53; // Invalid request descriptor
    pub const xfull = 54; // Exchange full
    pub const noano = 55; // No anode
    pub const badrqc = 56; // Invalid request code
    pub const badslt = 57; // Invalid slot
    pub const deadlock = deadlk;
    pub const bfont = 59; // Bad font file format
    pub const nostr = 60; // Device not a stream
    pub const nodata = 61; // No data available
    pub const time = 62; // Timer expired
    pub const nosr = 63; // Out of streams resources
    pub const nonet = 64; // Machine is not on the network
    pub const nopkg = 65; // Package not installed
    pub const remote = 66; // Object is remote
    pub const nolink = 67; // Link has been severed
    pub const adv = 68; // Advertise error
    pub const srmnt = 69; // Srmount error
    pub const comm = 70; // Communication error on send
    pub const proto = 71; // Protocol error
    pub const multihop = 72; // Multihop attempted
    pub const dotdot = 73; // RFS specific error
    pub const badmsg = 74; // Not a data message
    pub const fsbadcrc = badmsg; // Bad CRC detected
    pub const overflow = 75; // Value too large for defined data type
    pub const notuniq = 76; // Name not unique on network
    pub const badfd = 77; // File descriptor in bad state
    pub const remchg = 78; // Remote address changed
    pub const libacc = 79; // Can not access a needed shared library
    pub const libbad = 80; // Accessing a corrupted shared library
    pub const libscn = 81; // .lib section in a.out corrupted
    pub const libmax = 82; // Attempting to link in too many shared libraries
    pub const libexec = 83; // Cannot exec a shared library directly
    pub const ilseq = 84; // Illegal byte sequence
    pub const restart = 85; // Interrupted system call should be restarted
    pub const strpipe = 86; // Streams pipe error
    pub const users = 87; // Too many users
    pub const notsock = 88; // Socket operation on non-socket
    pub const destaddrreq = 89; // Destination address required
    pub const msgsize = 90; // Message too long
    pub const prototype = 91; // Protocol wrong type for socket
    pub const noprotoopt = 92; // Protocol not available
    pub const protonosupport = 93; // Protocol not supported
    pub const socktnosupport = 94; // Socket type not supported
    pub const opnotsupp = 95; // Operation not supported on transport endpoint
    pub const pfnosupport = 96; // Protocol family not supported
    pub const afnosupport = 97; // Address family not supported by protocol
    pub const addrinuse = 98; // Address already in use
    pub const addrnotavail = 99; // Cannot assign requested address
    pub const netdown = 100; // Network is down
    pub const netunreach = 101; // Network is unreachable
    pub const netreset = 102; // Network dropped connection because of reset
    pub const connaborted = 103; // Software caused connection abort
    pub const connreset = 104; // Connection reset by peer
    pub const nobufs = 105; // No buffer space available
    pub const isconn = 106; // Transport endpoint is already connected
    pub const notconn = 107; // Transport endpoint is not connected
    pub const shutdown = 108; // Cannot send after transport endpoint shutdown
    pub const toomanyrefs = 109; // Too many references: cannot splice
    pub const timedout = 110; // Connection timed out
    pub const connrefused = 111; // Connection refused
    pub const hostdown = 112; // Host is down
    pub const hostunreach = 113; // No route to host
    pub const already = 114; // Operation already in progress
    pub const inprogress = 115; // Operation now in progress
    pub const stale = 116; // Stale file handle
    pub const uclean = 117; // Structure needs cleaning
    pub const fscorrupted = uclean; // Filesystem is corrupted
    pub const notnam = 118; // Not a XENIX named type file
    pub const navail = 119; // No XENIX semaphores available
    pub const isnam = 120; // Is a named type file
    pub const remoteio = 121; // Remote I/O error
    pub const dquot = 122; // Quota exceeded
    pub const nomedium = 123; // No medium found
    pub const mediumtype = 124; // Wrong medium type
    pub const canceled = 125; // Operation Canceled
    pub const nokey = 126; // Required key not available
    pub const keyexpired = 127; // Key has expired
    pub const keyrevoked = 128; // Key has been revoked
    pub const keyrejected = 129; // Key was rejected by service
// for robust mutexes
    pub const ownerdead = 130; // Owner died
    pub const notrecoverable = 131; // State not recoverable
    pub const rfkill = 132; // Operation not possible due to RF-kill
    pub const hwpoison = 133; // Memory page has hardware error
    pub const ftype = 134; // Wrong file type for the intended operation
};

