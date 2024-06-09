local M = {}

function M.get_error_type(word, bufnr)
    return vim.api.nvim_buf_call(bufnr, function() -- Docs recommend to wrap as such
        local check = vim.spell.check(word)
        -- If the word "is" spelled correctly, but is being flagged, it's a capitalization error
        return "spell" .. ((check[1] and check[1][2]) or "cap")
    end)
end

function M.check_spellwarn_comment(bufnr, linenr) -- Check for spellwarn:disable* comments
    local above = (linenr > 1 and vim.api.nvim_buf_get_lines(bufnr, linenr - 2, linenr - 1, false)[1]) or ""
    local above_val = string.find(above, "spellwarn:disable-next-line", 1, true) ~= nil
    local cur = vim.api.nvim_buf_get_lines(bufnr, linenr - 1, linenr, false)[1]
    local cur_val = string.find(cur, "spellwarn:disable-line", 1, true) ~= nil
    return above_val or cur_val
end

function M.get_spelling_errors_main(opts, bufnr)
    local bufopts = opts.ft_config[vim.o.filetype] or opts.ft_default
    local disable_comment =  string.find(vim.fn.getline(1), "spellwarn:disable", 1, true) ~= nil

    if disable_comment or not bufopts then
        return {}
    elseif bufopts == true or bufopts == "cursor" then
        return M.get_spelling_errors_cursor(bufnr)
    elseif bufopts == "iter" then
        return M.get_spelling_errors_iter(bufnr)
    elseif bufopts == "treesitter" then
        return M.get_spelling_errors_ts(bufnr)
    else
        error("Invalid value for ft_config: " .. bufopts)
    end
end

function M.get_spelling_errors_cursor(bufnr)
    -- Save current window view and create table to store errors
    local window = vim.fn.winsaveview()
    local foldstatus = vim.o.foldenable
    local concealstatus = vim.o.conceallevel
    local errors = {}

    -- Get location of first spelling error to start while loop
    vim.o.foldenable = false
    vim.o.conceallevel = 0
    vim.fn.setpos(".", { bufnr, 1, 2, 0 })
    local minpos = vim.fn.getpos(".")
    vim.cmd("silent normal! ]s")
    local location = vim.fn.getpos(".")

    local function adjust_table() -- Add error to table
        if M.check_spellwarn_comment(bufnr, vim.fn.line(".")) then return end
        local word = vim.fn.expand("<cword>")
        table.insert(errors, {
            col  = location[3],
            lnum = location[2],
            type = M.get_error_type(word, bufnr),
            word = word,
        })
    end

    -- Iterate through spelling errors and stop when you loop around to start
    while (minpos[2] < location[2]) or (minpos[2] == location[2] and minpos[3] < location[3]) do
        adjust_table()
        minpos = vim.fn.getpos(".")
        vim.cmd("silent normal! ]s")
        location = vim.fn.getpos(".")
    end

    -- Check for spelling errors in first word (edge case but would be ignored otherwise)
    if vim.fn.getpos(".")[2] == 1 and vim.fn.getpos(".")[3] == 1 then
        adjust_table()
    end

    -- Restore window view and return errors
    vim.fn.winrestview(window)
    vim.o.foldenable = foldstatus
    vim.o.conceallevel = concealstatus
    return errors
end

function M.get_spelling_errors_iter(bufnr, start_row, start_col, end_row, end_col)
    if start_row == nil then start_row = 0 end
    if start_col == nil then start_col = 0 end
    if end_row == nil then end_row = #(vim.api.nvim_buf_get_lines(bufnr, 1, -1, false)) + 1 end
    if end_col == nil then end_col = string.len(vim.api.nvim_buf_get_lines(bufnr, end_row - 1, end_row, false)[1]) end
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
    lines[#lines] = string.sub(lines[#lines], 1, end_col + 1)
    lines[1] = string.sub(lines[1], start_col + 1)
    local errors = {}
    for n, line in ipairs(lines) do
        local errs = vim.spell.check(line)
        for _, err in ipairs(errs) do
            local i = start_row + n
            local offset = (n == 1 and start_col) or 0
            local key = i .. (err[3] + offset) -- By inserting based on location, we avoid duplicates
            if not M.check_spellwarn_comment(bufnr, i) then
                errors[key] = {
                    lnum = i,
                    col = err[3] + offset,
                    word = err[1],
                    type = "spell" .. err[2],
                }
            end
        end
    end
    return errors
end

function M.get_spelling_errors_ts(bufnr)
    local errors = {}
    local ts_enabled = pcall(require, "nvim-treesitter")
    local buf_highlighter = ts_enabled and vim.treesitter.highlighter.active[bufnr]

    if not buf_highlighter then return M.get_spelling_errors_iter(bufnr) end
    buf_highlighter.tree:for_each_tree(function(tstree, tree)
        ---@diagnostic disable: invisible
        if not tstree then return end
        local root = tstree:root()

        local q = buf_highlighter:get_query(tree:lang())

        -- Some injected languages may not have highlight queries.
        if not q:query() then return end

        for capture, node in q:query():iter_captures(root, bufnr, 0, -1) do
            local c = q._query.captures[capture] -- Name of the capture in the query
            if c == "spell" then
                local start_row, start_col, end_row, end_col = node:range()
                for k, v in pairs(M.get_spelling_errors_iter(bufnr, start_row, start_col, end_row, end_col)) do
                    errors[k] = v
                end
            end
        end
        ---@diagnostic enable: invisible
    end)
    return errors
end

return M
