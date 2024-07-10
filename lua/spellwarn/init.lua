local M = {}
local defaults = {
    -- FIX: Trouble.nvim jump to diagnostic is slightly buggy with `TextChanged` event; no good workaround though AFAICT
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
    prefix = "possible misspelling(s): ", -- prefix for each diagnostic message
    diagnostic_opts = { severity_sort = true }, -- options for diagnostic display
}

function M.setup(opts)
    -- With most options we want to overwrite the defaults, but with `severity` and `diagnostic_opts` we want to extend
    local diagnostic_opts = defaults.diagnostic_opts
    local severity = defaults.severity
    opts = opts or {}
    defaults = vim.tbl_extend("force", defaults, opts)
    defaults.diagnostic_opts = vim.tbl_extend("force", diagnostic_opts, opts.diagnostic_opts or {})
    defaults.severity = vim.tbl_extend("force", severity, opts.severity or {})
    require("spellwarn.diagnostics").setup(defaults)

    -- Expose public functions
    M.enable = require("spellwarn.diagnostics").enable
    M.disable = require("spellwarn.diagnostics").disable
    M.toggle = require("spellwarn.diagnostics").toggle
end

return M
