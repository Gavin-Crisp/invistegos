const std = @import("std");

pub fn CscMatrix(num_nonzeroes: comptime_int, m: comptime_int, n: comptime_int) type {
    return struct {
        row_indices: RowIndices,
        column_indices: ColumnIndices,

        pub const Row: type = @Type(.{ .int = .{ .signedness = .unsigned, .bits = std.math.log2_int_ceil(comptime_int, m) } });
        pub const Col: type = @Type(.{ .int = .{ .signedness = .unsigned, .bits = std.math.log2_int_ceil(comptime_int, n) } });
        const RowIndices: type = @Type(.{ .array = .{ .len = num_nonzeroes, .child = Row } });
        const ColumnIndices: type = @Type(.{ .array = .{ .len = n + 1, .child = Col } });

        pub const M = m;
        pub const N = n;

        const Self = @This();

        pub fn get(self: Self, row: Row, col: Col) u1 {
            std.debug.assert(row < M);
            std.debug.assert(col < N);

            const elem_rows = get_col_by_indices(self, col);

            for (elem_rows) |elem| {
                if (row == elem) {
                    return 1;
                }
            }

            return 0;
        }

        pub fn get_col(self: Self, col: Col) [M]u1 {
            std.debug.assert(col < N);

            const elem_rows = get_col_by_indices(self, col);

            var out = std.mem.zeroes([M]u1);
            var elem_index = 0;

            for (0..M) |row| {
                if (row == elem_rows[elem_index]) {
                    out[row] = 1;
                    elem_index += 1;
                }
            }

            return out;
        }

        pub fn get_col_by_indices(self: Self, col: Col) []Row {
            const col_start = self.column_indices[col];
            const col_end = self.column_indices[col + 1];
            return self.row_indices[col_start..col_end];
        }
    };
}
