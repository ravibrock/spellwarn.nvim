local M = {}

function M.get_error_type(word, bufnr)
    return vim.api.nvim_buf_call(bufnr, function() -- Docs recommend to wrap as such
        return "spell" .. vim.spell.check(word)[1][2]
    end)
end

function M.get_spelling_errors(bufnr)
    -- Save current window view and create table to store errors
    local window = vim.fn.winsaveview()
    local errors = {}
    if string.find(vim.fn.getline(1), "spellwarn:disable", 1, true) ~= nil then return errors end

    -- Get location of first spelling error to start while loop
    vim.fn.setpos(".", { bufnr, 1, 1, 0 })
    local minpos = vim.fn.getpos(".")
    vim.cmd("silent normal! ]s")
    local location = vim.fn.getpos(".")

    local function check_spellwarn_comment() -- Check for spellwarn:disable* comments
        local current_line_number = vim.fn.line(".")
        local above = (current_line_number > 1 and vim.fn.getline(current_line_number - 1)) or ""
        local above_val = string.find(above, "spellwarn:disable-next-line", 1, true) ~= nil
        local cur = vim.fn.getline(current_line_number)
        local cur_val = string.find(cur, "spellwarn:disable-line", 1, true) ~= nil
        return above_val or cur_val
    end
    local function adjust_table() -- Add error to table
        if check_spellwarn_comment() then return end
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
    return errors
end

return M
