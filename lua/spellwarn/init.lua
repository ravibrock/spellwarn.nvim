local M = {}
local defaults = {
    -- FIX: Trouble.nvim jump to diagnostic is slightly buggy with `TextChanged` event; no good workaround though AFAICT
    event = { -- event(s) to refresh diagnostics on
        "CursorHold",
        "InsertLeave",
        "TextChanged",
        "TextChangedI",
        "TextChangedP",
        "TextChangedT",
    },
    ft_config = { -- spellcheck method: "cursor", "iter", "treesitter", or boolean
        alpha   = false,
        help    = false,
        lazy    = false,
        lspinfo = false,
        mason   = false,
    },
    ft_default = true, -- whether to enable or disable for all filetypes by default
    max_file_size = nil, -- maximum file size to check in lines (nil for no limit)
    severity = { -- severity for each spelling error type (false to disable diagnostics for that type)
        spellbad   = "WARN",
        spellcap   = "HINT",
        spelllocal = "HINT",
        spellrare  = "INFO",
    },
    prefix = "possible misspelling(s): ", -- prefix for each diagnostic message
}

function M.setup(opts)
    -- With most options we want to overwrite the defaults, but with `severity` we want to extend
    local severity = defaults.severity
    opts = opts or {}
    defaults = vim.tbl_extend("force", defaults, opts)
    defaults.severity = vim.tbl_extend("force", severity, opts.severity or {})
    require("spellwarn.diagnostics").setup(defaults)
end

return M
