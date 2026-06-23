const std = @import("std");
const constants = @import("c/consts.zig");

pub fn toUnsigned(comptime T: type, t: T) u32 {
    var unsigned: u32 = 0;
    const field_names = comptime std.meta.fieldNames(T);

    inline for (field_names) |field_name| {
        if (@field(t, field_name) == true)
            unsigned = unsigned | @field(constants, field_name);
    }

    return unsigned;
    //    return comptime blk: {
    //        var unsigned: u32 = 0;
    //        const field_names = std.meta.fieldNames(T);
    //        for (field_names) |field_name| {
    //            if (@field(t, field_name) == true) unsigned = unsigned | @field(constants, field_name);
    //        }
    //        const final = unsigned;
    //        break :blk final;
    //    };
}

pub fn fromUnsigned(comptime T: type, unsigned: u32) T {
    var t = T{};
    const field_names = comptime std.meta.fieldNames(T);

    inline for (field_names) |field_name| {
        if (unsigned & @field(constants, field_name) == @field(constants, field_name))
            @field(t, field_name) = true
        else
            @field(t, field_name) = false;
    }

    return t;
}
