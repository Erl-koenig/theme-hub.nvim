local M = {}
local Path = require("plenary.path")

M.config = {
	install_dir = vim.fn.stdpath("data") .. "/theme-hub",
	auto_install_on_select = true,
	apply_after_install = true,
	persistent = false,
	-- computed in setup(), do not set manually
	installed_file = nil,
	persistent_theme_file = nil,
}

-- helpers
local function get_themes()
	return require("theme-hub.registry")
end

local function find_theme(theme_name)
	local themes = get_themes()
	for _, theme in ipairs(themes) do
		if theme.name == theme_name then
			return theme
		end
	end
	return nil
end

local function load_installed_themes()
	local installed_themes = M.get_installed_themes()
	for _, theme_info in ipairs(installed_themes) do
		local theme_path = M.config.install_dir .. "/" .. theme_info.install_path
		if vim.fn.isdirectory(theme_path) == 1 then
			vim.opt.runtimepath:append(theme_path)
		end
	end
end

local function load_persistent_theme()
	if not M.config.persistent then
		return
	end

	local persistent_theme = M.get_persistent_theme()
	if persistent_theme and persistent_theme ~= "" then
		-- schedule to run after startup to avoid conflicts
		vim.schedule(function()
			local success, _ = pcall(function()
				vim.cmd("colorscheme " .. persistent_theme)
			end)
			if not success then
				M.clear_persistent_theme() -- if theme fails to load, clear it
			end
		end)
	end
end

-- Public API
function M.get_installed_themes()
	local file = Path:new(M.config.installed_file)
	if not file:exists() then
		return {}
	end
	local ok, result = pcall(function()
		return vim.fn.json_decode(file:read())
	end)
	return ok and result or {}
end

function M.save_installed_themes(installed_themes)
	local installed_file = Path:new(M.config.installed_file)
	installed_file:write(vim.fn.json_encode(installed_themes), "w")
end

function M.get_persistent_theme()
	local file = Path:new(M.config.persistent_theme_file)
	if not file:exists() then
		return nil
	end
	local ok, result = pcall(function()
		return file:read():gsub("%s+", "") -- trim whitespace
	end)
	return ok and result or nil
end

function M.save_persistent_theme(theme_name)
	if not M.config.persistent then
		return
	end
	local persistent_file = Path:new(M.config.persistent_theme_file)
	persistent_file:write(theme_name, "w")
end

function M.clear_persistent_theme()
	local persistent_file = Path:new(M.config.persistent_theme_file)
	if persistent_file:exists() then
		persistent_file:rm()
	end
end

function M.add_installed_theme(theme_data)
	local installed = M.get_installed_themes()
	installed = vim.tbl_filter(function(t)
		return t.name ~= theme_data.name
	end, installed)
	table.insert(installed, theme_data)
	M.save_installed_themes(installed)
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {}) -- merge user opts
	M.config.installed_file = M.config.install_dir .. "/installed.json"
	M.config.persistent_theme_file = M.config.install_dir .. "/persistent_theme.txt"

	vim.fn.mkdir(M.config.install_dir, "p")
	load_installed_themes()
	load_persistent_theme()
end

function M.show()
	local ui = require("theme-hub.ui")
	ui.show_themes(get_themes())
end

function M.install(theme_name)
	if not theme_name then
		vim.notify("Specify a theme name", vim.log.levels.ERROR)
		return
	end

	local theme = find_theme(theme_name)
	if not theme then
		vim.notify("Theme not found: " .. theme_name, vim.log.levels.ERROR)
		return
	end

	local installer = require("theme-hub.installer")
	installer.install(theme)
end

function M.uninstall(theme_name)
	if not theme_name then
		vim.notify("Specify a theme name", vim.log.levels.ERROR)
		return
	end

	local installer = require("theme-hub.installer")
	installer.uninstall(theme_name)
end

function M.uninstall_all()
	local installed_themes = M.get_installed_themes()
	local count = #installed_themes

	if count == 0 then
		vim.notify("No themes installed", vim.log.levels.INFO)
		return
	end

	local max_display = 10
	local shown = vim.list_slice(installed_themes, 1, max_display)
	local display = vim.tbl_map(function(t)
		return "• " .. t.name
	end, shown)

	if count > max_display then
		table.insert(display, string.format("• ... and %d more", count - max_display))
	end

	local choice = vim.fn.confirm(
		string.format("Uninstall all %d themes?\n\n%s", count, table.concat(display, "\n")),
		"&Yes\n&No",
		2
	)

	if choice == 1 then
		local installer = require("theme-hub.installer")
		for _, theme in ipairs(installed_themes) do
			installer.uninstall(theme.name, true)
		end
		vim.notify("Uninstalled " .. count .. " themes", vim.log.levels.INFO)
	else
		vim.notify("Uninstall all cancelled", vim.log.levels.INFO)
	end
end

return M
