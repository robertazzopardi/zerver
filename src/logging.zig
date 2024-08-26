const std = @import("std");

pub fn logger_fn(
    comptime level: std.log.Level,
    comptime _: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const prefix = "[" ++ comptime level.asText() ++ "] ";

    // Print the message to stderr, silently ignoring any errors
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();
    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(prefix ++ format ++ "\n", args) catch return;
}

const month_names = [_][]const u8{ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };

/// Logs in the common log format
///
/// host ident authuser date request status bytes
/// 127.0.0.1 user-identifier frank [10/Oct/2000:13:55:36 -0700] "GET /apache_pb.gif HTTP/1.0" 200 2326
pub fn common_log(host: []const u8, request_line: []const u8, response_status: u9, bytes_returned: usize) []const u8 {
    const date_time = get_current_time();

    const formatted_log = std.fmt.allocPrint(std.heap.page_allocator, "{s} {s} {s} {s} \"{s}\" {d} {d}", .{
        host,
        "-",
        "-",
        date_time,
        request_line,
        response_status,
        bytes_returned,
    });

    return formatted_log catch "-";
}

fn get_current_time() []const u8 {
    const now = std.time.timestamp();

    var epoch_seconds = std.time.epoch.EpochSeconds{ .secs = @intCast(now) };
    const epoch_day = epoch_seconds.getEpochDay();
    const year_day = epoch_day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();

    const day_seconds = @mod(epoch_seconds.secs, std.time.s_per_day);
    const hours = @divFloor(day_seconds, std.time.s_per_hour);
    const minutes = @divFloor(@mod(day_seconds, std.time.s_per_hour), std.time.s_per_min);
    const seconds = @mod(day_seconds, std.time.s_per_min);

    // TODO: get the timezone info
    const date_time = std.fmt.allocPrint(std.heap.page_allocator, "[{d:0>2}/{s}/{d:0>4}:{d:0>2}:{d:0>2}:{d:0>2} -0000]", .{
        month_day.day_index + 1,
        month_names[month_day.month.numeric() - 1],
        year_day.year,
        hours,
        minutes,
        seconds,
    }) catch "-";

    return date_time;
}
