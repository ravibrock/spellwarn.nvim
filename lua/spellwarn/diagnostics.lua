local M = {}
local namespace = vim.api.nvim_create_namespace("Spellwarn")

local flag_text_changed = true -- Prevent updating when nothing was changed (CursorHold navigation, etc)

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
    if opts.max_file_size and vim.api.nvim_buf_line_count(bufnr) > opts.max_file_size then
        return
    end
    local diags = {}
    for _, error in pairs(require("spellwarn.spelling").get_spelling_errors_main(opts, bufnr) or {}) do
        local msg = error.word
        if opts.suggest and opts.num_suggest > 0 then
            local suggestions = vim.fn.spellsuggest(error.word, opts.num_suggest)
            local addition = "\nSuggestions:\n"
            for i = 1, opts.num_suggest do
                if suggestions[i] then
                    if i == opts.num_suggest then
                        addition = addition .. i .. ". " .. suggestions[i]
                    else
                        addition = addition .. i .. ". " .. suggestions[i] .. "\n"
                    end
                end
            end
            msg = msg .. addition
        end
        if error.word ~= "" and error.word ~= "spellwarn" then
            if opts.severity[error.type] then
                diags[#diags + 1] = {
                    col = error.col - 1, -- 0-indexed
                    lnum = error.lnum - 1, -- 0-indexed
                    message = opts.severity[error.type].prefix .. msg .. opts.severity[error.type].suffix,
                    severity = vim.diagnostic.severity[opts.severity[error.type].level],
                    source = "SpellWarn",
                }
            end
        end
    end

    -- Pre-process, if a function is set in opts to do anything.
    diags = opts.func_preprocess(bufnr, diags) or {}

    vim.diagnostic.set(namespace, bufnr, diags, opts.diagnostic_opts)
end

local function can_update(opts, bufnr)
    local winid = vim.api.nvim_get_current_win()
    if winid then
        if not vim.wo[winid].spell then
            return false
        end
    end

    -- Allow the buffer type, or file type, to cancel the attempt to process the buffer.
    local is_ok = true

    -- Buffer type check.
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
    if opts.bt_config[buftype] ~= nil then
        is_ok = opts.bt_config[buftype]
    else
        is_ok = opts.bt_default
    end

    if not is_ok then
        return false
    end
    -- Still OK to proceed.

    -- File type check.
    local ft = vim.fn.getbufvar(bufnr, "&filetype")
    if opts.ft_config[ft] ~= nil then
        is_ok = opts.ft_config[ft]
    else
        is_ok = opts.ft_default
    end

    return is_ok
end

function M.setup(opts)
    local group_name = "Spellwarn"
    function M.enable()
        vim.api.nvim_create_augroup(group_name, {})
        -- BufEnter to trigger an initial pass through.
        vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
            group = group_name,
            callback = function()
                flag_text_changed = true
            end,
        })

        vim.api.nvim_create_autocmd(opts.event, {
            group = group_name,
            callback = function()
                if not flag_text_changed then
                    return false
                end

                local bufnr = vim.fn.bufnr("%")
                if can_update(opts, bufnr) then
                    flag_text_changed = false
                    M.update_diagnostics(opts, bufnr)
                else
                    vim.diagnostic.reset(namespace, bufnr)
                end
            end,
            desc = "Update Spellwarn diagnostics",
        })
        for _, bufnr in pairs(get_bufs_loaded()) do
            M.update_diagnostics(opts, bufnr)
        end
        vim.g.spellwarn_enabled = true
    end

    function M.disable()
        vim.api.nvim_create_augroup("Spellwarn", {})
        for _, bufnr in pairs(get_bufs_loaded()) do
            vim.diagnostic.reset(namespace, bufnr)
        end
        vim.g.spellwarn_enabled = false
    end

    function M.toggle()
        if vim.g.spellwarn_enabled then
            M.disable()
        else
            M.enable()
        end
    end

    vim.api.nvim_create_user_command("Spellwarn", function(args)
        local arg = args.args
        if arg == "enable" then
            M.enable()
        elseif arg == "disable" then
            M.disable()
        elseif arg == "toggle" then
            M.toggle()
        elseif arg == "qflist" then
            require("spellwarn.qflist").qflist(opts)
        else
            vim.api.nvim_echo({ { "Invalid argument: " .. arg .. "\n" } }, true, { err = true })
        end
    end, {
        nargs = 1,
        complete = function()
            return { "disable", "enable", "toggle", "qflist" }
        end,
    })

    if opts.enable then
        M.enable()
    end
end

return M
