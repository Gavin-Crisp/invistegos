const std = @import("std");
const config = @import("config");
const ldpc = @import("../ldpc.zig");

pub const CodeMatrix = SimpleMatrix(config.c_nodes, ldpc.v_nodes);
pub const GeneratorMatrix = SimpleMatrix(config.d_nodes, config.c_nodes);

fn SimpleMatrix(m: comptime_int, n: comptime_int) type {
    const Row = @Type(.{ .int = .{ .signedness = .unsigned, .bits = std.math.log2_int_ceil(comptime_int, n) } });
    const Col = @Type(.{ .int = .{ .signedness = .unsigned, .bits = std.math.log2_int_ceil(comptime_int, m) } });

    return struct {
        buf: [M * N]u1 = [_]u1{0} ** (M * N),

        const Self = @This();
        const M = m;
        const N = n;

        pub fn get(self: Self, row: Row, col: Col) *u1 {
            std.debug.assert(row < M);
            std.debug.assert(col < N);

            return &self.buf[row * M + col];
        }

        pub fn get_row(self: Self, row: Row) []u1 {
            std.debug.assert(row < M);

            self.buf[row * M .. (row + 1) * M];
        }

        pub fn add_rows(self: Self, from: Row, to: Row) void {
            std.debug.assert(from < M);
            std.debug.assert(to < M);

            const from_row = self.get_row(from);
            const to_row = self.get_row(to);

            for (from_row, to_row) |from_el, *to_el| {
                to_el.* ^= from_el;
            }
        }

        pub fn swap_rows(self: Self, row1: Row, row2: Row) void {
            std.debug.assert(row1 < M);
            std.debug.assert(row2 < M);

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

        pub fn into_csc(self: Self) Csc(self) {
            var out = .{};

            out.column_indices[0] = 0;
            var elem_idx = 0;

            for (0..N) |col_idx| {
                for (0..M) |row_idx| {
                    if (self.get(row_idx, col_idx) == 1) {
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

            return CscMatrix(num_nonzeroes, M, N);
        }
    };
}

pub fn CscMatrix(num_nonzeroes: comptime_int, m: comptime_int, n: comptime_int) type {
    const RowIndices = @Type(.{ .array = .{ .len = num_nonzeroes, .child = usize } });
    const ColumnIndices = @Type(.{ .array = .{ .len = n + 1, .child = usize } });

    return struct {
        row_indices: RowIndices,
        column_indices: ColumnIndices,

        const Self = @This();
        const M = m;
        const N = n;

        pub fn get(self: Self, row: usize, col: usize) u1 {
            std.debug.assert(row < M);
            std.debug.assert(col < N);

            const col_start = self.column_indices[col];
            const col_end = self.column_indices[col + 1];
            const elem_rows = self.row_indices[col_start..col_end];

            for (elem_rows) |elem| {
                if (row == elem) {
                    return 1;
                }
            }

            return 0;
        }

        pub fn get_col(self: Self, col: usize) [M]u1 {
            std.debug.assert(col < N);

            const col_start = self.column_indices[col];
            const col_end = self.column_indices[col + 1];
            const elem_rows = self.row_indices[col_start..col_end];

            var out: [M]u1 = .{0};
            var elem_index = 0;

            for (0..M) |row| {
                if (row == elem_rows[elem_index]) {
                    out[row] = 1;
                    elem_index += 1;
                }
            }

            return out;
        }
    };
}
