local M = {}
local hub = require("theme-hub")

-- helpers
local function cleanup_temp_dir(path)
	if vim.fn.isdirectory(path) == 1 then
		vim.fn.delete(path, "rf")
	end
end

local function finalize_installation(theme, install_path)
	vim.opt.runtimepath:append(install_path)
	
	hub.add_installed_theme({
		name = theme.name,
		install_path = theme.install_path or theme.name,
	})

	if hub.config.apply_after_install then
		M.apply(theme.custom_name or theme.name)
	else
		vim.notify("Installed: " .. theme.name, vim.log.levels.INFO)
	end
end

local function ensure_lush(theme_name)
	local lush_ok, _ = pcall(require, "lush")
	if not lush_ok then
		vim.notify(
			"Theme '"
				.. theme_name
				.. "' requires 'lush'. Install lush by uncommenting the dependency in your theme-hub config.",
			vim.log.levels.WARN
		)
		return false
	end
	return true
end

-- Install a theme (git clone and add to runtimepath)
function M.install(theme)
	local Job = require("plenary.job")
	local install_path = hub.config.install_dir .. "/" .. (theme.install_path or theme.name)
	local temp_path = install_path .. ".tmp"

	if theme.requires_lush and not ensure_lush(theme.name) then
		return
	end

	if vim.fn.isdirectory(install_path) == 1 then
		vim.notify("Theme already installed: " .. theme.name, vim.log.levels.INFO)
		return
	end

	-- clean up temp directory
	cleanup_temp_dir(temp_path)

	vim.notify("Installing " .. theme.name .. "...", vim.log.levels.INFO)

	-- Clone repo
	Job:new({
		command = "git",
		args = { "clone", "--depth=1", "https://github.com/" .. theme.repo, temp_path },
		on_exit = function(j, code)
			if code == 0 then
				vim.schedule(function()
					-- move temp directory to final location
					local rename_success = vim.fn.rename(temp_path, install_path)
					if rename_success == 0 then
						finalize_installation(theme, install_path)
					else
						cleanup_temp_dir(temp_path)
						vim.notify("Failed to install " .. theme.name .. ": Could not move to final location", vim.log.levels.ERROR)
					end
				end)
			else
				-- clone failed
				vim.schedule(function()
					cleanup_temp_dir(temp_path)
					vim.notify(
						"Failed to install " .. theme.name .. ": " .. table.concat(j:stderr_result(), "\n"),
						vim.log.levels.ERROR
					)
				end)
			end
		end,
	}):start()
end

-- applies the first variant
function M.apply(theme_name)
	local success, _ = pcall(function()
		vim.cmd.colorscheme(theme_name)
	end)
	if success then
		vim.notify("Applied: " .. theme_name, vim.log.levels.INFO)
		-- Save persistent theme if enabled
		hub.save_persistent_theme(theme_name)
	else
		vim.notify("Failed to apply: " .. theme_name .. ". Is it installed?", vim.log.levels.ERROR)
	end
end

function M.uninstall(theme_name, silent)
	local installed_themes = hub.get_installed_themes()

	local theme_to_remove = nil
	for _, theme in ipairs(installed_themes) do
		if theme.name == theme_name then
			theme_to_remove = theme
			break
		end
	end

	if not theme_to_remove then
		vim.notify("Theme not installed: " .. theme_name, vim.log.levels.ERROR)
		return
	end

	-- remove directory
	local install_path = hub.config.install_dir .. "/" .. theme_to_remove.install_path
	if vim.fn.isdirectory(install_path) == 1 then
		vim.fn.delete(install_path, "rf")
	end

	local new_installed_themes = vim.tbl_filter(function(theme)
		return theme.name ~= theme_name
	end, installed_themes)

	hub.save_installed_themes(new_installed_themes)
	if not silent then
		vim.notify("Uninstalled: " .. theme_name, vim.log.levels.INFO)
	end
end

return M
