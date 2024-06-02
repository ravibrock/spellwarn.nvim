local M = {}
local defaults = {
    event = { "TextChanged", "TextChangedI", "TextChangedP", "TextChangedT" }, -- event(s) to refresh diagnostics on
    ft_config = { -- filetypes to override ft_default for
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
    if not opts then opts = {} end
    vim.tbl_deep_extend("force", defaults, opts)
    require("spellwarn.diagnostics").setup(defaults)
end

return M
