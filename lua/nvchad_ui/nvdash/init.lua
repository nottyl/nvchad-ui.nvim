local M = {}
local api = vim.api
local fn = vim.fn

-- dofile(vim.g.base46_cache .. "nvdash
-- ")

local options = require("nvchad_ui.config").options.nvdash
local is_lazyvim = require("nvchad_ui.config").options.lazyVim

local headerAscii = options.header
local emmptyLine = string.rep(" ", vim.fn.strwidth(headerAscii[1]))

table.insert(headerAscii, 1, emmptyLine)
table.insert(headerAscii, 2, emmptyLine)

headerAscii[#headerAscii + 1] = emmptyLine
headerAscii[#headerAscii + 1] = emmptyLine

api.nvim_create_autocmd("BufWinLeave", {
    callback = function()
        if vim.bo.ft == "nvdash" then
            vim.g.nvdash_displayed = false
        end
    end,
})

local nvdashWidth = #headerAscii[1] + 2

local max_height = #headerAscii + 4 + #options.buttons -- 4  = extra spaces i.e top/bottom
local get_win_height = api.nvim_win_get_height
local footer = "⚡ Neovim loading "

M.open = function(buf)
    if vim.fn.expand "%" == "" or buf then
        buf = buf or api.nvim_create_buf(false, true)
        ---@type integer | nil
        local win = nil
        local was_lazy_open = false

        -- close windows i.e splits
        for _, winnr in ipairs(api.nvim_list_wins()) do
            if api.nvim_win_is_valid(winnr) then
                if win == nil and api.nvim_win_get_config(winnr).relative == "" then
                    win = winnr
                    api.nvim_win_set_buf(win, buf)
                end
                local bufnr = api.nvim_win_get_buf(winnr)
                was_lazy_open = vim.bo[bufnr].ft == "lazy" or was_lazy_open
                if api.nvim_buf_is_valid(bufnr) and win ~= winnr then
                    api.nvim_win_close(winnr, api.nvim_win_get_config(winnr).relative == "")
                end
            end
        end

        -- This should not happen but lets handle it anyway
        if win == nil then return end

        vim.opt_local.filetype = "nvdash"
        vim.g.nvdash_displayed = true

        local header = headerAscii
        local buttons = options.buttons

        local function addSpacing_toBtns(txt1, txt2)
            local btn_len = fn.strwidth(txt1) + fn.strwidth(txt2)
            local spacing = fn.strwidth(header[1]) - btn_len
            return txt1 .. string.rep(" ", spacing - 1) .. txt2 .. " "
        end

        local function addPadding_toHeader(str)
            ---@type number
            local pad = (api.nvim_win_get_width(win) - fn.strwidth(str)) / 2
            return string.rep(" ", math.floor(pad)) .. str .. " "
        end

        ---@type string[]
        local dashboard = {}

        for _, val in ipairs(header) do
            table.insert(dashboard, val .. " ")
        end

        for _, val in ipairs(buttons) do
            table.insert(dashboard, addSpacing_toBtns(val[1], val[2]) .. " ")
            table.insert(dashboard, header[1] .. " ")
        end
        if is_lazyvim then
            table.insert(dashboard, header[1] .. " ")
            table.insert(dashboard, footer)
            table.insert(dashboard, header[1] .. " ")
            max_height = max_height + 4
        else
            table.insert(dashboard, header[1] .. " ")
            table.insert(dashboard, footer)
            table.insert(dashboard, header[1] .. " ")
            max_height = max_height + 4
        end

        ---@type string[]
        local result = {}

        -- make all lines available
        for i = 1, math.max(get_win_height(win), max_height) do
            result[i] = ""
        end

        local headerStart_Index = math.abs(math.floor((get_win_height(win) / 2) - (#dashboard / 2))) +
            1                                                                              -- 1 = To handle zero case
        local abc = math.abs(math.floor((get_win_height(win) / 2) - (#dashboard / 2))) +
        1                                                                                  -- 1 = To handle zero case

        -- set ascii
        for _, val in ipairs(dashboard) do
            result[headerStart_Index] = addPadding_toHeader(val)
            headerStart_Index = headerStart_Index + 1
        end

        api.nvim_buf_set_lines(buf, 0, -1, false, result)

        local nvdash = api.nvim_create_namespace "nvdash"
        local horiz_pad_index = math.floor((api.nvim_win_get_width(win) / 2) - (nvdashWidth / 2)) - 2

        for i = abc, abc + #header - 2 do
            api.nvim_buf_add_highlight(buf, nvdash, "NvDashAscii", i, horiz_pad_index, -1)
        end

        for i = abc + #header - 2, is_lazyvim and abc + #dashboard - 5 or abc + #dashboard - 1 do
            api.nvim_buf_add_highlight(buf, nvdash, "NvDashButtons", i, horiz_pad_index, -1)
        end
        if is_lazyvim then
            for i = abc + #dashboard - 4, abc + #dashboard - 2 do
                api.nvim_buf_add_highlight(buf, nvdash, "NvDashNoiceStats", i, horiz_pad_index, -1)
            end
        end

        api.nvim_win_set_cursor(win, { abc + #header, math.floor(vim.o.columns / 2) - 13 })

        local first_btn_line = abc + #header + 2
        local keybind_lineNrs = {}

        for _, _ in ipairs(options.buttons) do
            table.insert(keybind_lineNrs, first_btn_line - 2)
            first_btn_line = first_btn_line + 2
        end

        vim.keymap.set("n", "h", "", { buffer = true })
        vim.keymap.set("n", "<Left>", "", { buffer = true })
        vim.keymap.set("n", "l", "", { buffer = true })
        vim.keymap.set("n", "<Right>", "", { buffer = true })

        local function upward_movement()
            local cur = fn.line "."
            local target_line = keybind_lineNrs[1] >= cur and keybind_lineNrs[#keybind_lineNrs] or cur - 2
            api.nvim_win_set_cursor(win, { target_line, math.floor(vim.o.columns / 2) - 13 })
        end

        local function downward_movement()
            local cur = fn.line "."
            local target_line = keybind_lineNrs[#keybind_lineNrs] <= cur and keybind_lineNrs[1] or cur + 2
            api.nvim_win_set_cursor(win, { target_line, math.floor(vim.o.columns / 2) - 13 })
        end

        vim.keymap.set("n", "k", upward_movement, { buffer = true })

        vim.keymap.set("n", "<Up>", upward_movement, { buffer = true })

        vim.keymap.set("n", "j", downward_movement, { buffer = true })

        vim.keymap.set("n", "<Down>", downward_movement, { buffer = true })

        -- Set single keystroke keymaps if available
        for i, _ in ipairs(keybind_lineNrs) do
            local keymap = options.buttons[i][2] or ""
            if keymap:len() == 1 then
                vim.keymap.set("n", keymap, function()
                    local action = options.buttons[i][3]
                    if type(action) == "string" then
                        vim.cmd(action)
                    elseif type(action) == "function" then
                        action()
                    end
                end, { buffer = true, silent = true, nowait = true })
            end
        end

        -- pressing enter on
        vim.keymap.set("n", "<CR>", function()
            for i, val in ipairs(keybind_lineNrs) do
                if val == fn.line "." then
                    local action = options.buttons[i][3]

                    if type(action) == "string" then
                        vim.cmd(action)
                    elseif type(action) == "function" then
                        action()
                    end
                end
            end
        end, { buffer = true })

        -- buf only options
        vim.opt_local.buflisted = false
        vim.opt_local.modifiable = false
        vim.opt_local.number = false
        vim.opt_local.list = false
        vim.opt_local.relativenumber = false
        vim.opt_local.wrap = false
        vim.opt_local.cul = false

        if was_lazy_open then require("lazy").show() end
    end
end

M.lazyVim_callback = function()
    local stats = require("lazy").stats()
    local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
    footer = "⚡ Neovim loaded " .. stats.count .. " plugins in " .. ms .. "ms"
    if options.load_on_startup then
        vim.schedule(function()
            local buf_lines = vim.api.nvim_buf_get_lines(0, 0, 1, false)
            local no_buf_content = vim.api.nvim_buf_line_count(0) == 1 and buf_lines[1] == ""
            local bufname = vim.api.nvim_buf_get_name(0)

            if bufname == "" and no_buf_content then
                M.open()
            end
        end, 0)
    end
end

return M
