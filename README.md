# luci-macblock
Quick temporary MAC Block for LuCI web UI

# Build with OpenWrt SDK
Place this directory under `package/luci-macblock` inside your SDK/buildroot and run:

```
make defconfig
make package/luci-macblock/compile -j$(nproc)
```
Artifacts will appear under `bin/packages/*/*/`.
