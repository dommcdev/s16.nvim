# s16.nvim

Neovim highlighting and assembler-backed diagnostics for Dr. Art Hanna's
FA2022 S16 assembly language. Requires Neovim 0.10+.

Highlights `.s16` files: instructions, segment/data directives, registers,
labels, decimal/hex numbers, booleans, strings, characters and `;` comments.
Keywords are case-insensitive, matching the assembler. Supports `""` inside
strings and `\'` character literals. Sets `commentstring` for Neovim's `gc`.

## Install with lazy.nvim

```lua
return {
  dir = vim.fn.expand("~/dev/projects/s16.nvim"),
  name = "s16.nvim",
  lazy = false,
  opts = {
    assembler = vim.fn.expand("~/dev/courses/operating-systems/s16/bin/s16assembler"),
    debounce_ms = 500,
    timeout_ms = 3000,
  },
}
```

Build the course assembler if necessary, from its `s16/` directory:

```sh
mkdir -p bin
gcc -std=c11 -o bin/s16assembler s16assembler.c labeltable.c
```

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
provide completion, rename, or go-to-definition. Definition-only snippets such as
`svcdefinitions.s16` receive missing-program-header diagnostics when opened alone.

## Test

```sh
S16_ASSEMBLER=/absolute/path/to/s16/bin/s16assembler nvim --headless -u NONE -l tests/check.lua
```
