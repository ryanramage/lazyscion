if vim.g.loaded_lazyscion then
  return
end
vim.g.loaded_lazyscion = true

vim.api.nvim_create_user_command('Lazyscion', function()
  require('lazyscion').toggle()
end, { desc = 'Open hyperscion (hs ui) in a floating terminal' })
