# luci-macblock
Quick temporary WAN MAC Block for OpenWRT LuCI web UI

Only for nftables (OpenWRT v22 and upper). Optimized for phone view.

# Build with OpenWrt SDK
Place this directory under `package/luci-macblock` inside your SDK/buildroot and run:

```
git clone https://github.com/mrFallon/luci-macblock.git package/luci-macblock
make defconfig
make package/luci-macblock/compile -j$(nproc)
```
Artifacts will appear under `bin/packages/*/*/`.

# HowTo delete rules for group in single string
nft -a list chain inet fw4 raw_prerouting | grep -F '"fw4mb_*GroupNAME*"' | sed -n 's/.*# handle \\([0-9]\\+\\)$/\1/p' | xargs -r -n1 nft delete rule inet fw4 raw_prerouting handle

# HowTo schedule block
You can use cron with command in executed commands and unblock using command upper

# Sreenshots

<table>
    <tr>
    <td width="50%">Default bootstrap theme</td>
    <td width="50%">OpenWRT2020 theme</td>
  </tr
  <tr>
    <td width="50%"><img width="50%" height="50%" alt="Clipboard_08-22-2025_01" src="https://github.com/user-attachments/assets/bf0237bd-d1a6-4b0d-9a69-f3209e0f4124" /></td>
    <td width="50%"><img width="50%" height="50%" alt="Clipboard_08-22-2025_02" src="https://github.com/user-attachments/assets/69a85c91-166c-43a3-b209-097208fe9467" /></td>
  </tr>
</table>

