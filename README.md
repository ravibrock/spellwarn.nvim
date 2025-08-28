# Spellwarn.nvim

![example of spelling diagnostics](img/example.jpg)

This is a plugin to display spelling errors as diagnostics. Some language servers offer this as a feature, but they have several issues:

- By finding spelling separately from Neovim, they don't respect options like `spellfile` or `spelllang`.
- Their spelling mistakes don't align with Neovim's, which is a source of inconsistency.
- You can't use the default keybindings to add words to your spellfile.
- Neovim spelling works in nearly all filetypes, and is context-aware with Treesitter, whereas language servers like `ltex` only work for specific languages.

A simpler solution, therefore, is to use Neovim's existing spellchecking and diagnostics features. This is done by iterating through the flagged words in a buffer and passing them to `vim.diagnostic.set()`. Neovim is fast enough that this is ~instantaneous for most files. See below for installation and configuration instructions.

## Installation
I recommend using [Lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
    "ravibrock/spellwarn.nvim",
    event = "VeryLazy",
    config = true,
}
```
<details close>
<summary>Plugged</summary>

```lua
Plug('ravibrock/spellwarn.nvim')
```

</details>

Note that this uses Neovim's built-in spellchecking. This requires putting `vim.opt.spell = true` and `vim.opt.spelllang = [YOUR LANGUAGE HERE]` somewhere in your Neovim config if you haven't already. You may also want to add the word "spellwarn" to your Neovim dictionary. This can be done by putting the cursor onto "spellwarn" and hitting `zg`.

## Configuration
Pass any of the following options to `require("spellwarn").setup()`:
```lua
{
    event = { -- event(s) to refresh diagnostics on
        "CursorHold",
        "InsertLeave",
        "TextChanged",
        "TextChangedI",
        "TextChangedP",
    },
    enable = true, -- enable diagnostics on startup
    ft_config = { -- spellcheck method: "cursor", "iter", or boolean
        alpha   = false,
        help    = false,
        lazy    = false,
        lspinfo = false,
        mason   = false,
    },
    ft_default = true, -- default option for unspecified filetypes
    max_file_size = nil, -- maximum file size to check in lines (nil for no limit)
    severity = { -- severity for each spelling error type (false to disable diagnostics for that type)
        spellbad   = "WARN",
        spellcap   = "HINT",
        spelllocal = "HINT",
        spellrare  = "INFO",
    },
    suggest = false, -- show spelling suggestions in diagnostic message (works best with window-style message)
    num_suggest = 3, -- number of spelling suggestions shown in diagnostic message
    prefix = "possible misspelling(s): ", -- prefix for each diagnostic message
    diagnostic_opts = { severity_sort = true }, -- options for diagnostic display
}
```
Most options are overwritten (e.g. passing `ft_config = { python = false }` will mean that `alpha`, `mason`, etc. are set to true) but `severity` and `diagnostic_opts` are merged, so that (for example) passing `{ spellbad = "HINT" }` won't cause `spellcap` to be nil. You can pass any of `cursor`, `iter`, `treesitter`, `false`, or `true` as options to `ft_config`. The default method is `cursor`, which iterates through the buffer with `]s`. There is also `iter`, which uses Treesitter (if available) and the Lua API. Finally, `false` disables Spellwarn for that filetype and `true` uses the default (`cursor`). The `suggest` option adds spelling suggestions to the diagnostic message, it does not allow auto-complete. `num_suggest` specifies the number of suggestions to show in the diagnostic message. **If you have `suggest` set to `true`, you need to also have `num_suggest >= 1` or else you will have an error.**

*Note: `iter` doesn't show `spellcap` errors, but works well other than that. I recommend it.*

## Usage
The plugin should be good to go after installation with the provided snippet. It has sensible defaults. Run `:Spellwarn enable`, `:Spellwarn disable`, or `:Spellwarn toggle` to enable/disable/toggle during runtime (though this will *not* override `max_file_size`, `ft_config`, or `ft_default`). You can also add keybindings for any of these (one possible usecase would be disabling by default with the `enable` key of the configuration table and then only enabling when needed). To disable diagnostics on a specific line, add `spellwarn:disable-next-line` to the line immediately above or `spellwarn:disable-line` to a comment at the end of the line. To disable diagnostics in a file, add a comment with `spellwarn:disable` to the *first or second* line of the file.

## Lua API
The Lua API matches the arguments for the `Spellwarn` command:
- `require("spellwarn").disable()` to disable
- `require("spellwarn").enable()` to enable
- `require("spellwarn").toggle()` to toggle

## Contributing
PRs and issues welcome! Please use [Conventional Commits](https://www.conventionalcommits.org/) if submitting a pull request.
