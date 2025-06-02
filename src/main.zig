const std = @import("std");
const cwd = std.fs.cwd;
const eql = std.mem.eql;
const Datetime = @import("zig-datetime").datetime.Datetime;

const readme_contents = @embedFile("./templates/readme_template.md");
const adr_contents = @embedFile("./templates/adr_template.md");
const help_contents = @embedFile("./templates/help.txt");
const template_readme_contents = @embedFile("./templates/readme_templates_folder.md");

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.ascii.orderIgnoreCase(lhs, rhs).compare(std.math.CompareOperator.lt);
}

fn rebuildReadme(arena_alloc: std.mem.Allocator) !void {
    const files = try getAllFilesInADRDir(arena_alloc);
    std.mem.sort([]const u8, files, {}, compareStrings);

    var formatted_files = std.ArrayList(u8).init(arena_alloc);
    for (files) |str| {
        const new_str = try std.fmt.allocPrint(arena_alloc, " - [{s}](./{s})\n", .{ str, str });
        try formatted_files.appendSlice(new_str);
    }

    var template_contents = cwd().readFileAlloc(arena_alloc, "./adr/templates/template_readme.md", 1e10) catch readme_contents;
    template_contents = try std.mem.replaceOwned(u8, arena_alloc, template_contents, "{{timestamp}}", try Datetime.now().formatHttp(arena_alloc));
    template_contents = try std.mem.replaceOwned(u8, arena_alloc, template_contents, "{{contents}}", formatted_files.items);
    try cwd().writeFile(.{ .sub_path = "./adr/README.md", .data = template_contents });
}

fn generateADR(arena_alloc: std.mem.Allocator, n: u64, name: []const u8) !void {
    const padded_num = try std.fmt.allocPrint(arena_alloc, "{:0>5}", .{n});
    const heading = try std.fmt.allocPrint(arena_alloc, "{s} - {s}", .{ padded_num, name });

    const template_contents = cwd().readFileAlloc(arena_alloc, "./adr/templates/template_adr.md", 1e10) catch adr_contents;
    const contents = try std.mem.replaceOwned(u8, arena_alloc, template_contents, "{{name}}", heading);

    const safe_name = try arena_alloc.dupe(u8, name);
    for (safe_name) |*char| switch (char.*) {
        '/', '\\', ':', '*', '?', '"', '<', '>', '|' => char.* = ' ',
        else => {},
    };

    const file_path = try std.fmt.allocPrint(arena_alloc, "./adr/{s}-{s}.md", .{ padded_num, safe_name });
    try cwd().writeFile(.{ .sub_path = file_path, .data = contents });
}

fn establishCoreFiles() !void {
    try cwd().makePath("./adr/assets");
    try cwd().makePath("./adr/templates");
    try cwd().writeFile(.{ .sub_path = "./adr/templates/README.md", .data = template_readme_contents });
}

fn getAllFilesInADRDir(allocator: std.mem.Allocator) ![][]const u8 {
    var dir = try cwd().openDir("./adr", .{ .iterate = true });
    defer dir.close();

    var file_list = std.ArrayList([]const u8).init(allocator);
    var dir_iterator = dir.iterate();
    while (try dir_iterator.next()) |entry| {
        if (!eql(u8, entry.name, "README.md") and !eql(u8, entry.name, "assets") and !eql(u8, entry.name, "templates"))
            try file_list.append(try allocator.dupe(u8, entry.name));
    }

    return file_list.toOwnedSlice();
}

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    var args = try std.process.argsAlloc(arena_alloc);
    const command_arg = if (args.len > 1) args[1] else "";

    const Command = enum { regen, create, help, unsupported };
    const cmd = std.meta.stringToEnum(Command, command_arg) orelse .unsupported;
    switch (cmd) {
        .create => {
            if (args.len <= 2) std.process.fatal("No name supplied for the ADR.\nCommand should be: `adl create <Name of ADR here>`\n", .{});
            const name: []u8 = try std.mem.join(arena_alloc, " ", args[2..]);

            try establishCoreFiles();
            const file_list = try getAllFilesInADRDir(arena_alloc);
            try generateADR(arena_alloc, file_list.len, name);
            try rebuildReadme(arena_alloc);
        },
        .regen => {
            try establishCoreFiles();
            try rebuildReadme(arena_alloc);
        },
        .help, .unsupported => try std.io.getStdOut().writeAll(help_contents),
    }
}
