const std = @import("std");
const assert = std.debug.assert;

pub fn StaticBinaryTree(comptime T: type, comptime levels: u8) type {
    return struct {
        const Self = @This();
        pub const size: usize = (1 << levels) - 1;

        items: [size]T,

        pub fn init(initial_value: T) Self {
            return .{
                .items = [_]T{initial_value} ** size,
            };
        }

        pub const Cursor = struct {
            tree: *Self,
            index: usize = 0,

            pub fn value(self: *Cursor) T {
                return self.tree.items[self.index];
            }

            pub fn parent(self: *Cursor) ?void {
                if (self.index == 0) {
                    return null;
                }
                self.index = (self.index - 1) >> 1;
            }

            pub fn leftChild(self: *Cursor) ?void {
                if (self.index >= size / 2) {
                    return null;
                }
                self.index = (self.index << 1) + 1;
            }

            pub fn rightChild(self: *Cursor) ?void {
                if (self.index >= size / 2) {
                    return null;
                }
                self.index = (self.index << 1) + 2;
            }

            pub fn sibling(self: *Cursor) ?void {
                if (self.index & 1 == 0) {
                    return null;
                }
                self.index += 1;
            }
        };

        pub const PreorderIterator = struct {
            cursor: Cursor,
            done: bool = false,

            pub fn next(it: *PreorderIterator) ?T {
                if (it.done) {
                    return null;
                }
                const value = it.cursor.value();
                if (it.cursor.leftChild() == null) {
                    if (it.cursor.rightChild() == null) {
                        while (it.cursor.index & 1 == 0) {
                            if (it.cursor.index == 0) {
                                it.done = true;
                                break;
                            }
                            _ = it.cursor.parent();
                        } else {
                            _ = it.cursor.sibling();
                        }
                    }
                }
                return value;
            }

            pub fn reset(it: *PreorderIterator) void {
                it.cursor.index = 0;
                it.done = false;
            }
        };

        pub fn preorderIterator(self: *Self) PreorderIterator {
            return .{
                .cursor = .{
                    .tree = self,
                },
            };
        }
    };
}

const TestData = struct {
    level: u8,
    order: []const u8,
};

test "preorderIterator" {
    inline for ([_]TestData{
        .{
            .level = 1,
            .order = &.{0},
        },
        .{
            .level = 2,
            .order = &.{ 0, 1, 2 },
        },
        .{
            .level = 3,
            .order = &.{ 0, 1, 3, 4, 2, 5, 6 },
        },
        .{
            .level = 4,
            .order = &.{ 0, 1, 3, 7, 8, 4, 9, 10, 2, 5, 11, 12, 6, 13, 14 },
        },
    }) |data| {
        const Tree = StaticBinaryTree(u8, data.level);
        var tree = Tree.init(0);

        {
            var i: usize = 0;
            while (i < Tree.size) : (i += 1) {
                tree.items[i] = @intCast(u8, i);
            }
        }

        {
            var i: usize = 0;
            var it = tree.preorderIterator();
            while (it.next()) |value| : (i += 1) {
                try std.testing.expectEqual(data.order[i], value);
            }
        }
    }
}
