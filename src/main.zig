const std = @import("std");
const Datetime = @import("zig-datetime").datetime.Datetime;

const readme_contents = @embedFile("./templates/readme_template.md");
const adr_contents = @embedFile("./templates/adr_template.md");
const help_contents = @embedFile("./templates/help.txt");
const template_readme_contents = @embedFile("./templates/readme_templates_folder.md");

const Command = enum { regen, create, help, unsupported };

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}

fn readFileIfExists(allocator: std.mem.Allocator, filepath: []const u8) !?[]u8 {
    const template_file = std.fs.cwd().openFile(filepath, .{}) catch return null;
    defer template_file.close();
    return try template_file.readToEndAlloc(allocator, std.math.maxInt(usize));
}

fn rebuildReadme(arena_alloc: std.mem.Allocator) !void {
    const template_contents = try readFileIfExists(arena_alloc, "./adr/templates/template_readme.md") orelse readme_contents;

    const date = try Datetime.now().formatHttp(arena_alloc);
    const output = try std.mem.replaceOwned(u8, arena_alloc, template_contents, "{{timestamp}}", date);
    const files = try getAllFilesInADRDir(arena_alloc);
    var formatted_files = std.ArrayList(u8).init(arena_alloc);

    std.mem.sort([]const u8, files.items, {}, compareStrings);

    for (files.items) |str| {
        const new_str = try std.fmt.allocPrint(arena_alloc, " - [{s}](./{s})\n", .{ str, str });
        try formatted_files.appendSlice(new_str);
    }

    const with_contents = try std.mem.replaceOwned(u8, arena_alloc, output, "{{contents}}", formatted_files.items);

    const f = try std.fs.cwd().createFile("./adr/README.md", .{});
    defer f.close();
    try f.writeAll(with_contents);
}

fn generateADR(arena_alloc: std.mem.Allocator, n: u64, name: []u8) !void {
    const padded_nums = try std.fmt.allocPrint(arena_alloc, "{:0>5}", .{n});
    const heading = try std.fmt.allocPrint(arena_alloc, "{s} - {s}", .{ padded_nums, name });

    const template_contents = try readFileIfExists(arena_alloc, "./adr/templates/template_adr.md") orelse adr_contents;
    const contents = try std.mem.replaceOwned(u8, arena_alloc, template_contents, "{{name}}", heading);

    const safe_name = try arena_alloc.dupe(u8, name);
    for (name) |*char| switch (char.*) {
        '/', '\\', ':', '*', '?', '"', '<', '>', '|' => char.* = ' ',
        else => {},
    };

    const file_name = try std.fmt.allocPrint(arena_alloc, "./adr/{s}-{s}.md", .{ padded_nums, safe_name });

    const f = try std.fs.cwd().createFile(file_name, .{});
    defer f.close();
    try f.writeAll(contents);
}

fn establishCoreFiles() !void {
    const cwd = std.fs.cwd();
    try cwd.makePath("./adr/assets");
    try cwd.makePath("./adr/templates");

    const f = try cwd.createFile("./adr/templates/README.md", .{});
    defer f.close();
    try f.writeAll(template_readme_contents);
}

fn getAllFilesInADRDir(allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
    var dir = try std.fs.cwd().openDir("./adr", .{ .iterate = true });
    defer dir.close();

    var file_list = std.ArrayList([]const u8).init(allocator);

    var dir_iterator = dir.iterate();
    while (try dir_iterator.next()) |entry| {
        if (!std.mem.eql(u8, entry.name, "README.md") and
            !std.mem.eql(u8, entry.name, "assets") and
            !std.mem.eql(u8, entry.name, "templates"))
        {
            const file_name = try allocator.dupe(u8, entry.name);
            try file_list.append(file_name);
        }
    }

    return file_list;
}

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_allocator.deinit();
    const allocator = debug_allocator.allocator();

    var arena: std.heap.ArenaAllocator = .init(allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    var args = try std.process.argsAlloc(arena_alloc);
    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();

    const action = if (args.len > 1) args[1] else "";
    const cmd = std.meta.stringToEnum(Command, action) orelse .unsupported;
    switch (cmd) {
        .create => {
            const name: []u8 = if (args.len > 2) try std.mem.join(arena_alloc, " ", args[2..]) else &.{};
            if (name.len == 0) {
                try stderr.print("No name supplied for the ADR.\nCommand should be: `adl create <Name of ADR here>`\n", .{});
                return;
            }

            try establishCoreFiles();
            const file_list = try getAllFilesInADRDir(arena_alloc);
            try generateADR(arena_alloc, file_list.items.len, name);
            try rebuildReadme(arena_alloc);
        },
        .regen => {
            try establishCoreFiles();
            try rebuildReadme(arena_alloc);
        },
        else => {
            stdout.writeAll(help_contents) catch @panic("Unable to write help contents");
        },
    }
}
