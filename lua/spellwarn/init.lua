local M = {}
local defaults = {
    event = "TextChanged", -- event(s) to refresh diagnostics on (could update to BufWritePost for performance)
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
        spellbad   = "WARNING",
        spellcap   = "HINT",
        spelllocal = "HINT",
        spellrare  = "INFO",
    },
    prefix = "possible misspelling: ", -- prefix for each diagnostic message
}

function M.setup(opts)
    if not opts then opts = {} end
    vim.tbl_deep_extend("force", defaults, opts)
    require("spellwarn.diagnostics").setup(defaults)
end

return M
