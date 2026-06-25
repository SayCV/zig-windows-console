const std = @import("std");
const testing = std.testing;

const c = @import("c/c.zig");
const windows = c.windows;
const utils = @import("utils.zig");
pub const types = @import("types.zig");
pub const Event = @import("events.zig").Event;

pub fn getCodepage() c_uint {
    return c.GetConsoleOutputCP();
}

pub fn setCodepage(codepage: c_uint) !void {
    if (c.SetConsoleOutputCP(codepage) == .FALSE) {
        switch (windows.GetLastError()) {
            else => |err| return windows.unexpectedError(err),
        }
    }
}

pub const ConsoleApp = struct {
    const Self = @This();

    stdin_handle: windows.HANDLE,
    stdout_handle: windows.HANDLE,

    pub fn init() !Self {
        return Self{ .stdin_handle = c.GetStdHandle(c.STD_INPUT_HANDLE), .stdout_handle = c.GetStdHandle(c.STD_OUTPUT_HANDLE) };
    }

    pub fn getInputMode(self: Self) !types.InputMode {
        var mode: windows.DWORD = undefined;
        if (c.GetConsoleMode(self.stdin_handle, &mode) == .FALSE) {
            switch (windows.GetLastError()) {
                else => |err| return windows.unexpectedError(err),
            }
        }
        return utils.fromUnsigned(types.InputMode, mode);
    }

    pub fn setInputMode(self: Self, mode: types.InputMode) !void {
        if (c.SetConsoleMode(self.stdin_handle, utils.toUnsigned(types.InputMode, mode)) == .FALSE) {
            switch (windows.GetLastError()) {
                else => |err| return windows.unexpectedError(err),
            }
        }
    }

    pub fn getOutputMode(self: Self) !types.OutputMode {
        var mode: windows.DWORD = undefined;
        if (c.GetConsoleMode(self.stdout_handle, &mode) == .FALSE) {
            switch (windows.GetLastError()) {
                else => |err| return windows.unexpectedError(err),
            }
        }
        return utils.fromUnsigned(types.OutputMode, mode);
    }

    pub fn setOutputMode(self: Self, mode: types.OutputMode) !void {
        if (c.SetConsoleMode(self.stdout_handle, utils.toUnsigned(types.OutputMode, mode)) == .FALSE) {
            switch (windows.GetLastError()) {
                else => |err| return windows.unexpectedError(err),
            }
        }
    }

    pub fn getEvent(self: Self) !Event {
        var event_count: u32 = 0;
        var input_record = std.mem.zeroes(c.INPUT_RECORD);

        if (c.ReadConsoleInputW(self.stdin_handle, &input_record, 1, &event_count) == .FALSE) {
            switch (windows.GetLastError()) {
                else => |err| return windows.unexpectedError(err),
            }
        }

        return Event.fromInputRecord(input_record);
    }

    pub fn getEventNb(self: Self) !Event {
        var event_count: u32 = 0;
        var input_record = std.mem.zeroes(c.INPUT_RECORD);

        // Check if there are any input events available
        if (c.PeekConsoleInputW(self.stdin_handle, &input_record, 1, &event_count) == .FALSE) {
            switch (windows.GetLastError()) {
                else => |err| return windows.unexpectedError(err),
            }
        }

        // If no events are available, return null
        if (event_count == 0) {
            return Event{ .focus = false };
        }

        // Read the input event
        if (c.ReadConsoleInputW(self.stdin_handle, &input_record, 1, &event_count) == .FALSE) {
            switch (windows.GetLastError()) {
                else => |err| return windows.unexpectedError(err),
            }
        }

        // Return the event
        return Event.fromInputRecord(input_record);
    }

    pub fn viewportCoords(self: Self, coords: types.Coords, viewport_rect: ?types.Rect) !types.Coords {
        return types.Coords{ .x = coords.x, .y = coords.y - (viewport_rect orelse (try self.getScreenBufferInfo()).viewport_rect).top };
    }

    pub fn getScreenBufferInfo(self: Self) !types.ScreenBufferInfo {
        var bf = std.mem.zeroes(c.CONSOLE_SCREEN_BUFFER_INFO);

        if (c.GetConsoleScreenBufferInfo(self.stdout_handle, &bf) == .FALSE) {
            switch (windows.GetLastError()) {
                else => |err| return windows.unexpectedError(err),
            }
        }
        return types.ScreenBufferInfo{
            .size = @bitCast(bf.dwSize),
            .cursor_position = @bitCast(bf.dwCursorPosition),
            .attributes = @bitCast(bf.wAttributes),
            .viewport_rect = @bitCast(bf.srWindow),
            .max_window_size = @bitCast(bf.dwMaximumWindowSize),
        };
    }

    pub fn setConsoleTextAttribute(self: Self, attrs: c.CONSOLE_CHARACTER_ATTRIBUTES) !void {
        if (c.SetConsoleTextAttribute(self.stdout_handle, attrs) == .FALSE) {
            switch (windows.GetLastError()) {
                else => |err| return windows.unexpectedError(err),
            }
        }
    }
};
