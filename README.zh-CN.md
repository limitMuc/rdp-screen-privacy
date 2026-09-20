# rdp-screen-privacy

在通过 RDP 远程控制 **同一个 GNOME 桌面会话** 时自动熄灭现场物理显示器；远程连接断开后，先锁定 GNOME 会话，再自动点亮显示器。

这个项目适合这样的场景：你不想使用一个全新的 Remote Login 会话，而是希望继续使用白天已经打开的浏览器、IDE、终端、窗口布局和应用状态，同时不希望远程操作实时显示在现场屏幕上。

## 为什么需要这个项目？

Ubuntu 的 GNOME Remote Desktop 很适合共享已经存在的桌面会话，但 Ubuntu/GNOME 并没有提供一个足够可靠的内置隐私联动机制：RDP 建立后自动熄灭现场物理显示器，连接断开后先锁定本地会话，再安全地恢复显示器。实际上，Desktop Sharing、Wayland/GNOME 的显示管理，以及显示器自身的电源控制属于不同层次，在不同 Ubuntu 版本、显卡驱动、扩展坞和显示器上的配合并不总是稳定。

这会带来一个很现实的工作场景问题：你从家里或其他地方远程连接到办公电脑开始工作，却忘记关闭办公室的显示器。此时附近的人可能直接看到与你远程操作相同的桌面、窗口和工作内容。这个项目就是为了解决这个问题：通过一个小型 systemd 服务检测 GNOME Desktop Sharing 连接，使用 DDC/CI 熄灭兼容的物理显示器；确认远程连接断开后，先锁定 GNOME 会话，再点亮显示器。

它是一个面向远程办公的实用隐私辅助工具，不替代 GNOME 的身份认证、锁屏机制或现场物理安全措施。

> [!IMPORTANT]
> 这只是一个**本地隐私辅助工具**，不是物理访问控制。现场有人仍可能手动按显示器电源键重新点亮屏幕。真正的安全边界仍然是 GNOME 锁屏和系统认证。

## 工作原理

```text
Desktop Sharing RDP 建立连接
             │
             ▼
       自动发现 DDC 显示器
             │
             ▼
    通过 VCP D6 熄灭物理屏幕
       （支持多次延迟重试）
             │
             ▼
GNOME 逻辑显示器仍保持在线，同一桌面继续通过 RDP 使用

RDP 连接断开
             │
             ▼
       等待短暂重连窗口
             │
             ▼
         先锁 GNOME
             │
             ▼
       再点亮物理显示器
             │
             ▼
        现场只看到锁屏界面
```

项目不会从 GNOME 中禁用显示器，也不会修改桌面布局，而是使用 DDC/CI 控制显示器面板电源状态。

## 主要特性

- 监控 GNOME Desktop Sharing 的现有 RDP 会话。
- 自动识别**用户级** GNOME Remote Desktop 监听端口；当 Remote Login 占用 `3389`、Desktop Sharing 自动切到 `3390` 时无需手工改端口。
- 自动发现 DDC/CI 的 I2C bus，并缓存到 `/run`，即使显示器熄灭后不再参与扫描，也可以用缓存 bus 唤醒。
- RDP 建连后多次补发关屏命令，解决部分显示器被 GNOME / RDP 显示协商重新唤醒的问题。
- 断线防抖，避免网络瞬断导致现场显示器反复亮灭。
- 确认断开后，**先锁屏，再亮物理屏**。
- 可选周期性补发关屏指令，处理长时间远程过程中偶发自动亮屏。
- 自带 systemd 服务、安装/卸载脚本、诊断工具和预检查脚本。
- `extension/` 提供可选的 GNOME Shell 扩展，用于在顶栏显示服务状态。
- 不会自动修改防火墙，不会创建 RDP 账号或密码。

## 参考环境

项目基于下面这套已验证思路设计：

- Ubuntu 26.04
- GNOME Shell 50 / Wayland
- GNOME Remote Desktop Desktop Sharing
- system Remote Login 占用 `3389`，Desktop Sharing 实际监听 `3390`
- Dell E2421HN + Dell E2420H
- `ddcutil` / MCCS VCP D6

理论上其他 systemd Linux + GNOME Remote Desktop + 支持 DDC/CI 的外接显示器也能工作，但不同显示器、显卡、扩展坞的行为可能不同，**请务必人在机器旁边时先测试关屏和唤醒**。

## 为什么选择 Desktop Sharing？

GNOME Remote Desktop 中 Remote Login 和 Desktop Sharing 是两套不同模式。Remote Login 创建远程登录流程，而 Desktop Sharing / remote assistance 操作的是已经存在的桌面会话。

GNOME 官方配置说明：

https://github.com/GNOME/gnome-remote-desktop/blob/main/docs/configuration.md

本项目针对 Desktop Sharing，就是为了保留你原会话里的浏览器标签页、IDE、终端、应用状态和窗口位置。

## 依赖

必须：

- Linux + `systemd`
- GNOME Desktop + GNOME Remote Desktop
- 已开启 RDP Desktop Sharing
- `ddcutil`
- 支持 DDC/CI、VCP `D6` 的外接显示器
- `iproute2`（提供 `ss`）
- `systemd-logind`（提供 `loginctl`）

可选但很重要：

如果你希望 GNOME 已锁屏以后仍然能够重新连接 Desktop Sharing，可以使用 GNOME Shell 扩展 **Allow Locked Remote Desktop**：

https://extensions.gnome.org/extension/4338/allow-locked-remote-desktop/

源码：

https://github.com/jikamens/allow-locked-remote-desktop/

UUID：

```text
allowlockedremotedesktop@kamens.us
```

GNOME 默认 remote-assistance 行为在锁屏后会停止远程访问，因此启用此扩展前请理解它对锁屏安全模型的改变。

## 快速安装

完整的换机交接、实机测试、故障排查和发布清单请见
[HANDOFF.md](HANDOFF.md)。

可选的 GNOME 顶栏扩展与后台服务分开安装：

```bash
make extension-pack
systemctl --user daemon-reload
systemctl --user enable --now rdp-screen-privacy-agent.service
gnome-extensions install rdp-screen-privacy@limitMuc.shell-extension.zip
gnome-extensions enable rdp-screen-privacy@limitMuc
```

扩展元数据已经指向 `limitMuc/rdp-screen-privacy` 仓库。

### 1. 确认显示器开启 DDC/CI

不少显示器需要在 OSD 菜单里手工打开 DDC/CI。

### 2. 扫描显示器

```bash
sudo ddcutil detect
```

查看某个 bus 的 D6：

```bash
sudo ddcutil --bus 8 getvcp D6
sudo ddcutil --bus 8 capabilities | grep -A4 -i 'Feature: D6'
```

常见输出类似：

```text
01: DPM: On
04: DPM: Off
05: Write only value to turn off display
```

项目默认使用 `04`，而不是更激进的 `05`，主要考虑远程可恢复性。

### 3. 人在电脑旁边时测试熄屏和唤醒

```bash
sudo ddcutil --bus 8 setvcp D6 04
sleep 5
sudo ddcutil --bus 8 setvcp D6 01
```

每一块显示器都建议单独验证。

### 4. 预检查

```bash
./scripts/preflight.sh
```

### 5. 安装

```bash
git clone https://github.com/limitMuc/rdp-screen-privacy.git
cd rdp-screen-privacy
sudo ./install.sh --install-deps --user "$USER"
```

安装内容：

```text
/usr/local/sbin/rdp-screen-privacy
/etc/rdp-screen-privacy.conf
/etc/systemd/system/rdp-screen-privacy.service
```

### 6. 诊断

```bash
sudo rdp-screen-privacy diagnose
```

### 7. 首次测试时开实时日志

```bash
sudo journalctl -u rdp-screen-privacy -f
```

然后从另一台机器连接 GNOME **Desktop Sharing**。连接建立后物理屏幕应自动熄灭；断开后等待几秒，GNOME 自动锁定，随后显示器亮起并停留在锁屏界面。

## 配置

```bash
sudo editor /etc/rdp-screen-privacy.conf
```

关键配置：

```bash
# 留空时自动识别 seat0 上活动的图形用户
DESKTOP_USER=""

# 自动识别用户级 GNOME Desktop Sharing 实际端口
RDP_PORT="auto"

# 自动发现所有 DDC/CI 显示器，也可明确写成 "8 13"
MONITOR_BUSES="auto"

CHECK_INTERVAL=1
DISCONNECT_DELAY=5
LOCK_SETTLE_DELAY=2

# 第一次立即关屏，2 秒后补一次，再过 3 秒补一次
OFF_RETRY_DELAYS="0 2 3"
ON_RETRY_DELAYS="0 2"

# 0 表示关闭周期补发。如果显示器远程一段时间后会自己亮，可设 30
KEEP_OFF_INTERVAL=0

DDC_OFF_VALUE="04"
DDC_ON_VALUE="01"

LOCK_ON_DISCONNECT=true
TURN_ON_AFTER_DISCONNECT=true
LOCK_ON_SERVICE_STOP=true
TURN_ON_ON_SERVICE_STOP=true
```

修改后：

```bash
sudo systemctl restart rdp-screen-privacy
```

## 常用命令

```bash
sudo rdp-screen-privacy diagnose
sudo rdp-screen-privacy port
sudo rdp-screen-privacy buses
sudo rdp-screen-privacy off
sudo rdp-screen-privacy on
sudo rdp-screen-privacy lock
```

服务：

```bash
sudo systemctl status rdp-screen-privacy
sudo systemctl restart rdp-screen-privacy
sudo journalctl -u rdp-screen-privacy -f
```

## 同时开启 Remote Login 和 Desktop Sharing

常见状态：

```text
3389 -> system gnome-remote-desktop -> Remote Login
3390 -> user gnome-remote-desktop   -> Desktop Sharing
```

建议保持：

```bash
RDP_PORT="auto"
```

项目会根据桌面用户自己的 `gnome-remote-desktop-daemon` 找到真实监听端口，不会误把 system `--system` Remote Login 当成要监控的会话。

手工查看：

```bash
sudo ss -lntp | grep -E ':(3389|3390)\b'
```

## 为什么缓存显示器 bus？

部分显示器进入低功耗状态后可能不再被 `ddcutil detect` 扫描到。如果这时完全重新扫描，就可能找不到“开屏”目标。

因此项目在关屏前把当前 bus 缓存到：

```text
/run/rdp-screen-privacy/buses
```

重启后 `/run` 会清空，因此驱动/硬件变化导致 bus 编号变化时不会永久使用旧值。

## 安全顺序

断线后的顺序是刻意设计的：

```text
RDP 连接消失
    ↓
等待重连窗口
    ↓
锁 GNOME 会话
    ↓
等待锁屏稳定
    ↓
物理显示器亮起
```

这样避免现场屏幕先亮、短暂暴露未锁桌面的情况。

服务被 stop/restart 时默认也执行相同保护动作，可通过配置关闭。

## 限制

- DDC/CI 是否可用与显示器、线材、扩展坞、GPU 驱动都有关系。
- 笔记本内置屏幕通常不能像外接显示器一样由 `ddcutil` 控制。
- 某些显示器进入特定 D6 电源模式后会失去 DDC 响应，所以一定要先现场测试。
- 现场人员仍然可以手动按显示器电源键或切换输入源。
- 本项目不会隐藏 RDP 连接本身，也不会绕过系统认证、锁屏、终端管理、防火墙或公司安全策略。
- GNOME 不同版本行为可能变化，提交兼容性问题时建议附上 `sudo rdp-screen-privacy diagnose` 输出。

## 排障

完整说明见：[`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)

常用：

```bash
sudo rdp-screen-privacy diagnose
sudo ddcutil detect
sudo journalctl -u rdp-screen-privacy -n 100 --no-pager
```

## 卸载

保留配置：

```bash
sudo ./uninstall.sh
```

配置一起删除：

```bash
sudo ./uninstall.sh --purge-config
```

不会自动卸载 `ddcutil`。

## 开发

```bash
make check
make shellcheck
```


## 开源协议

本项目使用 **MIT License**。

MIT 是一种宽松的开放源代码许可证，允许个人和商业使用、修改、再分发及再授权；再分发时需保留版权声明和许可证文本。

详见 [LICENSE](LICENSE)。
