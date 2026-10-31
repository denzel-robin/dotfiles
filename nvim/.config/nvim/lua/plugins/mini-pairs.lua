return {
  "nvim-mini/mini.pairs",
  event = "InsertEnter", -- lazy-load when entering insert mode
  config = function()
    require("mini.pairs").setup()
  end,
}
