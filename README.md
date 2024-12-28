# lsp-sample-extractor.nvim

A Neovim plugin to extract and export a code sample along with a lot of info from LSP.

Example:

Let's say you want to put the following code snippet into your blogpost.

```zig
pub fn main() void {
    std.log.err("Hello {s}", .{global});
}
```

You can do so with this plugin. Simply select the lines with Visual-line mode and
call `<Plug>(lsp_sample_get)` (bound to `<leader>lx` by default).
The following JSON will be copied to the clipboard:

<details>
  <summary>Output</summary>
```json
{
  "range": [
    41,
    44
  ],
  "tokens": [
    {
      "end_col": 3,
      "type": "keyword",
      "line": 41,
      "modifiers": [],
      "client_id": 1,
      "marked": true,
      "start_col": 0
    },
    {
      "end_col": 7,
      "type": "namespace",
      "line": 42,
      "modifiers": [],
      "client_id": 1,
      "marked": true,
      "start_col": 4
    },
    {
      "end_col": 11,
      "type": "namespace",
      "line": 42,
      "modifiers": [],
      "client_id": 1,
      "marked": true,
      "start_col": 8
    },
    {
      "end_col": 15,
      "type": "function",
      "line": 42,
      "modifiers": {
        "generic": true
      },
      "client_id": 1,
      "marked": true,
      "start_col": 12
    },
    {
      "end_col": 27,
      "type": "string",
      "line": 42,
      "modifiers": [],
      "client_id": 1,
      "marked": true,
      "start_col": 16
    }
  ],
  "version": "1",
  "hover": [
    {
      "range": {
        "start": {
          "line": 42,
          "character": 4
        },
        "end": {
          "line": 42,
          "character": 7
        }
      },
      "contents": {
        "kind": "markdown",
        "value": "\n\n```zig\nconst std = @import(\"std\")\n```\n```zig\n(type)\n```"
      }
    },
    {
      "range": {
        "start": {
          "line": 42,
          "character": 8
        },
        "end": {
          "line": 42,
          "character": 11
        }
      },
      "contents": {
        "kind": "markdown",
        "value": " std.log is a standardized interface for logging which allows for the logging\n of programs and libraries using this interface to be formatted and filtered\n by the implementer of the `std.options.logFn` function.\n\n Each log message has an associated scope enum, which can be used to give\n context to the logging. The logging functions in std.log implicitly use a\n scope of .default.\n\n A logging namespace using a custom scope can be created using the\n std.log.scoped function, passing the scope as an argument; the logging\n functions in the resulting struct use the provided scope parameter.\n For example, a library called 'libfoo' might use\n `const log = std.log.scoped(.libfoo);` to use .libfoo as the scope of its\n log messages.\n\n An example `logFn` might look something like this:\n\n ```\n const std = @import(\"std\");\n\n pub const std_options = .{\n     // Set the log level to info\n     .log_level = .info,\n\n     // Define logFn to override the std implementation\n     .logFn = myLogFn,\n };\n\n pub fn myLogFn(\n     comptime level: std.log.Level,\n     comptime scope: @Type(.enum_literal),\n     comptime format: []const u8,\n     args: anytype,\n ) void {\n     // Ignore all non-error logging from sources other than\n     // .my_project, .nice_library and the default\n     const scope_prefix = \"(\" ++ switch (scope) {\n         .my_project, .nice_library, std.log.default_log_scope => @tagName(scope),\n         else => if (@intFromEnum(level) <= @intFromEnum(std.log.Level.err))\n             @tagName(scope)\n         else\n             return,\n     } ++ \"): \";\n\n     const prefix = \"[\" ++ comptime level.asText() ++ \"] \" ++ scope_prefix;\n\n     // Print the message to stderr, silently ignoring any errors\n     std.debug.lockStdErr();\n     defer std.debug.unlockStdErr();\n     const stderr = std.io.getStdErr().writer();\n     nosuspend stderr.print(prefix ++ format ++ \"\\n\", args) catch return;\n }\n\n pub fn main() void {\n     // Using the default scope:\n     std.log.debug(\"A borderline useless debug log message\", .{}); // Won't be printed as log_level is .info\n     std.log.info(\"Flux capacitor is starting to overheat\", .{});\n\n     // Using scoped logging:\n     const my_project_log = std.log.scoped(.my_project);\n     const nice_library_log = std.log.scoped(.nice_library);\n     const verbose_lib_log = std.log.scoped(.verbose_lib);\n\n     my_project_log.debug(\"Starting up\", .{}); // Won't be printed as log_level is .info\n     nice_library_log.warn(\"Something went very wrong, sorry\", .{});\n     verbose_lib_log.warn(\"Added 1 + 1: {}\", .{1 + 1}); // Won't be printed as it gets filtered out by our log function\n }\n ```\n Which produces the following output:\n ```\n [info] (default): Flux capacitor is starting to overheat\n [warning] (nice_library): Something went very wrong, sorry\n ```\n\n```zig\nconst log = @import(\"log.zig\")\n```\n```zig\n(type)\n```"
      }
    },
    {
      "range": {
        "start": {
          "line": 42,
          "character": 12
        },
        "end": {
          "line": 42,
          "character": 15
        }
      },
      "contents": {
        "kind": "markdown",
        "value": " Log an error message using the default scope. This log level is intended to\n be used when something has gone wrong. This might be recoverable or might\n be followed by the program exiting.\n\n Log an error message. This log level is intended to be used\n when something has gone wrong. This might be recoverable or might\n be followed by the program exiting.\n\n```zig\nfn err(\n            comptime format: []const u8,\n            args: anytype,\n        ) void\n```"
      }
    }
  ],
  "code": "pub fn main() void {\n    std.log.err(\"Hello {s}\", .{global});\n}"
}
```
</details>

As you can see, the snippet contains semantic tokens and hover information from the
LSP server. You can parse this information in your code block component and provide your readers with
exactly the same information you see in your editor!
That includes:
- imports from other files
- all the active LSPs in your buffer


---

## Installation

As of now, no options are available.

- lazy.nvim:
`"Sekky61/lsp-sample-extractor.nvim"`

---

## Usage

basic usage instructions:  
- how to activate the plugin  
- key features walkthrough  

---

## Commands

list and explain plugin-specific commands:  
- `:CommandName` - what it does  

---

## Keybindings

recommend keybindings:  
- `<leader>x` - triggers a specific feature  

---

## Dependencies

The plugin has no dependencies.

---

## FAQ

Common questions and issues:  
- X

---

## Contributions Welcome

contributions are welcome and greatly appreciated! if you have an idea for improvement, find a bug, or want to add a feature, feel free to open an issue and submit a pull request.

---

## License

this plugin is licensed under the mit license. you're free to use, modify, and distribute the code as long as the original license and copyright notice are included. see the license file for full details.
