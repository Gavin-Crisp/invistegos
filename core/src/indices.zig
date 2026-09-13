const config = @import("config");

pub const DeviceIndexInt = u64;

pub const PhysicalIndex = enum (DeviceIndexInt) {
    _,

    const Self = @This();

    pub fn from(int: DeviceIndexInt) Self {
        return @enumFromInt(int);
    }

    pub fn to(self: Self) DeviceIndexInt {
        return @intFromEnum(self);
    }

    pub fn cluster(self: Self) PhysicalClusterIndex {
        return .from(self.to() / config.lcg_cluster_size);
    }

    pub fn clusterOffset(self: Self) DeviceIndexInt {
        return self.to() % config.lcg_cluster_size;
    }

    pub fn spanClusters(self: Self, len: u64) u64 {
        const first_cluster = self.cluster();
        const last_cluster: PhysicalClusterIndex = .from(self + len - 1);

        return last_cluster.to() - first_cluster.to() + 1;
    }
};

pub const PhysicalClusterIndex = enum (DeviceIndexInt) {
    _,

    const Self = @This();

    pub fn from(int: DeviceIndexInt) Self {
        return @enumFromInt(int);
    }

    pub fn to(self: Self) DeviceIndexInt {
        return @intFromEnum(self);
    }

    pub fn beginning(self: Self) PhysicalIndex {
        return .from(self.to() * config.lcg_cluster_size);
    }
};

pub const ShuffledIndex = enum (DeviceIndexInt) {
    _,

    const Self = @This();

    pub fn from(int: DeviceIndexInt) Self {
        return @enumFromInt(int);
    }

    pub fn to(self: Self) DeviceIndexInt {
        return @intFromEnum(self);
    }

    pub fn cluster(self: Self) ShuffledClusterIndex {
        return .from(self.to() / config.lcg_cluster_size);
    }

    pub fn clusterOffset(self: Self) DeviceIndexInt {
        return self.to() % config.lcg_cluster_size;
    }

    pub fn spanClusters(self: Self, len: u64) u64 {
        const first_cluster = self.cluster();
        const last_cluster: ShuffledClusterIndex = .from(self + len - 1);

        return last_cluster.to() - first_cluster.to() + 1;
    }
};

pub const ShuffledClusterIndex = enum (DeviceIndexInt) {
    _,

    const Self = @This();

    pub fn from(int: DeviceIndexInt) Self {
        return @enumFromInt(int);
    }

    pub fn to(self: Self) DeviceIndexInt {
        return @intFromEnum(self);
    }

    pub fn beginning(self: Self) ShuffledIndex {
        return .from(self.to() * config.lcg_cluster_size);
    }
};

pub const LogicalIndex = enum (DeviceIndexInt) {
    _,

    const Self = @This();

    pub fn from(int: DeviceIndexInt) Self {
        return @enumFromInt(int);
    }

    pub fn to(self: Self) DeviceIndexInt {
        return @intFromEnum(self);
    }
};

