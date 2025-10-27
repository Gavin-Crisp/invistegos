pub const mult = 80285479;
pub const incr = 33276689;

pub fn lcg(comptime T: type, seed: T) T {
    return mult *% seed +% incr;
}

pub fn lcg_map(comptime T: type, index: T, limit: T) T {
    if (index >= limit)
        return index;

    // Applied thrice at a minimum because lcg is not especially random
    var ret = lcg(T, lcg(T, lcg(T, index)));

    while (ret >= limit) {
        ret = lcg(T, ret);
    }

    return ret;
}
