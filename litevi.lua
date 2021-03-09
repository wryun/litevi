--[[
This is currently quite close to the functionality of a327ex's modalediting with
easymotion stripped. However, it now relies on command predicates rather than
maintaining its own 'mode' state.
]]--

local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"
local CommandView = require "core.commandview"
local DocView = require "core.docview"
local style = require "core.style"
local config = require "core.config"
local common = require "core.common"
local translate = require "core.doc.translate"

local mode = "movement";

local function dv()
  return core.active_view
end

local function doc()
  return core.active_view.doc
end

local function is_real_docview()
  -- NB CommandView extends Docview, and we don't want that
  -- so we can't use :is() as normal.
  return getmetatable(dv()) == DocView
end

local function is_command_mode()
  return is_real_docview() and mode == "movement"
end

local function append_line_if_last_line(line)
  if line >= #doc().lines then
    doc():insert(line, math.huge, "\n")
  end
end

local modkey_map = {
  ["left ctrl"]   = "ctrl",
  ["right ctrl"]  = "ctrl",
  ["left shift"]  = "shift",
  ["right shift"] = "shift",
  ["left alt"]    = "alt",
  ["right alt"]   = "altgr",
}

local modkeys = { "ctrl", "alt", "altgr", "shift" }

local function key_to_stroke(k)
  local stroke = ""
  for _, mk in ipairs(modkeys) do
    if keymap.modkeys[mk] then
      stroke = stroke .. mk .. "+"
    end
  end
  return stroke .. k
end

function keymap.on_key_pressed(k)
  local mk = modkey_map[k]
  if mk then
    keymap.modkeys[mk] = true
    -- work-around for windows where `altgr` is treated as `ctrl+alt`
    if mk == "altgr" then
      keymap.modkeys["ctrl"] = false
    end
  else
    local stroke = key_to_stroke(k)
    local commands = keymap.map[stroke]
    if commands then
      for _, cmd in ipairs(commands) do
        local performed = command.perform(cmd)
        if performed then return true end
      end
    end
  end
  return false
end

local draw_line_body = DocView.draw_line_body

function DocView:draw_line_body(idx, x, y)
  local line, col = self.doc:get_selection()
  draw_line_body(self, idx, x, y)

  if mode == "movement" then
    if line == idx and core.active_view == self
    and system.window_has_focus() then
      local lh = self:get_line_height()
      local x1 = x + self:get_col_x_offset(line, col)
      local w = self:get_font():get_width(" ")
      renderer.draw_rect(x1, y, w, lh, style.caret)
    end
  end
end

command.add(is_real_docview, {
  ["modalediting:switch-to-command-mode"] = function()
    mode = "movement"
  end,
})

command.add(is_command_mode, {
  ["modalediting:missing-command"] = function()
    -- beep? prompt with help?
  end,

  ["modalediting:switch-to-insert-mode"] = function()
    mode = "insert"
  end,

  ["modalediting:insert-at-start-of-line"] = function()
    mode = "insert"
    command.perform("doc:move-to-start-of-line")
  end,

  ["modalediting:insert-at-end-of-line"] = function()
    mode = "insert"
    command.perform("doc:move-to-end-of-line")
  end,

  ["modalediting:insert-at-next-char"] = function()
    mode = "insert"
    local line, col = doc():get_selection()
    local next_line, next_col = translate.next_char(doc(), line, col)
    if line ~= next_line then
      doc():move_to(translate.end_of_line, dv())
    else
      if doc():has_selection() then
        local _, _, line, col = doc():get_selection(true)
        doc():set_selection(line, col)
      else
        doc():move_to(translate.next_char)
      end
    end
  end,

  ["modalediting:insert-on-newline-below"] = function()
    mode = "insert"
    command.perform("doc:newline-below")
  end,

  ["modalediting:insert-on-newline-above"] = function()
    mode = "insert"
    command.perform("doc:newline-above")
  end,

  ["modalediting:delete-line"] = function()
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      system.set_clipboard(text)
      doc():delete_to(0)
    else
      local line, col = doc():get_selection()
      doc():move_to(translate.start_of_line, dv())
      doc():select_to(translate.end_of_line, dv())
      if doc():has_selection() then
        local text = doc():get_text(doc():get_selection())
        system.set_clipboard(text)
        doc():delete_to(0)
      end
      local line1, col1, line2 = doc():get_selection(true)
      append_line_if_last_line(line2)
      doc():remove(line1, 1, line2 + 1, 1)
      doc():set_selection(line1, col1)
    end
  end,

  ["modalediting:delete-to-end-of-line"] = function()
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      system.set_clipboard(text)
      doc():delete_to(0)
    else
      doc():select_to(translate.end_of_line, dv())
      if doc():has_selection() then
        local text = doc():get_text(doc():get_selection())
        system.set_clipboard(text)
        doc():delete_to(0)
      end
    end
  end,

  ["modalediting:delete-word"] = function()
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      system.set_clipboard(text)
      doc():delete_to(0)
    else
      doc():select_to(translate.next_word_boundary, dv())
      if doc():has_selection() then
        local text = doc():get_text(doc():get_selection())
        system.set_clipboard(text)
        doc():delete_to(0)
      end
    end
  end,

  ["modalediting:delete-char"] = function()
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      system.set_clipboard(text)
      doc():delete_to(0)
    else
      doc():select_to(translate.next_char, dv())
      if doc():has_selection() then
        local text = doc():get_text(doc():get_selection())
        system.set_clipboard(text)
        doc():delete_to(0)
      end
    end
  end,

  ["modalediting:paste"] = function()
    local line, col = doc():get_selection()
    doc():insert(line, math.huge, "\n")
    doc():set_selection(line + 1, math.huge)
    doc():text_input(system.get_clipboard():gsub("\r", ""))
  end,

  ["modalediting:copy"] = function()
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      system.set_clipboard(text)
      local line, col = doc():get_selection()
      doc():move_to(function() return line, col end, dv())
    else
      local line, col = doc():get_selection()
      doc():move_to(translate.start_of_line, dv())
      doc():move_to(translate.next_word_boundary, dv())
      doc():select_to(translate.end_of_line, dv())
      if doc():has_selection() then
        local text = doc():get_text(doc():get_selection())
        system.set_clipboard(text)
      end
      doc():move_to(function() return line, col end, dv())
    end
  end,

  ["modalediting:end-of-line"] = function()
    if doc():has_selection() then
      doc():select_to(translate.end_of_line, dv())
    else
      command.perform("doc:move-to-end-of-line")
    end
  end,

  ["modalediting:indent"] = function()
    if doc():has_selection() then
      local line, col = doc():get_selection()
      local line1, col1, line2, col2 = doc():get_selection(true)
      for i = line1, line2 do
        doc():move_to(function() return i, 1 end, dv())
        doc():move_to(translate.start_of_line, dv())
        command.perform("doc:indent")
      end
      doc():move_to(function() return line, col end, dv())
    else
      local line, col = doc():get_selection()
      doc():move_to(translate.start_of_line, dv())
      command.perform("doc:indent")
      doc():move_to(function() return line, col end, dv())
    end
  end,
})


-- We need to add the predicate to these pass-through commands
-- (since the predicate is how we check that we're properly 'modal')
local function add_wrapped(cmds)
  for _, cmd in ipairs(cmds) do
    command.add(is_command_mode, {
      ["modalediting:" .. cmd] = function()
        command.perform(cmd)
      end,
    })
  end
end


add_wrapped({
  "find-replace:find",
  "find-replace:replace",
  "find-replace:repeat-find",
  "find-replace:previous-find",
  "doc:move-to-previous-line",
  "doc:move-to-next-line",
  "doc:move-to-previous-char",
  "doc:move-to-next-char",
  "doc:move-to-next-word-end",
  "doc:move-to-previous-word-start",
  "doc:move-to-start-of-line",
  "doc:move-to-previous-start-of-block",
  "doc:move-to-next-start-of-block",
  "doc:move-to-previous-page",
  "doc:move-to-next-page",
  "doc:move-to-end-of-doc",
  "doc:select-to-previous-line",
  "doc:select-to-next-line",
  "doc:select-to-previous-char",
  "doc:select-to-next-char",
  "doc:select-to-next-word-end",
  "doc:select-to-previous-word-start",
  "doc:select-to-start-of-line",
  "doc:select-to-previous-start-of-block",
  "doc:select-to-next-start-of-block",
  "doc:join-lines",
  "doc:undo",
  "doc:redo",
  "doc:unindent",
})

-- This function exists so we can fill in the other normal text input commands with
-- 'command not found'. If we don't do this, then these printables will appear as normal
-- input.
local function modal_keymap_addall(map)
  for i = 0x20, 0xFF do
    local c = string.char(i)
    if string.match(c, '%g') then
      if string.match(c, '%u') then
        c = 'shift+' .. string.lower(c)
      end
      if map[c] == nil then
        keymap.add { [c] = "modalediting:missing-command" }
      end
    end
  end

  keymap.add(map)
end


modal_keymap_addall {
  ["/"] = "modalediting:find-replace:find",
  ["r"] = "modalediting:find-replace:replace",
  ["n"] = "modalediting:find-replace:repeat-find",
  ["shift+n"] = "modalediting:find-replace:previous-find",
  ["g"] = "modalediting:go-to-line",

  ["k"] = "modalediting:doc:move-to-previous-line",
  ["j"] = "modalediting:doc:move-to-next-line",
  ["h"] = "modalediting:doc:move-to-previous-char",
  ["backspace"] = "modalediting:doc:move-to-previous-char",
  ["l"] = "modalediting:doc:move-to-next-char",
  ["w"] = "modalediting:doc:move-to-next-word-end",
  ["b"] = "modalediting:doc:move-to-previous-word-start",
  ["0"] = "modalediting:doc:move-to-start-of-line",
  ["shift+4"] = "modalediting:end-of-line",
  ["shift+g"] = "modalediting:doc:move-to-end-of-doc",
  ["["] = "modalediting:doc:move-to-previous-start-of-block",
  ["]"] = "modalediting:doc:move-to-next-start-of-block",
  ["ctrl+u"] = "modalediting:doc:move-to-previous-page",
  ["ctrl+d"] = "modalediting:doc:move-to-next-page",
  ["ctrl+b"] = "modalediting:doc:move-to-previous-page",
  ["ctrl+f"] = "modalediting:doc:move-to-next-page",
  ["shift+k"] = "modalediting:doc:select-to-previous-line",
  ["shift+j"] = "modalediting:doc:select-to-next-line",
  ["shift+h"] = "modalediting:doc:select-to-previous-char",
  ["shift+backspace"] = "modalediting:doc:select-to-previous-char",
  ["shift+l"] = "modalediting:doc:select-to-next-char",
  ["shift+w"] = "modalediting:doc:select-to-next-word-end",
  ["shift+b"] = "modalediting:doc:select-to-previous-word-start",
  ["shift+0"] = "modalediting:doc:select-to-start-of-line",
  ["shift+["] = "modalediting:doc:select-to-previous-start-of-block",
  ["shift+]"] = "modalediting:doc:select-to-next-start-of-block",

  ["i"] = "modalediting:switch-to-insert-mode",
  ["shift+i"] = "modalediting:insert-at-start-of-line",
  ["a"] = "modalediting:insert-at-next-char",
  ["shift+a"] = "modalediting:insert-at-end-of-line",
  ["o"] = "modalediting:insert-on-newline-below",
  ["shift+o"] = "modalediting:insert-on-newline-above",

  ["ctrl+j"] = "modalediting:doc:join-lines",
  ["u"] = "modalediting:doc:undo",
  ["ctrl+r"] = "modalediting:doc:redo",
  ["tab"] = "modalediting:indent",
  ["shift+tab"] = "modalediting:doc:unindent",
  ["shift+."] = "modalediting:indent",
  ["shift+,"] = "modalediting:doc:unindent",
  ["p"] = "modalediting:paste",
  ["y"] = "modalediting:copy",
  ["d"] = "modalediting:delete-line",
  ["e"] = "modalediting:delete-to-end-of-line",
  ["q"] = "modalediting:delete-word",
  ["x"] = "modalediting:delete-char",

  ["escape"] = "modalediting:switch-to-command-mode",
}
