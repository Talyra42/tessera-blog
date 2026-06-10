---
title: 解决 Fedora KDE 部分程序无法打字的问题
date: 2026-06-04 09:25:38
tags:
- fedora
- linux
- wayland
- fcitx5
categories:
- linux
---

## 现象

系统里 fcitx5 工作正常，**其它程序都能正常打中文**，唯独**微信里无法切出中文输入法、打不了汉字**。

## 背景知识

Linux 下应用程序连接输入法（fcitx5）有两条路：

1. **Wayland 原生路径**：原生 Wayland 应用通过 `text-input` 协议直接连 fcitx5，**不需要任何环境变量**。
2. **X11 / XWayland 路径**：跑在 XWayland 下的 X11 应用连不上 Wayland 输入协议，只能走老办法——靠 `GTK_IM_MODULE`、`QT_IM_MODULE`、`XMODIFIERS` 这些环境变量去找输入法。

KDE Plasma 在 Wayland 下，原生应用走第 1 条路，所以即使环境变量没配，大部分程序也能正常输入。**问题就出在那些走第 2 条路的程序身上。**

## 原因

微信 4.x 是 Chromium 内核应用，运行在 XWayland（X11 模式）下，只能靠环境变量找输入法；但系统里 `GTK_IM_MODULE` / `XMODIFIERS` 没有指向 fcitx5（为空 / `@im=none`），导致微信完全连不上输入法。

因此，类似的其他 Chromium 软件，也会出现这种情况。

## 解决方案

把环境变量做成**用户级**持久配置，新建 `~/.config/environment.d/im.conf`：

```ini
# 输入法 (fcitx5) 环境变量
# 让 XWayland / Chromium 系应用(如微信)能连上 fcitx5
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
```

> `~/.config/environment.d/*.conf` 由 systemd 用户会话在**登录时**读取，因此需要 **注销重新登录一次**（或重启）才会生效。生效后微信无需再手动带环境变量启动。

