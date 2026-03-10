const config = @import("config");
const shared = @import("root.zig");
const std = @import("std");

const gce = @import("ldpc/gce.zig");
const simple_matrix = @import("ldpc/simple_matrix.zig");

const c_nodes = config.c_nodes;
const d_nodes = config.d_nodes;
pub const v_nodes = d_nodes + c_nodes;

const EccNode = shared.EccNode;

const code = gce.code_matrix.into_csr();
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

    const gen: simple_matrix.GeneratorMatrix = .{};

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

// TODO: change to return error
pub fn decode(code_word: [v_nodes]?EccNode) ?[d_nodes]EccNode {
    decode_in_place(code_word);

    var word: [d_nodes]EccNode = undefined;
    @memcpy(&word, code_word[0..d_nodes]);

    return word;
}

// TODO: change to return error
pub fn decode_in_place(code_word: [v_nodes]?EccNode) void {
    const checks_buf = init: {
        var buf: [c_nodes]usize = undefined;

        for (0..buf.len) |index| {
            buf[index] = index;
        }

        break :init buf;
    };
    const checks: std.ArrayList(usize) = .{ .items = checks_buf[0..checks_buf.len], .capacity = checks_buf.len };
    var missing_word_nodes: usize = init: {
        var count = 0;

        for (code_word[0..d_nodes]) |node_opt| {
            if (node_opt == null) {
                count += 1;
            }
        }

        break :init count;
    };

    if (!is_decoding_possible(code_word, missing_word_nodes)) {
        return null;
    }

    while (missing_word_nodes > 0) {
        const remaining_checks = checks.items.len;
        var checks_index: usize = 0;

        while (checks_index < checks.items.len) {
            const check_outcome = decode_check(code.get_row_by_indices(checks_index), code_word);

            switch (check_outcome) {
                DecodeCheckOutcome.fully_specified => |outcome| if (outcome.is_valid) {
                    // A fully specified valid parity check provides no new information and is a waste of time.
                    checks.swapRemove(checks_index);
                } else {
                    return null;
                },
                DecodeCheckOutcome.resolvable => |outcome| {
                    code_word[outcome.node_idx] = outcome.check_value;
                    if (outcome.node_idx < d_nodes) {
                        missing_word_nodes -= 1;
                    }

                    // Each parity check can resolve up to one error, and after that it cannot provide new information.
                    checks.swapRemove(checks_index);
                },
                DecodeCheckOutcome.unresolvable => {},
            }

            checks_index += 1;
        }

        // If no checks were used in the previous loop, none will in all future loops, and the algorithm has stalled.
        if (remaining_checks == checks.items.len) {
            return null;
        }
    }
}

fn is_decoding_possible(code_word: [v_nodes]?EccNode, missing_word_nodes: usize) bool {
    var count: usize = 0;

    for (code_word[d_nodes..v_nodes]) |node_opt| {
        if (node_opt == null) {
            count += 1;
        }
    }

    return count + missing_word_nodes > c_nodes;
}

const DecodeCheckOutcome = union(enum) {
    fully_specified: struct { is_valid: bool },
    resolvable: struct { node_idx: usize, check_value: EccNode },
    unresolvable: void,
};

fn decode_check(check: []code.Col, code_word: [v_nodes]?EccNode) DecodeCheckOutcome {
    var check_value: EccNode = 0;
    var first_missing_node: ?code.Col = 0;

    for (check) |check_node| {
        if (code_word[check_node]) |code_node| {
            check_value ^= code_node;
        } else if (first_missing_node) |_| {
            return .unresolvable;
        } else {
            first_missing_node = check_node;
        }
    }

    return if (first_missing_node) |node_idx|
        .{ .resolvable = .{ .node_idx = node_idx, .check_value = check_value } }
    else
        .{ .fully_specified = .{ .is_valid = check_value == 0 } };
}
