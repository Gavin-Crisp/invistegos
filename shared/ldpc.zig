const std = @import("std");
const config = @import("config");

const matrix = @import("ldpc/matrix.zig");

pub const v_nodes = config.d_nodes + config.c_nodes;

/// TODO: GCE
const code: matrix.CodeMatrix = .{};
const generator = blk: {
    const h = code;

    // Reduce h to [-P^T|I_c]
    for (0..config.c_nodes) |col| {
        const i = col + config.d_nodes;

        // Ensure a one is on the diagonal
        const first_one = for (col..config.c_nodes) |n| {
            if (h.get(n, n) == 1)
                break n;
        };
        h.swap_rows(col, first_one);

        // Remove non-diagonal ones from column
        for (0..config.c_nodes) |row| {
            if (row == col) continue;

            if (h.get(row, i) == 1) {
                h.add_rows(col, row);
            }
        }
    }

    const gen: matrix.GeneratorMatrix = .{};

    // Move P into gen
    for (0..config.d_nodes) |gen_row| {
        for (0..config.c_nodes) |gen_col| {
            gen.get(gen_row, gen_col).* = h.get(gen_col, gen_row).*;
        }
    }

    break :blk gen;
};

// TODO: Move to more central place
const Node = u512;

pub fn encode(data: [config.d_nodes]Node) [config.c_nodes]Node {
    const out: [config.c_nodes]Node = undefined;

    // Iterate through columns of gen_matrix
    for (0..config.c_nodes) |j| {
        var code_node: Node = 0;

        // Sum data and column
        for (0..config.d_nodes) |i|
            code_node ^= data[i] * generator.get(i, j);

        out[j] = code_node;
    }

    return out;
}

// TODO: add multiple decoder algorithms

test {
    _ = matrix;
}
