-- /usr/lib/lua/luci/controller/macblock.lua
module("luci.controller.macblock", package.seeall)

function index()
  local i18n = require "luci.i18n"
  -- List page
  entry({"admin","network","macblock"}, cbi("macblock"), i18n.translate("MAC Access Control"), 60).dependent = false
  -- Editor page
  entry({"admin","network","macblock","edit"}, cbi("macblock-detail")).leaf = true
end
