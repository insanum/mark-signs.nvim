
local M = {}

local function is_upper(char)
    return (char:byte() >= 65 and char:byte() <= 90)
end

local function is_lower(char)
    return (char:byte() >= 97 and char:byte() <= 122)
end

local function is_letter(char)
    return is_upper(char) or is_lower(char)
end

-- 'mark_state.buffers' is an array of tables indexed by [bufnr] where each
-- table has the following keys:
--
-- 'placed_marks': A table of currently placed/registered marks in the buffer
-- indexed by [mark] name and contains information about mark position and
-- sign id.
--
-- 'marks_by_line': A table of lines that have marks on them indexed by [line]
-- number and contains an array of all marks currently set on that line.

local function delete_sign(bufnr, id)
    -- delete the sign
    vim.fn.sign_unplace("MarkSigns",
                        { buffer = bufnr,
                          id     = id })
end

local function delete_mark(mark, bufnr)
    local buffer = M.mark_state.buffers[bufnr]

    if not buffer or not buffer.placed_marks[mark] then
        return
    end

    -- delete the sign if it was previously placed
    if buffer.placed_marks[mark].id ~= -1 then
        delete_sign(bufnr, buffer.placed_marks[mark].id)
    end

    -- remove the mark from the marks_by_line table
    local line = buffer.placed_marks[mark].line
    for key, tmp_mark in pairs(buffer.marks_by_line[line]) do
        if tmp_mark == mark then
            buffer.marks_by_line[line][key] = nil
            break
        end
    end

    if vim.tbl_isempty(buffer.marks_by_line[line]) then
        buffer.marks_by_line[line] = nil
    end

    -- remove the mark from the placed_marks table
    buffer.placed_marks[mark] = nil
end

local function add_sign(bufnr, text, line, id)
    local priority

    if is_lower(text) then
        priority = M.mark_state.opt.priority[1]
    elseif is_upper(text) then
        priority = M.mark_state.opt.priority[2]
    else -- builtin
        priority = M.mark_state.opt.priority[3]
    end

    local sign_name = "Marks_" .. text

    -- if the sign doesn't yet exist it must be defined
    if not M.mark_state.sign_cache[sign_name] then
        M.mark_state.sign_cache[sign_name] = true
        vim.fn.sign_define(sign_name,
                           { text   = text,
                             texthl = "MarkSignsHL",
                             numhl  = "MarkSignsNumHL" })
    end

    -- add the sign
    vim.fn.sign_place(id, "MarkSigns", sign_name, bufnr,
                      { lnum     = line,
                        priority = priority })
end

local function add_mark(mark, line, col, bufnr)
    col = col or 1
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local buffer = M.mark_state.buffers[bufnr]

    if not buffer then
        return
    end

    -- delete the mark if it was previously placed
    if buffer.placed_marks[mark] then
        delete_mark(mark, bufnr)
    end

    -- add the mark to the marks_by_line table
    if buffer.marks_by_line[line] then
        table.insert(buffer.marks_by_line[line], mark)
    else
        buffer.marks_by_line[line] = { mark }
    end

    -- add the mark to the placed_marks table (id is -1 until the sign is placed)
    buffer.placed_marks[mark] = { line = line, col = col, id = -1 }

    -- add the sign with the numerical value of the mark for the id
    local id = mark:byte()
    buffer.placed_marks[mark].id = id
    add_sign(bufnr, mark, line, id)
end

local function do_refresh(force)
    local bufnr = vim.api.nvim_get_current_buf()

    -- if this buffer has not been seen yet, add it
    if not M.mark_state.buffers[bufnr] then
        M.mark_state.buffers[bufnr] = { placed_marks = {},
                                        marks_by_line = {}, }
    end

    -- first off delete all marks that no longer exist
    for mark, _ in pairs(M.mark_state.buffers[bufnr].placed_marks) do
        if vim.api.nvim_buf_get_mark(bufnr, mark)[1] == 0 then
            delete_mark(mark, bufnr)
        end
    end

    local mark
    local pos
    local cached_mark

    -- uppercase marks
    for _, data in ipairs(vim.fn.getmarklist()) do
        mark = data.mark:sub(2,3)
        pos = data.pos
        cached_mark = M.mark_state.buffers[bufnr].placed_marks[mark]

        -- Check for:
        -- . uppercase mark
        -- . mark located in current buffer
        -- . force is true or
        --   first time seeing mark or
        --   mark line position has changed
        if is_upper(mark) and (pos[1] == bufnr) and
           (force or not cached_mark or pos[2] ~= cached_mark.line) then
            add_mark(mark, pos[2], pos[3], bufnr)
        end
    end

    -- lowercase marks
    for _, data in ipairs(vim.fn.getmarklist("%")) do
        mark = data.mark:sub(2, 3)
        pos = data.pos
        cached_mark = M.mark_state.buffers[bufnr].placed_marks[mark]

        -- Check for:
        -- . lowercase mark
        -- . force is true or
        --   first time seeing mark or
        --   mark line position has changed
        if is_lower(mark) and
           (force or not cached_mark or pos[2] ~= cached_mark.line) then
            add_mark(mark, pos[2], pos[3], bufnr)
        end
    end

    -- builtin marks
    for _, char in pairs(M.mark_state.builtin_marks) do
        pos = vim.fn.getpos("'" .. char)
        cached_mark = M.mark_state.buffers[bufnr].placed_marks[char]

        -- Check for:
        -- . mark located in current buffer
        --   (0-9 marks return absolute bufnr instead of 0)
        -- . lnum != 0
        -- . force is true or
        --   first time seeing mark or
        --   mark line position has changed
        if (pos[1] == 0 or pos[1] == bufnr) and
            pos[2] ~= 0 and
            (force or not cached_mark or pos[2] ~= cached_mark.line) then
            add_mark(char, pos[2], pos[3], bufnr)
        end
    end
end

function M.set()
    local stat, input = pcall(function()
        return string.char(vim.fn.getchar())
    end)
    if stat == true and is_letter(input) then
        local bufnr = vim.api.nvim_get_current_buf()
        local pos = vim.api.nvim_win_get_cursor(0)
        add_mark(input, pos[1], pos[2], bufnr)
        vim.cmd("normal! m" .. input)
    end
end

function M.delete()
    local stat, input = pcall(function()
        return string.char(vim.fn.getchar())
    end)
    if stat == true and is_letter(input) then
        local bufnr = vim.api.nvim_get_current_buf()
        delete_mark(input, bufnr)
        vim.cmd("delmark " .. input)
    end
end

function M.refresh(force_reregister)
    force_reregister = force_reregister or false
    do_refresh(force_reregister)
end

function M.buf_delete()
    local bufnr = tonumber(vim.fn.expand("<abuf>"))
    if bufnr then
        M.mark_state.buffers[bufnr] = nil
    end
end

M.mappings = {
    set = "m",
    delete = "dm",
}

local function setup_mappings(config)
    if config.mappings then
        for cmd, key in pairs(config.mappings) do
            M.mappings[cmd] = nil
            if key ~= false then
                M.mappings[cmd] = key
            end
        end
    end

    -- apply the mappings
    for cmd, key in pairs(M.mappings) do
        if key then
            vim.cmd("nnoremap <silent> "..key.." <cmd>lua require('mark-signs')."..cmd.."()<cr>")
        end
    end
end

local function setup_autocommands()
    vim.cmd [[
        augroup Marks_autocmds
            autocmd!
            autocmd BufEnter * lua require('mark-signs').refresh(true)
            autocmd BufDelete * lua require('mark-signs').buf_delete()
        augroup end
    ]]
end

function M.setup(config)
    config = config or {}

    M.mark_state = setmetatable({ buffers = {}, opt = {}, sign_cache = {} },
                                { __index = Mark })
    M.mark_state.builtin_marks = config.builtin_marks or {}

    setup_mappings(config)
    setup_autocommands()

    M.mark_state.opt.priority = { 10, 10, 10 }
    local mark_priority = M.mark_state.opt.priority
    if type(config.sign_priority) == "table" then
        mark_priority[1] = config.sign_priority.lower or mark_priority[1]
        mark_priority[2] = config.sign_priority.upper or mark_priority[2]
        mark_priority[3] = config.sign_priority.builtin or mark_priority[3]
    elseif type(config.sign_priority) == "number" then
        mark_priority[1] = config.sign_priority
        mark_priority[2] = config.sign_priority
        mark_priority[3] = config.sign_priority
    end

    local refresh_interval = 150
    if config.refresh_interval then
        refresh_interval = config.refresh_interval
    end

    local timer = vim.uv.new_timer()
    timer:start(0, refresh_interval, vim.schedule_wrap(M.refresh))
end

return M

