const std = @import("std");
const config = @import("config");
const csc = @import("csc.zig");
const csr = @import("csr.zig");
const ldpc = @import("../ldpc.zig");

pub const CodeMatrix = SimpleMatrix(config.c_nodes, ldpc.v_nodes);
pub const GeneratorMatrix = SimpleMatrix(config.d_nodes, config.c_nodes);

fn SimpleMatrix(m: comptime_int, n: comptime_int) type {
    const Row: type = @Type(.{ .int = .{ .signedness = .unsigned, .bits = std.math.log2_int_ceil(comptime_int, m) } });
    const Col: type = @Type(.{ .int = .{ .signedness = .unsigned, .bits = std.math.log2_int_ceil(comptime_int, n) } });

    return struct {
        buf: [M * N]u1 = [_]u1{0} ** (M * N),

        pub const M = m;
        pub const N = n;

        const Self = @This();

        pub fn index(self: Self, row: Row, col: Col) *u1 {
            std.debug.assert(row < M);
            std.debug.assert(col < N);

            return &self.buf[row * M + col];
        }

        pub fn getRow(self: Self, row: Row) []u1 {
            std.debug.assert(row < M);

            self.buf[row * M .. (row + 1) * M];
        }

        pub fn addRows(self: Self, from: Row, to: Row) void {
            std.debug.assert(from < M);
            std.debug.assert(to < M);

            const from_row = self.getRow(from);
            const to_row = self.getRow(to);

            for (from_row, to_row) |from_el, *to_el| {
                to_el.* ^= from_el;
            }
        }

        pub fn swapRows(self: Self, row1: Row, row2: Row) void {
            std.debug.assert(row1 < M);
            std.debug.assert(row2 < M);

            if (row1 == row2)
                return;

            const r1 = self.getRow(row1);
            const r2 = self.getRow(row2);

            for (r1, r2) |*r1_el, *r2_el| {
                const tmp = r1_el.*;
                r1_el.* = r2_el.*;
                r2_el.* = tmp;
            }
        }

        pub fn intoCsc(self: Self) Csc(self) {
            var out = .{};

            out.column_indices[0] = 0;
            var elem_idx = 0;

            for (0..N) |col_idx| {
                for (0..M) |row_idx| {
                    if (self.index(row_idx, col_idx) == 1) {
                        out.row_indices[elem_idx] = row_idx;
                        elem_idx += 1;
                    }
                }

                out.column_indices[col_idx + 1] = elem_idx;
            }

            return out;
        }

        fn Csc(self: Self) type {
            var num_nonzeroes = 0;

            for (self.buf) |elem| {
                if (elem == 1) {
                    num_nonzeroes += 1;
                }
            }

            return csc.CscMatrix(num_nonzeroes, M, N);
        }

        pub fn intoCsr(self: Self) Csr(self) {
            var out = .{};

            out.column_indices[0] = 0;
            var elem_idx = 0;

            for (0..N) |col_idx| {
                for (0..M) |row_idx| {
                    if (self.index(row_idx, col_idx) == 1) {
                        out.row_indices[elem_idx] = row_idx;
                        elem_idx += 1;
                    }
                }

                out.column_indices[col_idx + 1] = elem_idx;
            }

            return out;
        }

        fn Csr(self: Self) type {
            var num_nonzeroes = 0;

            for (self.buf) |elem| {
                if (elem == 1) {
                    num_nonzeroes += 1;
                }
            }

            return csr.CsrMatrix(num_nonzeroes, M, N);
        }
    };
}
