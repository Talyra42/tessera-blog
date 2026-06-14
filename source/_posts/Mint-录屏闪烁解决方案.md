---
title: Mint 录屏闪烁解决方案
date: 2026-06-14 10:28:21
tags:
- linux
- mint
categories:
- linux
---

## 系统配置

直接上 fastfetch 详情：

![](/images/2026-06-14_10-31-25.png)

注意，我的显卡是 Nvidia 系列的，这个也是问题的关键。

## 起因

使用 Linux Mint 的时候，如果我使用 obs 或者 peek 进行屏幕录制，会出现闪烁的情况，例如下面这种录制的图片：

![](/images/Peek2026-06-14-10-37.gif)

可以看到，中间出现了奇怪的闪烁，闪烁的是桌面的背景。

## 解决方案

直接打开 Nvidia X Server Setting，然后设置 OpenGL 的 Allow Flipping 为关闭即可：

![](/images/2026-06-14-10-41-51屏幕截图.png)

随后，不需要重启电脑，再次尝试录制，就不会再出现闪烁的问题了。
