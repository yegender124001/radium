pub const Buffer = struct {
    addr: usize,
    ptr: *anyopaque,
    width: u32,
    height: u32,
    stride: u32,
};

const Self = @This();

ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    acquireBuffer: *const fn (ptr: *anyopaque) anyerror!Buffer,
    presentBuffer: *const fn (ptr: *anyopaque, buffer: Buffer, damage: ?@Vector(4, u32)) void,
};

pub fn acquireBuffer(self: Self) !Buffer {
    return self.vtable.acquireBuffer(self.ptr);
}
pub fn presentBuffer(self: Self, buffer: Buffer, damage: ?@Vector(4, u32)) void {
    self.vtable.presentBuffer(self.ptr, buffer, damage);
}
