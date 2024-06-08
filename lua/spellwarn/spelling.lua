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
    lines[1] = string.sub(lines[1], start_col + 1)
    lines[#lines] = string.sub(lines[#lines], 1, end_col + 1)
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
    vim.treesitter.get_parser(bufnr):parse(true)
    local node = vim.treesitter.get_node({ bufnr = 0, pos = { 0, 0 } })

    ---@diagnostic disable-next-line: redefined-local
    local function parserec(node)
        local start_row, start_col = node:start()
        local end_row, end_col = node:end_()
        for i = 0, node:child_count() - 1 do
            parserec(node:child(i))
        end
        -- TODO: This seems to be the bottleneck
        local spell = false
        for _, capture in pairs(vim.treesitter.get_captures_at_pos(bufnr, start_row, start_col)) do
            if capture.capture == "spell" then
                spell = true
                break
            end
        end
        if spell then
            for k, v in pairs(M.get_spelling_errors_iter(bufnr, start_row, start_col, end_row, end_col)) do
                errors[k] = v
            end
        end
    end

    while node do
        parserec(node)
        node = node:next_sibling()
    end

    return errors
end

return M
