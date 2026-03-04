const config = @import("config");
const shared = @import("root.zig");
const std = @import("std");

const gce = @import("ldpc/gce.zig");
const matrix = @import("ldpc/matrix.zig");

const c_nodes = config.c_nodes;
const d_nodes = config.d_nodes;
pub const v_nodes = d_nodes + c_nodes;

const EccNode = shared.EccNode;

const code = gce.code_matrix.into_csc();
const generator = init: {
    const h = gce.code_matrix;

    // Reduce h to [-P^T|I_c]
    for (0..c_nodes) |diag_row| {
        const diag_col = diag_row + d_nodes;

        // Ensure a one is on the diagonal
        const first_one = for (diag_row..c_nodes) |row| {
            if (h.index(row, diag_col) == 1)
                break row;
        };
        h.swap_rows(diag_row, first_one);

        // Remove non-diagonal ones from column
        for (0..c_nodes) |row| {
            if (row == diag_row) continue;

            if (h.index(row, diag_col) == 1) {
                h.add_rows(diag_row, row);
            }
        }
    }

    const gen: matrix.GeneratorMatrix = .{};

    // Move I_d into gen
    for (0..d_nodes) |idx| {
        gen.index(idx, idx).* = 1;
    }

    // Move P into gen
    for (0..d_nodes) |row| {
        for (0..c_nodes) |col| {
            const gen_row = row;
            const gen_col = col + d_nodes;

            gen.index(gen_row, gen_col).* = h.index(col, row).*;
        }
    }

    break :init gen.into_csc();
};

pub fn encode(word: [d_nodes]EccNode) [v_nodes]EccNode {
    var code_word: [v_nodes]EccNode = .{};

    // The first d_nodes Nodes are unchanged, as the first d_nodes columns of the generator are an identity matrix.
    @memcpy(code_word[0..d_nodes], &word);

    for (d_nodes..v_nodes) |code_idx| {
        const gen_col = generator.get_col(code_idx);

        for (gen_col, word) |gen_elem, word_node| {
            if (gen_elem == 1) {
                code_word[code_idx] ^= word_node;
            }
        }
    }

    return code_word;
}

pub fn decode(code_word: [v_nodes]?EccNode) ?[d_nodes]EccNode {
    var word: [d_nodes]EccNode = undefined;

    // Check the first d_nodes Nodes for errors and resolve them.
    for (0..d_nodes) |node_idx| {
        if (code_word[node_idx]) continue;

        if (!resolve_missing(code_word, node_idx)) {
            return null;
        }
    }

    @memcpy(&word, code_word[0..d_nodes]);

    return word;
}

fn resolve_missing(code_word: [v_nodes]?EccNode, missing: usize) bool {
    _ = code_word;
    _ = missing;
    @panic("resolve_missing unimplemented");
}

test {
    _ = matrix;
}
