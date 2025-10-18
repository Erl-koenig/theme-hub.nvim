local M = {}

function M.check()
  vim.health.start("theme-hub.nvim")

  -- Check Neovim version (>= 0.7.0)
  local nvim_version = vim.version()
  local required_version = { major = 0, minor = 7, patch = 0 }
  if vim.version.ge(nvim_version, required_version) then
    vim.health.ok(
      string.format("Neovim version %d.%d.%d is supported", nvim_version.major, nvim_version.minor, nvim_version.patch)
    )
  else
    vim.health.error(
      string.format(
        "Neovim version >= 0.7.0 required, found %d.%d.%d",
        nvim_version.major,
        nvim_version.minor,
        nvim_version.patch
      )
    )
  end

  -- Check plenary dependency
  local has_plenary = pcall(require, "plenary")
  if has_plenary then
    vim.health.ok("plenary.nvim is installed")
  else
    vim.health.error("plenary.nvim is required but not found")
  end

  -- Check optional lush dependency
  local has_lush = pcall(require, "lush")
  if has_lush then
    vim.health.ok("lush.nvim is installed")
  else
    vim.health.warn("lush.nvim is not installed, some themes may not work as expected")
  end

  -- Check git installation
  if vim.fn.executable("git") == 1 then
    vim.health.ok("git is installed")
  else
    vim.health.error("git is required but not found in PATH")
  end

  -- Check theme registry
  local has_registry, _ = pcall(require, "theme-hub.registry")
  if has_registry then
    vim.health.ok("registry.lua found")
  else
    vim.health.error("registry.lua not found")
  end

  -- Check persistent theme configuration
  local hub = require("theme-hub")
  if hub.config.persistent then
    vim.health.ok("persistent themes enabled")
    local persistent_theme = hub.get_persistent_theme()
    if persistent_theme then
      vim.health.ok("persistent theme set: " .. persistent_theme)
    else
      vim.health.warn("persistent themes enabled but no theme saved")
    end
  else
    vim.health.info("persistent themes disabled")
  end
end

return M
