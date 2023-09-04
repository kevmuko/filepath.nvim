local M = require('lualine.component'):extend()

local modules = require('lualine_require').lazy_require({
  highlight = 'lualine.highlight',
  utils = 'lualine.utils.utils',
})

local default_options = {
  symbols = {
    default = '',
    modified = '●',
    readonly = '',
    unnamed = '[No Name]',
    separator = '',
  },
  highlights = {
    modified = 'Constant',
    readonly = 'NonText',
    separator = 'NonText',
  },
  path = 'relative',
  filestatus = true,
}

function M:init(options)
  M.super.init(self, options)

  self.options = vim.tbl_deep_extend('keep', self.options or {}, default_options)
  self.parts = {}
  self.hl_cache = {}
end

---@param text string
---@param hl_group string|nil
---@return string
function M:hl_text(text, hl_group)
  if not hl_group then
    return text
  end

  local hl = self.hl_cache[hl_group]
  if not hl then
    local color = modules.utils.extract_highlight_colors(hl_group, 'fg')
    if not color then
      return text
    end

    hl = self:create_hl({ fg = color }, hl_group)
    self.hl_cache[hl_group] = hl
  end
  return self:format_hl(hl) .. text .. self:get_default_hl()
end

---@param text string
---@param delim string
---@return table<string>
local function split(text, delim)
  delim = delim or ' '
  local pattern = string.format('([^%s]+)', delim)
  local fields = {}
  _ = string.gsub(text, pattern, function(c)
    fields[#fields + 1] = c
  end)
  return fields
end

function M:update_filepath()
  local path
  if self.options.path == 'relative' then
    path = vim.fn.expand('%:~:.')
  elseif self.options.path == 'absolute' then
    path = vim.fn.expand('%:p')
  elseif self.options.path == 'absolute_tilde' then
    path = vim.fn.expand('%:p:~')
  elseif self.options.path == 'fileonly' then
    path = vim.fn.expand('%:t')
  end
  path = modules.utils.stl_escape(path)

  local delim = package.config:sub(1, 1)
  self.parts = split(path, delim)

  if #self.parts == 0 then
    self.parts[1] = self.options.symbols.unnamed
  end
end

function M:update_fileicon()
  local icon, hl_group
  local ok, devicons = pcall(require, 'nvim-web-devicons')
  if ok then
    local f_name, f_ext = vim.fn.expand('%:t'), vim.fn.expand('%:e')
    f_ext = f_ext ~= '' and f_ext or vim.bo.filetype
    icon, hl_group = devicons.get_icon(f_name, f_ext)

    if icon == nil and hl_group == nil then
      icon = self.options.symbols.default
      hl_group = 'DevIconDefault'
    end
    icon = self:hl_text(icon, hl_group)
  else
    ok = vim.fn.exists('*WebDevIconsGetFileTypeSymbol')
    if ok ~= 0 then
      icon = vim.fn.WebDevIconsGetFileTypeSymbol()
    end
  end

  -- Prepend the icon next to the filename and update self.parts
  local filename = self.parts[#self.parts]
  self.parts[#self.parts] = icon .. ' ' .. filename
end

function M:update_filestatus()
  local filename = self.parts[#self.parts]

  if self.options.filestatus then
    if vim.bo.modified then
      filename = filename .. ' ' ..
          self:hl_text(self.options.symbols.modified, self.options.highlights.modified)
    end
    if vim.bo.modifiable == false or vim.bo.readonly == true then
      filename = filename .. ' ' ..
          self:hl_text(self.options.symbols.readonly, self.options.highlights.readonly)
    end
  end

  self.parts[#self.parts] = filename
end

---@return string
function M:update_status()
  self:update_filepath()
  self:update_fileicon()
  self:update_filestatus()

  local separator = self:hl_text(self.options.symbols.separator, self.options.highlights.separator)
  return table.concat(self.parts, ' ' .. separator .. ' ')
end

return M
