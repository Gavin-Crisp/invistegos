const std = @import("std");
const config = @import("config");
const ldpc = @import("../ldpc.zig");

pub const CodeMatrix = Template(config.c_nodes, ldpc.v_nodes);
pub const GeneratorMatrix = Template(config.d_nodes, config.c_nodes);

fn Template(n: comptime_int, m: comptime_int) type {
    return struct {
        buf: [n * m]u1 = [_]u1{0} ** (n * m),

        const Self = @This();

        pub const Row = @Type(.{ .int = .{ .signedness = .unsigned, .bits = std.math.log2_int_ceil(comptime_int, n) } });
        pub const Col = @Type(.{ .int = .{ .signedness = .unsigned, .bits = std.math.log2_int_ceil(comptime_int, m) } });

        pub fn get(self: Self, row: Row, col: Col) *u1 {
            return &self.buf[row * m + col];
        }

        pub fn get_row(self: Self, row: Row) []u1 {
            self.buf[row * m .. (row + 1) * m];
        }

        pub fn add_rows(self: Self, from: Row, to: Row) void {
            const from_row = self.get_row(from);
            const to_row = self.get_row(to);

            for (from_row, to_row) |from_el, *to_el| {
                to_el.* ^= from_el;
            }
        }

        pub fn swap_rows(self: Self, row1: Row, row2: Row) void {
            if (row1 == row2)
                return;

            const r1 = self.get_row(row1);
            const r2 = self.get_row(row2);

            for (r1, r2) |*r1_el, *r2_el| {
                const tmp = r1_el.*;
                r1_el.* = r2_el.*;
                r2_el.* = tmp;
            }
        }
    };
}
