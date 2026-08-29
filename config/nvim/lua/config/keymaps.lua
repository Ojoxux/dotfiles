-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap

keymap.set("n", "<C-d>", "<C-d>zz")
keymap.set("n", "<C-u>", "<C-u>zz")

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<cr>", { desc = "Close current split" })

keymap.set("n", "<leader><C-d>", ":resize +2<cr>", { desc = "Increase height" })
keymap.set("n", "<leader><C-u>", ":resize -2<cr>", { desc = "Decrease height" })
keymap.set("n", "<leader><C-h>", ":vertical resize -4<cr>", { desc = "Narrower" })
keymap.set("n", "<leader><C-l>", ":vertical resize +4<cr>", { desc = "Wider" })

-- buffer management
keymap.set("n", "<leader>H", "<cmd>BufferLineCyclePrev<cr>", { desc = "Go to previous buffer" })
keymap.set("n", "<leader>L", "<cmd>BufferLineCycleNext<cr>", { desc = "Go to next buffer" })
keymap.set("n", "<leader>x", "<cmd>bd<cr>", { desc = "Close current buffer" })
keymap.set("n", "<leader>n", "<cmd>tabnew<cr>", { desc = "New tab" })
keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- file explorer
keymap.set("n", "<leader><space>", "<cmd>Ex<cr>", { desc = "Open file explorer" })

keymap.set("n", "<leader>ci", function()
  vim.lsp.buf.incoming_calls()
end, { desc = "LSP incoming calls" })
keymap.set("n", "<leader>co", function()
  vim.lsp.buf.outgoing_calls()
end, { desc = "LSP outgoing calls" })
keymap.set("n", "<leader>ch", function()
  LazyVim.pick("lsp_implementations")()
end, { desc = "LSP implementations" })
keymap.set("n", "<leader>cu", function()
  LazyVim.pick("lsp_references")()
end, { desc = "LSP references" })

keymap.set("n", "<leader>ts", "<cmd>Theme<cr>", { desc = "Select theme" })
keymap.set("n", "<leader>tn", "<cmd>ThemeNext<cr>", { desc = "Next theme" })
keymap.set("n", "<leader>tp", "<cmd>ThemePrev<cr>", { desc = "Previous theme" })
