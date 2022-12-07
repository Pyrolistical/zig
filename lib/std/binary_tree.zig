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
                if (self.parentIndex()) |index| {
                    self.index = index;
                } else {
                    return null;
                }
            }

            pub fn parentIndex(self: Cursor) ?usize {
                if (self.index == 0) {
                    return null;
                }
                return (self.index - 1) >> 1;
            }

            pub fn leftChild(self: *Cursor) ?void {
                if (self.leftIndex()) |index| {
                    self.index = index;
                } else {
                    return null;
                }
            }

            pub fn leftIndex(self: Cursor) ?usize {
                if (self.index >= size / 2) {
                    return null;
                }
                return (self.index << 1) + 1;
            }

            pub fn rightChild(self: *Cursor) ?void {
                if (self.rightIndex()) |index| {
                    self.index = index;
                } else {
                    return null;
                }
            }

            pub fn rightIndex(self: Cursor) ?usize {
                if (self.index >= size / 2) {
                    return null;
                }
                return (self.index << 1) + 2;
            }

            pub fn sibling(self: *Cursor) ?void {
                if (self.siblingIndex()) |index| {
                    self.index = index;
                } else {
                    return null;
                }
            }

            pub fn siblingIndex(self: Cursor) ?usize {
                if (self.index == 0) {
                    return null;
                }
                return if (self.index & 1 == 0)
                    self.index - 1
                else
                    self.index + 1;
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

        pub const InorderIterator = struct {
            cursor: Cursor,
            done: bool = false,

            pub fn next(it: *InorderIterator) ?T {
                if (it.done) {
                    return null;
                }
                const value = it.cursor.value();
                if (it.cursor.rightChild() == null) {
                    var last: ?usize = null;
                    while (it.cursor.rightIndex() == last) {
                        if (it.cursor.index == 0) {
                            it.done = true;
                            break;
                        }
                        last = it.cursor.index;
                        _ = it.cursor.parent();
                    }
                } else {
                    while (it.cursor.leftChild()) |_| {}
                }
                return value;
            }

            pub fn reset(it: *InorderIterator) void {
                it.cursor.index = 0;
                it.done = false;
                while (it.cursor.leftChild()) |_| {}
            }
        };

        pub fn inorderIterator(self: *Self) InorderIterator {
            var it = InorderIterator{
                .cursor = .{
                    .tree = self,
                },
            };
            it.reset();
            return it;
        }

        pub const PostorderIterator = struct {
            cursor: Cursor,
            done: bool = false,

            pub fn next(it: *PostorderIterator) ?T {
                if (it.done) {
                    return null;
                }
                const value = it.cursor.value();
                if (it.cursor.index & 1 == 1) {
                    _ = it.cursor.sibling();
                    while (it.cursor.leftChild()) |_| {}
                } else {
                    if (it.cursor.index == 0) {
                        it.done = true;
                    } else {
                        _ = it.cursor.parent();
                    }
                }
                return value;
            }

            pub fn reset(it: *PostorderIterator) void {
                it.cursor.index = 0;
                it.done = false;
                while (it.cursor.leftChild()) |_| {}
            }
        };

        pub fn postorderIterator(self: *Self) PostorderIterator {
            var it = PostorderIterator{
                .cursor = .{
                    .tree = self,
                },
            };
            it.reset();
            return it;
        }
    };
}

const TestData = struct {
    levels: u8,
    expected_order: []const u8,
};

test "preorderIterator" {
    inline for ([_]TestData{
        .{
            .levels = 1,
            .expected_order = &.{0},
        },
        .{
            .levels = 2,
            .expected_order = &.{ 0, 1, 2 },
        },
        .{
            .levels = 3,
            .expected_order = &.{ 0, 1, 3, 4, 2, 5, 6 },
        },
        .{
            .levels = 4,
            .expected_order = &.{ 0, 1, 3, 7, 8, 4, 9, 10, 2, 5, 11, 12, 6, 13, 14 },
        },
        .{
            .levels = 5,
            .expected_order = &.{ 0, 1, 3, 7, 15, 16, 8, 17, 18, 4, 9, 19, 20, 10, 21, 22, 2, 5, 11, 23, 24, 12, 25, 26, 6, 13, 27, 28, 14, 29, 30 },
        },
    }) |data| {
        const Tree = StaticBinaryTree(u8, data.levels);
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
                try std.testing.expectEqual(data.expected_order[i], value);
            }
        }
    }
}

test "inorderIterator" {
    inline for ([_]TestData{
        .{
            .levels = 1,
            .expected_order = &.{0},
        },
        .{
            .levels = 2,
            .expected_order = &.{ 1, 0, 2 },
        },
        .{
            .levels = 3,
            .expected_order = &.{ 3, 1, 4, 0, 5, 2, 6 },
        },
        .{
            .levels = 4,
            .expected_order = &.{ 7, 3, 8, 1, 9, 4, 10, 0, 11, 5, 12, 2, 13, 6, 14 },
        },
        .{
            .levels = 5,
            .expected_order = &.{ 15, 7, 16, 3, 17, 8, 18, 1, 19, 9, 20, 4, 21, 10, 22, 0, 23, 11, 24, 5, 25, 12, 26, 2, 27, 13, 28, 6, 29, 14, 30 },
        },
    }) |data| {
        const Tree = StaticBinaryTree(u8, data.levels);
        var tree = Tree.init(0);

        {
            var i: usize = 0;
            while (i < Tree.size) : (i += 1) {
                tree.items[i] = @intCast(u8, i);
            }
        }

        {
            var i: usize = 0;
            var it = tree.inorderIterator();
            while (it.next()) |value| : (i += 1) {
                try std.testing.expectEqual(data.expected_order[i], value);
            }
        }
    }
}

test "postorderIterator" {
    inline for ([_]TestData{
        .{
            .levels = 1,
            .expected_order = &.{0},
        },
        .{
            .levels = 2,
            .expected_order = &.{ 1, 2, 0 },
        },
        .{
            .levels = 3,
            .expected_order = &.{ 3, 4, 1, 5, 6, 2, 0 },
        },
        .{
            .levels = 4,
            .expected_order = &.{ 7, 8, 3, 9, 10, 4, 1, 11, 12, 5, 13, 14, 6, 2, 0 },
        },
        .{
            .levels = 5,
            .expected_order = &.{ 15, 16, 7, 17, 18, 8, 3, 19, 20, 9, 21, 22, 10, 4, 1, 23, 24, 11, 25, 26, 12, 5, 27, 28, 13, 29, 30, 14, 6, 2, 0 },
        },
    }) |data| {
        const Tree = StaticBinaryTree(u8, data.levels);
        var tree = Tree.init(0);

        {
            var i: usize = 0;
            while (i < Tree.size) : (i += 1) {
                tree.items[i] = @intCast(u8, i);
            }
        }

        {
            var i: usize = 0;
            var it = tree.postorderIterator();
            while (it.next()) |value| : (i += 1) {
                try std.testing.expectEqual(data.expected_order[i], value);
            }
        }
    }
}
