const config = @import("config");
const shared = @import("root.zig");

const Index = shared.Index;

const lcg_mult: Index = @trunc(config.lcg_mult);
const lcg_incr: Index = @trunc(config.lcg_incr);

pub fn lcg(seed: Index) Index {
    return lcg_mult *% seed +% lcg_incr;
}

pub fn lcg_map(index: shared.ShuffledIndex, limit: Index) shared.PhysicalIndex {
    if (index >= limit)
        return index;

    // Applied thrice at a minimum because lcg is not especially random
    var ret = lcg(lcg(lcg(index)));

    while (ret >= limit) {
        ret = lcg(ret);
    }

    return ret;
}
