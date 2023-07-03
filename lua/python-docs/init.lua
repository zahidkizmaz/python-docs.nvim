local M = {}

local function get_python_packages()
	local Job = require("plenary.job")

	local plugin_base_directory = vim.fn.fnamemodify(require("plenary.debug_utils").sourced_filepath(), ":h:h:h")
	local python_script_path = plugin_base_directory .. "/python/print_documentation_urls.py"
	local python_script_result = Job:new({
		command = "python3",
		args = { python_script_path },
	}):sync()
	-- Example result:
	-- {
	-- 	setuptools;Home-page;https://github.com/pypa/setuptools",
	-- 	setuptools;Documentation;https://setuptools.pypa.io/",
	-- 	setuptools;Changelog;https://setuptools.pypa.io/en/stable/history.html",
	-- 	pip;Home-page;https://pip.pypa.io/",
	-- 	pip;Documentation;https://pip.pypa.io",
	-- 	pip;Source;https://github.com/pypa/pip",
	-- 	pip;Changelog;https://pip.pypa.io/en/stable/news/",
	-- })
	return python_script_result
end

M.fzf_lua = function(opts)
	local has_fzf_lua, fzf_lua = pcall(require, "fzf-lua")
	if not has_fzf_lua then
		error("This plugin requires ibhagwan/fzf-lua")
	end

	return fzf_lua.fzf_exec(function(fzf_cb)
		for _, value in ipairs(get_python_packages()) do
			fzf_cb(value)
		end
		fzf_cb()
	end, {
		prompt = "Python docs> ",
		previewer = false,
		winopts = { height = 0.33, width = 0.66 },
		actions = {
			["default"] = function(selected)
				for _, value in ipairs(selected) do
					if selected == nil then
						return
					end

					local parts = vim.fn.split(value, ";")
					local package_url = parts[3]
					if opts.search then
						-- duckduckgo search for the rest
						local vstart = vim.fn.getpos("'<")
						local vend = vim.fn.getpos("'>")
						local line_start = vstart[2]
						local line_end = vend[2]
						local visual_selection = vim.fn.getline(line_start, line_end)[1]

						local url = require("url")
						local u = url.parse("http://duckduckgo.com/")
						u.query.q = "\\" .. visual_selection .. " site:" .. package_url
						vim.fn["netrw#BrowseX"](tostring(u), 0)
					else
						vim.fn["netrw#BrowseX"](package_url, 0)
					end
				end
			end,
		},
	})
end

return M
