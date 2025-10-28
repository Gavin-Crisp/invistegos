const config = @import("config");

pub const Lcg = @Type(.{ .int = .{ .bits = config.lcg_bits, .signedness = .unsigned } });

const lcg_mult: Lcg = @trunc(config.lcg_mult);
const lcg_incr: Lcg = @trunc(config.lcg_incr);

pub fn lcg(seed: Lcg) Lcg {
    return lcg_mult *% seed +% lcg_incr;
}

pub fn lcg_map(index: Lcg, limit: Lcg) Lcg {
    if (index >= limit)
        return index;

    // Applied thrice at a minimum because lcg is not especially random
    var ret = lcg(lcg(lcg(index)));

    while (ret >= limit) {
        ret = lcg(ret);
    }

    return ret;
}
