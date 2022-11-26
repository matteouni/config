require('packer').startup(function(use)
    use "nvim-treesitter/nvim-treesitter"
    use "easymotion/vim-easymotion"
    use "github/copilot.vim"
    use "wbthomason/packer.nvim"
    --use "" -- exuberant-ctags
end)

require("nvim-treesitter.configs").setup({
    ensure_installed = {"lua"}, --parsers
})

-- config centered on github copilot
local options = {
    foldmethod = "expr",
    foldexpr = "nvim_treesitter#foldexpr()",
    clipboard = vim.opt.clipboard + "unnamedplus" + "unnamed",
    expandtab = true,
    hlsearch = false,
    iskeyword = vim.opt.iskeyword + "-" + "_",
    number = true,
    pumheight = 7,
    relativenumber = true,
    scrolloff = 999,
    shiftwidth = 4, -- Number of spaces to use for each step of (auto)indent
    showmode = false,
    smartindent = true, -- Do smart autoindenting when starting a new line
    softtabstop = 4, -- Number of spaces that a <Tab> counts for while performing editing operations
    tabstop = 4, -- Number of spaces that a <Tab> in the file counts for
    updatetime = 200,
}
for k, v in pairs(options) do
    vim.opt[k] = v
end

-- partiallly accept GitHub copilot suggestion, word by word
local function partiallyAccept()
    local _ = vim.fn['copilot#Accept']("")
    local suggestion = vim.fn['copilot#TextQueuedForInsertion']()
    return vim.fn.split(suggestion,  [[[ .]\zs]])[1] -- the word can be separated by space or by the dot char
end

local function smartIndent()
    local currLine, currCol = unpack(vim.api.nvim_win_get_cursor(0))
    --! => nore
    vim.api.nvim_command("normal! gg=G")
    vim.api.nvim_command("normal! " .. currLine .. "G")
end
-- TODO indent mode
local keymaps = { -- :h modes
{"nv", "<leader>p", '"+p', {noremap=true}},
{"nv", "<leader>y", '"+y', {noremap=true}},
{"nv", "c", '"_c', {noremap=true}},
{"nv", "d", '"_d', {noremap=true}},
{"nv", "x", '"_x', {noremap=true}},
{"i", "<c-l>", partiallyAccept, {expr=true}},
{"n", "<c-f>", smartIndent, {}},
{"nov", "F" , "<Plug>(easymotion-Fl)", {}},
{"nov", "T" , "<Plug>(easymotion-Tl)", {}},
{"nov", "t" , "<Plug>(easymotion-tl)", {}},
{"nov", "f" , "<Plug>(easymotion-fl)", {}},
}

local function keymap(modes, key, value, opts)
    for i=1, string.len(modes) do
        local mode = string.sub(modes, i, i)
        vim.keymap.set(mode, key, value, opts)
    end
end

for _, v in pairs(keymaps) do
    keymap(unpack(v))
end
