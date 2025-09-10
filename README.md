# luci-macblock
Quick temporary WAN MAC Block for OpenWRT LuCI web UI

Only for nftables (OpenWRT v22 and upper). Optimized for phone view.

# Build with OpenWrt SDK
Place this directory under `package/luci-macblock` inside your SDK/buildroot and run:

```
make defconfig
make package/luci-macblock/compile -j$(nproc)
```
Artifacts will appear under `bin/packages/*/*/`.

# HowTo delete rules for group in single string
nft -a list chain inet fw4 raw_prerouting | grep -F '"fw4mb_*GroupNAME*"' | sed -n 's/.*# handle \\([0-9]\\+\\)$/\1/p' | xargs -r -n1 nft delete rule inet fw4 raw_prerouting handle

# HowTo schedule block
You can use cron with command in executed commands and unblock using command upper

