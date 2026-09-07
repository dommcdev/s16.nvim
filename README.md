# s16.nvim

Neovim highlighting and assembler-backed diagnostics for Dr. Art Hanna's
FA2022 S16 assembly language. Requires Neovim 0.10+.

Highlights `.s16` files: instructions, segment/data directives, registers,
labels, decimal/hex numbers, booleans, strings, characters and `;` comments.
Keywords are case-insensitive, matching the assembler. Supports `""` inside
strings and `\'` character literals. Sets `commentstring` for Neovim's `gc`.

NOTE: This repo is 100% AI slop.

## Install with lazy.nvim

```lua
return {
  "dommcdev/s16.nvim",
  lazy = false,
  opts = {
    assembler = vim.fn.expand("~/path/to/s16/assembler"),
    debounce_ms = 500,
    timeout_ms = 3000,
  },
}
```

Replace `~/path/to/s16/assembler` with the path to your S16 assembler executable.

## Completion (blink.cmp)

Add this to your `saghen/blink.cmp` options:

```lua
sources = {
  per_filetype = { s16 = { "s16", "path" } },
  providers = { s16 = { name = "S16", module = "s16.blink" } },
},
```

Typing `SVC_R` offers matching names such as `SVC_READ_FROM_TERMINAL`,
with `EQU 300` in the completion details. Accepting inserts only the name.
Suggestions include all `EQU` definitions in the current buffer (including
unsaved edits) and `svcdefinitions.s16` beside the assembler or one directory
above it. Current-buffer definitions take precedence for the same name.
For a different location, add `definitions = vim.fn.expand("~/path/to/svcdefinitions.s16")`
to the S16 plugin options. External suggestions do not insert declarations;
the program still needs the corresponding `EQU` definition to assemble.

## Diagnostics

Checks run on opening a file, after edits (including insert mode), and on save.
`:S16Check` checks immediately. Diagnostics use Neovim's built-in diagnostic
API: underlines, gutter signs, `[d` / `]d`, and
`:lua vim.diagnostic.open_float()` for the full error message.
The actual appearance of underlines depends on your terminal and colorscheme.

Each check assembles a temporary copy of the current buffer, including unsaved
edits. Listing and object files stay in that temporary directory and are removed
afterward. The simulator is never invoked. Stale results are discarded.

Errors include invalid mnemonics/register operands, missing commas or `#`,
undefined/duplicate labels, and invalid data definitions. Missing segment headers
and END are checked before invoking the assembler. Diagnostics underline the
statement because the assembler reports lines, not columns. Validation otherwise
follows the course assembler, including its parsing limitations.

This is a lightweight diagnostic integration, not an LSP server; it does not
provide rename or go-to-definition. Definition-only snippets such as
`svcdefinitions.s16` receive missing-program-header diagnostics when opened alone.

## Test

```sh
S16_ASSEMBLER=~/path/to/s16/assembler nvim --headless -u NONE -l tests/check.lua
```
