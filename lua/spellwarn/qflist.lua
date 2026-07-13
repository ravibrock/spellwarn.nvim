local M = {}

function M.qflist(opts)
    local spelling = require("spellwarn.spelling").get_spelling_errors_main(opts, 0)
    local list = {}

    for _, mistake in ipairs(spelling) do
        local qf_item = {
            bufnr = vim.api.nvim_get_current_buf(),
            col = mistake.col,
            lnum = mistake.lnum,
            text = opts.severity[mistake.type].prefix .. mistake.word .. opts.severity[mistake.type].suffix,
        }
        list[#list + 1] = qf_item
    end
    vim.fn.setqflist(list, "r")
    vim.cmd("copen")
end

return M
