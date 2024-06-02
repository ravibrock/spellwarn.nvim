local M = {}
local namespace = vim.api.nvim_create_namespace("Spellwarn")

local function get_bufs_loaded()
    local bufs_loaded = {}
    for i, buf_hndl in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf_hndl) then
            bufs_loaded[i] = buf_hndl
        end
    end
    return bufs_loaded
end

-- PERF: try wrapping this with a function to make it run asynchronously?
function M.update_diagnostics(opts, bufnr)
    if opts.max_file_size and vim.api.nvim_buf_line_count(bufnr) > opts.max_file_size then return end
    local ft = vim.fn.getbufvar(bufnr, "&filetype")
    if opts.ft_config[ft] == false or (opts.ft_config[ft] == nil and opts.ft_default == false) then
        vim.diagnostic.reset(namespace, bufnr)
        return
    end

    local errors = require("spellwarn.spelling").get_spelling_errors(bufnr)
    local diags = {}
    for _, error in pairs(errors) do
        if opts.severity[error.type] then
            diags[#diags + 1] = {
                col      = error.col - 1, -- 0-indexed
                lnum     = error.lnum - 1, -- 0-indexed
                message  = opts.prefix .. error.word,
                severity = vim.diagnostic.severity[opts.severity[error.type]],
                source   = "spellwarn",
            }
        end
    end
    vim.diagnostic.reset(namespace, bufnr)
    vim.diagnostic.set(namespace, bufnr, diags)
end

function M.enable(opts)
    vim.api.nvim_create_augroup("Spellwarn", {})
    vim.api.nvim_create_autocmd(opts.event, {
        callback = function() M.update_diagnostics(opts, vim.fn.bufnr("%")) end,
        desc = "Update Spellwarn diagnostics",
    })
    for _, bufnr in pairs(get_bufs_loaded()) do
        M.update_diagnostics(opts, bufnr)
    end
end

function M.disable()
    vim.api.nvim_create_augroup("Spellwarn", {})
    for _, bufnr in pairs(get_bufs_loaded()) do
        vim.diagnostic.reset(namespace, bufnr)
    end
end

function M.setup(opts)
    vim.api.nvim_create_user_command(
        "Spellwarn",
        function(args)
            local arg = args.args
            if arg == "enable" then
                M.enable(opts)
            elseif arg == "disable" then
                M.disable()
            else
                vim.api.nvim_err_writeln("Invalid argument: " .. arg)
            end
        end,
        { nargs = 1, complete = function() return { "enable", "disable" } end }
    )
    M.enable(opts)
end

return M
