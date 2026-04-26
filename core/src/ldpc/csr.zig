const std = @import("std");

pub fn CsrMatrix(num_nonzeroes: comptime_int, m: comptime_int, n: comptime_int) type {
    return struct {
        row_indices: RowIndices,
        column_indices: ColumnIndices,

        pub const Row: type = @Type(.{ .int = .{ .signedness = .unsigned, .bits = std.math.log2_int_ceil(comptime_int, m) } });
        pub const Col: type = @Type(.{ .int = .{ .signedness = .unsigned, .bits = std.math.log2_int_ceil(comptime_int, n) } });
        const RowIndices: type = @Type(.{ .array = .{ .len = m + 1, .child = Row } });
        const ColumnIndices: type = @Type(.{ .array = .{ .len = num_nonzeroes, .child = Col } });

        pub const M = m;
        pub const N = n;

        const Self = @This();

        pub fn get(self: Self, row: Row, col: Col) u1 {
            std.debug.assert(row < M);
            std.debug.assert(col < N);

            const elem_columns = get_row_by_indices(self, row);

            for (elem_columns) |elem| {
                if (col == elem) {
                    return 1;
                }
            }

            return 0;
        }

        pub fn get_row(self: Self, row: Row) [N]u1 {
            std.debug.assert(row < M);

            const elem_columns = get_row_by_indices(self, row);

            var out = std.mem.zeroes([N]u1);
            var elem_index = 0;

            for (0..N) |col| {
                if (col == elem_columns[elem_index]) {
                    out[col] = 1;
                    elem_index += 1;
                }
            }

            return out;
        }

        pub fn get_row_by_indices(self: Self, row: Row) []Col {
            const row_start = self.row_indices[row];
            const row_end = self.row_indices[row + 1];
            return self.column_indices[row_start..row_end];
        }
    };
}
