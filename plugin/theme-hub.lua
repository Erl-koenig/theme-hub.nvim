local hub = require("theme-hub")
local registry = require("theme-hub.registry")
local commands = { "install", "uninstall", "uninstall-all", "clear-persistent" }

local actions = { -- arg get passed implicitly to the functions as the first parameter
    install = hub.install,
    uninstall = hub.uninstall,
    ["uninstall-all"] = hub.uninstall_all,
    ["clear-persistent"] = function()
        hub.clear_persistent_theme()
        vim.notify("Persistent theme cleared", vim.log.levels.INFO)
    end,
}

local function filter_by_prefix(items, prefix)
    if prefix and prefix ~= "" then
        return vim.tbl_filter(function(item)
            return vim.startswith(item, prefix)
        end, items)
    end
    return items
end

vim.api.nvim_create_user_command("ThemeHub", function(opts)
    if #opts.fargs == 0 then
        hub.show()
        return
    end

    local cmd, arg = opts.fargs[1], opts.fargs[2]
    local action = actions[cmd]

    if action then
        action(arg)
    else
        vim.notify(
            "Unknown command. Usage: :ThemeHub [install|uninstall|uninstall-all|clear-persistent] <theme_name>",
            vim.log.levels.ERROR
        )
    end
end, {
    nargs = "*",
    complete = function(arg_lead, line)
        local args = vim.split(line, "%s+")
        -- First argument: suggest commands
        if #args == 2 then
            return filter_by_prefix(commands, arg_lead)
        end
        -- Second argument: suggest installed or all themes
        if #args >= 3 then
			local names = (args[2] == "uninstall") and hub.get_installed_themes() or registry
            names = vim.tbl_map(function(t) return t.name end, names)
            return filter_by_prefix(names, arg_lead)
        end
        return {}
    end,
})