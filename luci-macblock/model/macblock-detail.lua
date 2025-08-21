-- /usr/lib/lua/luci/model/cbi/macblock-detail.lua
local uci   = require "luci.model.uci".cursor()
local disp  = require "luci.dispatcher"
local i18n  = require "luci.i18n"
local http  = require "luci.http"
local sys   = require "luci.sys"
local json  = require "luci.jsonc"

local sid = arg[1]

-- Guard: section must exist
if not sid or not uci:get("macblock", sid) then
  local f = SimpleForm("macblock_missing",
    i18n.translate("Group not found"),
    i18n.translate("The requested group does not exist. Go back to the list and create it."))
  f.redirect = disp.build_url("admin","network","macblock")
  return f
end

-- Show current Group name (prefer value from form POST, then UCI, then SID)
local posted_name = http.formvalue("cbid.macblock." .. sid .. ".name")
local current_name = posted_name or uci:get("macblock", sid, "name") or sid

local m = Map("macblock", i18n.translatef("Edit group: %s", current_name))
m.redirect = disp.build_url("admin","network","macblock")

local s = m:section(NamedSection, sid, "group", i18n.translate("Group settings"))
s.addremove = false

-- Standard label
local name = s:option(Value, "name", i18n.translate("Group name"))
name.rmempty = false

-- Dynamic MAC list with server-side suggestions (WOL-style)
local macs = s:option(DynamicList, "mac", i18n.translate("MAC addresses"))
macs.datatype = "macaddr"
macs.placeholder = "AA:BB:CC:DD:EE:FF"


local function norm_mac(mac)
  if not mac then return nil end
  mac = mac:gsub("-", ":"):upper()
  if mac:match("^%x%x:%x%x:%x%x:%x%x:%x%x:%x%x$") then return mac end
  return nil
end

local function first_nonempty(...)
  local n = select("#", ...)
  for i = 1, n do
    local v = select(i, ...)
    if v and v ~= "" then return v end
  end
  return nil
end

-- Load host hints from luci-rpc (same source WOL uses)
local function load_host_hints()
  local out = sys.exec("ubus call luci-rpc getHostHints '{}' 2>/dev/null") or ""
  local data = json.parse(out)
  if type(data) == "table" then
    return data
  end
  return {}
end

local function hint_label_from_host(host)
  if type(host) ~= "table" then return nil end

  -- Typical fields in getHostHints:
  -- host = { name=?, mac=?, ipaddrs={...} or ipv4={...} or ipv6={...} }
  local ip4 = nil
  local ip6 = nil

  if type(host.ipaddrs) == "table" and host.ipaddrs[1] then
    ip4 = host.ipaddrs[1]
  end
  if type(host.ipv4) == "table" and host.ipv4[1] then
    ip4 = ip4 or host.ipv4[1]
  elseif type(host.ipv4) == "string" then
    ip4 = ip4 or host.ipv4
  end

  if type(host.ip6addrs) == "table" and host.ip6addrs[1] then
    ip6 = host.ip6addrs[1]
  end
  if type(host.ipv6) == "table" and host.ipv6[1] then
    ip6 = ip6 or host.ipv6[1]
  elseif type(host.ipv6) == "string" then
    ip6 = ip6 or host.ipv6
  end

  return first_nonempty(host.name, ip4, ip6)
end

local seen = {}

local function add_suggestion(mac, label)
  local nm = norm_mac(mac)
  if not nm or seen[nm] then return end
  macs:value(nm, (label and label ~= "" and string.format("%s (%s)", nm, label)) or nm)
  seen[nm] = true
end

-- 1) Primary source: luci-rpc host hints (as in WOL)
do
  local hints = load_host_hints()
  -- Usually it's a map keyed by MAC -> host table
  for k, v in pairs(hints) do
    if type(v) == "table" then
      local key_is_mac = norm_mac(k)
      local host_mac   = norm_mac(v.mac)
      local label      = hint_label_from_host(v) or "?"
      if key_is_mac then add_suggestion(key_is_mac, label) end
      if host_mac then add_suggestion(host_mac, label) end
    end
  end
end

-- 2) Fallback: DHCP leases
do
  local lf = io.open("/tmp/dhcp.leases", "r")
  if lf then
    for line in lf:lines() do
      -- <exp> <mac> <ip> <name> <id?>
      local _, mac, ip, host = line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
      local nm = norm_mac(mac)
      if nm and not seen[nm] then
        local lbl = (host and host ~= "*" and host) or ip
        add_suggestion(nm, lbl)
      end
    end
    lf:close()
  end
end

-- 3) Fallback: neighbors (ip neigh)  add any MAC we see, label with IP
do
  local out = sys.exec("ip -4 neigh show 2>/dev/null; ip -6 neigh show 2>/dev/null") or ""
  for ip, mac in out:gmatch("(%S+)%s+dev%s+%S+%s+lladdr%s+([%x:%-]+)") do
    add_suggestion(mac, ip)
  end
end

return m
