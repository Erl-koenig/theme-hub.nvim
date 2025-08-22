local M = {}
local installer = require("theme-hub.installer")
local hub = require("theme-hub")

local UI_CONSTANTS = {
	PADDING_EXTRA = 2,
	STATUS_INSTALLED = "✓",
	STATUS_NOT_INSTALLED = "-"
}

local function show_installed_theme_actions(theme, themes)
	local actions = {}

	if theme.variants and #theme.variants > 0 then
		for _, variant in ipairs(theme.variants) do
			table.insert(actions, {
				name = "Apply: " .. variant.display,
				action = function()
					installer.apply(variant.name)
				end,
			})
		end
	else
		table.insert(actions, {
			name = "Apply",
			action = function()
				installer.apply(theme.custom_name or theme.name)
			end,
		})
	end

	table.insert(actions, {
		name = "Uninstall",
		action = function()
			installer.uninstall(theme.name)
		end,
	})

	table.insert(actions, {
		name = "Back to overview",
		action = function()
			M.show_themes(themes)
		end,
	})

	vim.ui.select(actions, {
		prompt = "Actions for " .. theme.name,
		format_item = function(item)
			return item.name
		end,
	}, function(choice)
		if choice then
			choice.action()
		end
	end)
end

local function show_non_installed_theme_actions(theme, themes)
	local actions = {
		{
			name = "Install",
			action = function()
				installer.install(theme)
			end,
		},
		{
			name = "Back to overview",
			action = function()
				M.show_themes(themes)
			end,
		},
	}

	vim.ui.select(actions, {
		prompt = theme.name,
		format_item = function(item)
			return item.name
		end,
	}, function(choice)
		if choice then
			choice.action()
		end
	end)
end

function M.show_themes(themes)
	local installed_themes = hub.get_installed_themes()

	-- mark installed themes
	local installed_theme_names = {}
	for _, installed_theme in ipairs(installed_themes) do
		installed_theme_names[installed_theme.name] = true
	end

	-- get max length of theme names for padding
	local max_name_length = 0
	for _, theme in ipairs(themes) do
		max_name_length = math.max(max_name_length, #theme.name)
	end

	-- setup themes with installation status
	local theme_entries = {}
	for _, theme in ipairs(themes) do
		local is_installed = installed_theme_names[theme.name] or false
		table.insert(theme_entries, {
			theme = theme,
			is_installed = is_installed,
		})
	end

	-- sort themes: 1) installed themes 2) alphabetically
	table.sort(theme_entries, function(a, b)
		if a.is_installed == b.is_installed then
			return a.theme.name < b.theme.name
		end
		return a.is_installed
	end)

	vim.ui.select(theme_entries, {
		prompt = "Select a theme:",
		format_item = function(item)
			local theme = item.theme
			local status = item.is_installed and UI_CONSTANTS.STATUS_INSTALLED or UI_CONSTANTS.STATUS_NOT_INSTALLED
			local padding = string.rep(" ", max_name_length - #theme.name + UI_CONSTANTS.PADDING_EXTRA)
			return theme.name .. padding .. status .. " " .. theme.description
		end,
	}, function(choice)
		if not choice then
			return
		end

		local theme = choice.theme
		local is_installed = choice.is_installed

		if is_installed then
			show_installed_theme_actions(theme, themes)
		else
			if hub.config.auto_install_on_select then
				installer.install(theme)
			else
				show_non_installed_theme_actions(theme, themes)
			end
		end
	end)
end

return M
