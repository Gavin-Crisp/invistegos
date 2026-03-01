const config = @import("config");
const shared = @import("root.zig");

const gce = @import("ldpc/gce.zig");
const matrix = @import("ldpc/matrix.zig");

const c_nodes = config.c_nodes;
const d_nodes = config.d_nodes;
pub const v_nodes = d_nodes + c_nodes;

const EccNode = shared.EccNode;

const Word = [d_nodes]EccNode;
const CodeWord = [v_nodes]EccNode;

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

pub fn encode(word: Word) CodeWord {
    var code_word: CodeWord = .{};

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

pub fn decode(code_word: CodeWord) Word {
    _ = code_word;
    @panic("decode unimplemented");
}

test {
    _ = matrix;
}
