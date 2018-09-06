--[[
  copyright (c) 2018 - Bill Ferguson <wpferguson@gmail.com>

  correct_lens - non-destructively modify lens information used by darktable
]]

local dt = require "darktable"
local du = require "lib/dtutils"

local PS = dt.configuration.running_os == "windows" and "\\" or "/"

local correct_lens = {}

local function get_preferences(group)
  dt.print_log("looking for " .. group)
  local prefs = {}
  local DARKTABLERC = dt.configuration.config_dir .. PS .. "darktablerc"
  local f = io.open(DARKTABLERC, "r")
  if f then
    for line in f:lines() do
      if string.match(line, group) then
        dt.print_log("found match in " .. line)
        line = string.gsub(line, group .. "/", "")
        dt.print_log("line minus lua stuff is " .. line)
        local parts = du.split(line, "=")
        dt.print_log("found lens " .. parts[1])
        if not parts[2] then
          parts[2] = ""
        end
        prefs[parts[1]] = parts[2]
        dt.print_log("set prefs[" .. parts[1] .. "] = " .. parts[2])
      end
    end
    f:close()
  else
    dt.print_error("Unable to open " .. DARKTABLERC)
  end
  return prefs
end

local function set_correct_lens_preference(lens, correction)
  dt.preferences.write("correct_lens", lens, "string", correction)
end

local function get_correct_lens_preference(lens)
  return dt.preferences.read("correct_lens", lens, "string")
end

local function update_combobox_choices(combobox, choice_table, selected)
  local items = #combobox
  local choices = #choice_table
  if choices == 0 then
    return
  end
  for i, name in ipairs(choice_table) do 
    combobox[i] = name
  end
  if choices < items then
    for j = items, choices + 1, -1 do
      combobox[j] = nil
    end
  end
  combobox.value = selected
end

local function escape_lens_string(lens)
  lens = string.gsub(lens, "%-", "%%-")
  lens = string.gsub(lens, "%.", "%%.")
  return lens
end

local function apply_lens_string(images)
  if #images > 0 then
    for _,image in ipairs(images) do
      if string.match(correct_lens.lenses, escape_lens_string(image.exif_lens)) then
       if correct_lens.lens_table[image.exif_lens]:len() > 0 then
          local tag_name = "correct_lens|original|" .. image.exif_lens
          local tag = dt.tags.create(tag_name)
          dt.tags.attach(tag, image)
          image.exif_lens = correct_lens.lens_table[image.exif_lens]
        end
      end
    end
  else
    dt.print("no images selected")
  end
end

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
--  main program
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

correct_lens.stack = dt.new_widget("stack"){}

correct_lens.selector_values = {}

correct_lens.entries = {}

correct_lens.lens_table = get_preferences("lua/correct_lens")

correct_lens.lenses = ""

correct_lens.sorted_lenses = {}

dt.print_log("lens_table entries are " .. #correct_lens.lens_table)


for k,v in pairs(correct_lens.lens_table) do
  table.insert(correct_lens.sorted_lenses, k)
end

table.sort(correct_lens.sorted_lenses)

if #correct_lens.sorted_lenses > 0 then

  count = 1
  for _,k in pairs(correct_lens.sorted_lenses) do
    local v = correct_lens.lens_table[k]
    dt.print_log("k is " .. k .. " and v is " .. v)
    correct_lens.lenses = correct_lens.lenses .. k .. "\n"
    correct_lens.selector_values[count] = k
    correct_lens.entries[count] = dt.new_widget("entry"){
      text = v,
      placeholder = "enter correct lens string",
      editable = true,
    }
    correct_lens.stack[count] = dt.new_widget("box"){
      correct_lens.entries[count],
      dt.new_widget("button"){
        label = "save",
        clicked_callback = function(self)
          dt.print_log("lens is " .. correct_lens.selector.value .. " and entry is " .. correct_lens.entries[correct_lens.selector.selected].text)
          set_correct_lens_preference(correct_lens.selector.value, correct_lens.entries[correct_lens.selector.selected].text)
        end
      },
      dt.new_widget("button"){
        label = "clear",
        tooltip = "clear stored string correction",
        clicked_callback = function(self)
          set_correct_lens_preference(correct_lens.selector.value, "")
          correct_lens.entries[correct_lens.selector.selected].text = ""
          correct_lens[correct_lens.selector.value] = ""
        end
      },
    }
    count = count + 1
  end

  correct_lens.selector = dt.new_widget("combobox"){
    label = "select lens",
    tooltip = "select lens to modify",
    value = 1, "placeholder",
    changed_callback = function(self)
      correct_lens.stack.active = self.selected
    end
  }

  update_combobox_choices(correct_lens.selector, correct_lens.selector_values, 1)

  correct_lens.lenses = string.sub(correct_lens.lenses, 1, -2)

  dt.print_log("known lenses are " .. correct_lens.lenses)

  dt.print_log("stack entries are " .. #correct_lens.stack)

  correct_lens.stack[#correct_lens.stack + 1] = dt.new_widget("box"){ orientation = "vertical", dt.new_widget("label"){label = "test"}}
  dt.print_log("stack entries are " .. #correct_lens.stack)

end

correct_lens.detected = dt.new_widget("text_view"){
  text = correct_lens.lenses,
  editable = false,
}

correct_lens.detect = dt.new_widget("button"){
  label = "detect lenses",
  tooltip = "get exif lens information from selected images",
  clicked_callback = function(self)
    if #dt.gui.action_images > 0 then
      for _,image in ipairs(dt.gui.action_images) do
        lens = image.exif_lens
        if not string.match(correct_lens.detected.text, escape_lens_string(lens)) then
          dt.print_log("didn't find " .. lens .. " in " .. correct_lens.detected.text)
          dt.print_log("found new lens " .. lens)
          correct_lens.lens_table[lens] = get_correct_lens_preference(lens)
          local l = du.split(correct_lens.detected.text, "\n")
          dt.print_log("number of values in l is " .. #l)
          table.insert(l, lens)
          table.sort(l)
          if #l > 1 then
            dt.print_log("l values is " .. #l)
            correct_lens.detected.text = du.join(l, "\n")
          else
            correct_lens.detected.text = l[1]
          end
        end
      end
    else
      dt.print("No images selected")
      dt.print_error("no images selected for lens detection")
    end
  end
}

correct_lens.apply = dt.new_widget("button"){
  label = "apply",
  tooltip = "apply lens correction strings to selected images",
  clicked_callback = function(self)
    apply_lens_string(dt.gui.action_images)
  end
}

correct_lens.revert = dt.new_widget("button"){
  label = "revert",
  tooltip = "revert lens correction strings to original",
  clicked_callback = function(self)
    if #dt.gui.action_images > 0 then
      dt.print_log("have action_images")
      for _,image in ipairs(dt.gui.action_images) do
        local tags = dt.tags.get_tags(image)
        for _,t in ipairs(tags) do
          if string.match(t.name, "correct_lens|original|") then
            local tname = string.gsub(t.name, "correct_lens|original|", "")
            dt.tags.detach(t, image)
            image.exif_lens = tname
          end
        end
      end
    else
      dt.print("no images selected")
    end
  end
}

if #correct_lens.sorted_lenses > 0 then
  correct_lens.widget = dt.new_widget("box"){
      orientation = "vertical",
      dt.new_widget("section_label"){ label = "known lenses" },
      correct_lens.detected,
      correct_lens.detect,
      dt.new_widget("section_label"){ label = "correct lens string" },
      correct_lens.selector,
      correct_lens.stack,
      dt.new_widget("section_label"){ label = "update selected images" },
      correct_lens.apply,
      correct_lens.revert,
  }
else
  correct_lens.widget = dt.new_widget("box"){
      orientation = "vertical",
      dt.new_widget("section_label"){ label = "known lenses" },
      correct_lens.detected,
      correct_lens.detect,
  }
end

-- register the lib


dt.register_lib(
  "correct_lens",     -- Module name
  "correct lens",     -- Visible name
  true,                -- expandable
  false,               -- resetable
  {[dt.gui.views.lighttable] = {"DT_UI_CONTAINER_PANEL_RIGHT_CENTER", 100}},   -- containers
  correct_lens.widget,
  nil,-- view_enter
  nil -- view_leave
)

--[[
    Add a button to the selected images module in lighttable
]]

dt.gui.libs.image.register_action(
  "correct lens information",
  function(event, images) apply_lens_string(images) end,
  "correct lens information"
)

--[[
    Add a shortcut
]]

dt.register_event(
  "shortcut",
  function(event, shortcut) apply_lens_string(dt.gui.action_images) end,
  "correct lens information"
)
