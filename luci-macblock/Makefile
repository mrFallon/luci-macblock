# OpenWrt package Makefile for luci-macblock
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-macblock
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_MAINTAINER:=mrFallon <ootdel03@ya.ru>
PKG_LICENSE:=BSD-2-Clause
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Quick temporary MAC Block for LuCI web UI
  URL:=https://github.com/mrFallon/luci-macblock
  DEPENDS:=+luci-base +kmod-nft-core +luci-compat +luci-lua-runtime
  LUCI_PKGARCH:=all
  PKGARCH:=all
  PKG_NAME:=Quick temporary MAC Block for LuCI web UI
  LUCI_TITLE:=Quick temporary MAC Block for LuCI web UI
  
endef

define Package/$(PKG_NAME)/description
 Quick temporary MAC Block for LuCI web UI
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	mkdir -p $(PKG_BUILD_DIR)
	# Copy sources (controller/model/view)
	[ -d "$(CURDIR)/controller" ] && cp -R "$(CURDIR)/controller" "$(PKG_BUILD_DIR)/" || true
	[ -d "$(CURDIR)/model" ] && cp -R "$(CURDIR)/model" "$(PKG_BUILD_DIR)/" || true
	[ -d "$(CURDIR)/view" ] && cp -R "$(CURDIR)/view" "$(PKG_BUILD_DIR)/" || true
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/macblock

	[ -d "$(PKG_BUILD_DIR)/controller" ] && $(CP) $(PKG_BUILD_DIR)/controller/*.lua $(1)/usr/lib/lua/luci/controller/ || true
	[ -d "$(PKG_BUILD_DIR)/model" ] && $(CP) $(PKG_BUILD_DIR)/model/*.lua $(1)/usr/lib/lua/luci/model/cbi/ || true
	[ -d "$(PKG_BUILD_DIR)/view/macblock" ] && $(CP) $(PKG_BUILD_DIR)/view/macblock/* $(1)/usr/lib/lua/luci/view/macblock/ || true
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] && [ "$$IPKG_INSTROOT" != "/" ] && exit 0
for svc in uhttpd nginx rpcd; do
	if [ -x "/etc/init.d/$$svc" ]; then
		/etc/init.d/$$svc reload 2>/dev/null || /etc/init.d/$$svc restart 2>/dev/null || true
	fi
done
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] && [ "$$IPKG_INSTROOT" != "/" ] && exit 0
for svc in uhttpd nginx; do
	if [ -x "/etc/init.d/$$svc" ]; then
		/etc/init.d/$$svc reload 2>/dev/null || true
	fi
done
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
