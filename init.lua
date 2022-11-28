local lfs = require("lfs")
require('packer').startup(function(use)
    use "https://gitlab.com/yorickpeterse/nvim-window.git"
    use "folke/trouble.nvim"
    use "williamboman/mason.nvim"
    use "neovim/nvim-lspconfig"
    use "nvim-tree/nvim-tree.lua"
    use "nvim-treesitter/nvim-treesitter"
    use "easymotion/vim-easymotion"
    use "github/copilot.vim"
    use "wbthomason/packer.nvim"
    use "preservim/tagbar" -- exuberant-ctags
end)
require("trouble").setup({
    icons = false,
    fold_open = "",
    fold_closed = "",
    indent_lines = true,
    signs = {
        error = "E",
        warning = "W",
        hint = "H",
        information = "I",
        other = "O",
    },
}) --TODO refresh
local lspconfig = require("lspconfig")
lspconfig.pyright.setup{
    autostart = true,
}
require("mason").setup()
require("nvim-treesitter.configs").setup({
    ensure_installed = {"lua"}, --parsers
    indent = {enable = true},
    highlight = {enable = true}, --"I get query error: invalid node type at position" paragraph. Syntax highlighting 
})
require("nvim-tree").setup({ --TODO sync tab option
    open_on_setup_file = true, -- focus on file window rather than nvim-tree
    view = {
        relativenumber = true,
        number = true,
    },
    renderer = {
        highlight_opened_files = "names",
        icons = {-- To disable the display of icons see |renderer.icons.show|
            show = {
                git = true,
                folder = false,
                file = false,
                folder_arrow = false,
            },
        },
    },
    diagnostics = {
        enable = true,
        icons = {
            hint = "H",
            info = "I",
            warning = "W",
            error = "E",
        },
    },
})
-- config centered on github copilot
local options = {
    filetype = "on", --turned on filetype detection
    foldmethod = "expr",
    foldexpr = "nvim_treesitter#foldexpr()",
    foldnestmax = 1,
    clipboard = vim.opt.clipboard + "unnamedplus" + "unnamed", --TOFIX from repeat.vim page
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
local globals = {
    tagbar_show_linenumbers = 2, -- show relative line numbers in tagbar window
}
for k, v in pairs(globals) do
    vim.g[k] = v
end
local ex_cmds = {
    "command W w",
    "command Q q",
    "set cursorline cursorlineopt=screenline, number",
}
for _, v in pairs(ex_cmds) do
    vim.cmd(v)
end
-- partiallly accept GitHub copilot suggestion, word by word. TODO: add / and \
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
    {"nv", "<c-w>", "<cmd>:lua require('nvim-window').pick()<CR>", {}},
    {"nv", "<leader>p", '"+p', {noremap=true}}, --xclip?
    {"nv", "<leader>y", '"+y', {noremap=true}},
    {"nv", "c", '"_c', {noremap=true}},
    {"nv", "d", '"_d', {noremap=true}},
    {"nv", "x", '"_x', {noremap=true}},
    {"i", "<c-l>", partiallyAccept, {expr=true}},
    {"n", "<c-f>", smartIndent, {}},
    {"n", "<c-d>", function() updateLSP(lfs.currentdir(), 1) end, {}},
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
function updateLSP(path, depth)
    if depth == 0 then
        return
    end
    for file in lfs.dir(path) do 
        local f = path..'/'..file
        if file ~= "." and file ~= ".." and lfs.attributes(f).mode ~= "directory" then
            vim.cmd("vs " .. file)
            vim.cmd("close")
        end
    end
    vim.cmd("NvimTreeRefresh")
end
local autocmds = { -- TOSEE https://stackoverflow.com/questions/3837933/autowrite-when-changing-tab-in-vim
    --TODO NERDTree like, add commenter and system clipboard
    {{"TabNew"}, {pattern = "*", command=":TagbarOpen"}},
    {{"TabNew"}, {pattern = "*", command=":NvimTreeOpen"}},
    {{"VimEnter"}, {pattern =  {"*.lua", "*.py"}, command=":NvimTreeOpen"}},
    {{"VimEnter"}, {pattern = {"*.lua", "*.py"}, command=":TagbarOpen"}},
    {{"VimEnter"}, {pattern = {"*.lua", "*.py"}, command=":Trouble workspace_diagnostics"}},
    {{"CursorHoldI"}, {pattern = "*", command=":TagbarForceUpdate"}},
}
for _, v in pairs(autocmds) do
    vim.api.nvim_create_autocmd(unpack(v))
end
--for f in lfs.dir '.' do print(f) end -- TODO open and close tab and check if the file is already open and if the file is a directory
