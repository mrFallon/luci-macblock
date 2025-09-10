-- /usr/lib/lua/luci/model/cbi/macblock.lua
local sys   = require "luci.sys"
local uci   = require "luci.model.uci".cursor()
local disp  = require "luci.dispatcher"
local i18n  = require "luci.i18n"
local fs    = require "nixio.fs"

-- Ensure config exists so the table isn't completely blank for first-time users
do
  local has_group = false
  uci:foreach("macblock", "group", function(s) has_group = true end)
  if not has_group then
    uci:section("macblock", "group", nil, { name = "Default group" })
    uci:save("macblock"); uci:commit("macblock")
  end
end

local m = Map("macblock", i18n.translate("MAC Access Control"),
  i18n.translate("List of MAC address groups. Click 'Create group' to add a new one. The 'Edit' button opens a page to modify the group name and MAC list.")
)

-- Inject page-scoped styles and footer log panel
m:append(Template("macblock/style"))
 
-- Section as table of groups
local s = m:section(TypedSection, "group", i18n.translate("Groups"))
s.template      = "cbi/tblsection"
s.addremove     = true
s.anonymous     = true
s.novaluetext   = i18n.translate("No groups yet — click 'Create group'.")
s.extedit       = disp.build_url("admin","network","macblock","edit","%s")

-- Display columns (order matters)
local col_name = s:option(DummyValue, "_name", i18n.translate("Name"))
col_name.rawhtml = true
function col_name.cfgvalue(self, section)
local name = uci:get("macblock", section, "name") or section
  return '<span style="font-size:2rem;font-weight:700;line-height:2">' ..
         luci.util.pcdata(name) .. '</span>'
end


local col_count = s:option(DummyValue, "_cnt", i18n.translate("MAC addresses"))
function col_count.cfgvalue(self, section)
  local list = uci:get_list("macblock", section, "mac") or {}
  return tostring(#list)
end

-- Place the visible Actions column HERE, where the old 'Disable' column used to be
local actions = s:option(DummyValue, "_actions", i18n.translate("Actions"))
actions.template    = "macblock/actions"

-- Hidden technical buttons after Actions; empty titles so no headers appear
local block = s:option(Button, "_block", "")
block.inputstyle    = "remove"
block.template      = "macblock/hidden"

local unblock = s:option(Button, "_unblock", "")
unblock.inputstyle  = "apply"
unblock.template    = "macblock/hidden"

-- ===== nft helpers =====
local function sanitize_label(label)
  return (label or ""):gsub('\"','\\\"')
end

local function get_group_label(section)
  return sanitize_label(uci:get("macblock", section, "name") or section or "group")
end

-- Delete existing rules for group by comment fw4mb_<group>; returns list of executed delete commands
local function delete_rules_for_group(comment_label)
  local target = "fw4mb_" .. (comment_label or "")
  local deleted = {}
  local fh = io.popen("nft -a list chain inet fw4 raw_prerouting 2>/dev/null")
  if fh then
    for line in fh:lines() do
      local c = line:match('comment%s+\"(.-)\"')
      local h = line:match('#%s*handle%s+(%d+)')
      if c == target and h then
        local del = "nft delete rule inet fw4 raw_prerouting handle " .. h
        sys.call(del .. " 2>/dev/null")
        deleted[#deleted+1] = del
      end
    end
    fh:close()
  end
  return deleted
end

-- Wire options so actions template can generate button names
actions.block_opt   = block
actions.unblock_opt = unblock

-- Button handlers (kept on hidden options)
function block.write(self, section)
  local list = uci:get_list("macblock", section, "mac") or {}
  if #list == 0 then return end

  local label = get_group_label(section)
  local comment = "fw4mb_" .. label
  local mac_set = "{" .. table.concat(list, ", ") .. "}"

  -- Clear previous rules, collect log
  local log = {}
  local deleted = delete_rules_for_group(label)
  for _, d in ipairs(deleted) do log[#log+1] = d end

  -- Build commands (quote comment with \")
  local cmd_rt = "nft add rule inet fw4 raw_prerouting ether saddr " .. mac_set .. " counter counter reject comment \\\"" .. comment .. "\\\""
  
  -- Execute
  sys.call(cmd_rt .. " 2>/dev/null")

  -- Log footer
  log[#log+1] = cmd_rt
  fs.writefile("/tmp/macblock_last_cmds", "Group: " .. (label or "") .. "\n" .. table.concat(log, "\n") .. "\n")
end

function unblock.write(self, section)
  local label = get_group_label(section)
  local deleted = delete_rules_for_group(label)
  if #deleted > 0 then
    fs.writefile("/tmp/macblock_last_cmds", "Group: " .. (label or "") .. "\n" .. table.concat(deleted, "\n") .. "\n")
  else
    fs.writefile("/tmp/macblock_last_cmds", "Group: " .. (label or "") .. "\n(no matching rules found)\n")
  end
end

-- Footer log panel
m:append(Template("macblock/log"))

return m
