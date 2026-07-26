const linux = @import("linux.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Alignment = std.mem.Alignment;

pub const k_alloc = struct {
    const kernelAlloc = @extern(fn (usize) ?*anyopaque, .{ .name = "kernel_alloc" });
    const kernelRealloc = @extern(fn (*anyopaque, usize) ?*anyopaque, .{ .name = "kernel_realloc" });
    const kernelFree = @extern(fn (?*anyopaque) void, .{ .name = "kernel_free" });

    fn vTableAlloc(_: *anyopaque, len: usize, _: Alignment, _: usize) ?[*]u8 {
        return @ptrCast(kernelAlloc(len));
    }

    fn vTableRemap(_: *anyopaque, memory: []u8, _: Alignment, new_len: usize, _: usize) ?[*]u8 {
        return @ptrCast(kernelRealloc(@ptrCast(memory), new_len));
    }

    fn vTableFree(_: *anyopaque, memory: []u8, _: Alignment, _: usize) void {
        kernelFree(@ptrCast(memory));
    }

    const vtable: Allocator.VTable = .{
        .alloc = vTableAlloc,
        .resize = Allocator.noResize,
        .remap = vTableRemap,
        .free = vTableFree,
    };

    pub const allocator: Allocator = .{
        .ptr = undefined,
        .vtable = vtable,
    };
}.allocator;

