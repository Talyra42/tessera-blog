---
title: 如何开启 Claude Code Bypass 模式
date: 2026-06-20 10:59:03
tags:
- ai
- code
- claude
categories:
- dev
---

## 引言

之前使用 Claude Code 的时候，每次保存文件或者是执行命令，都需要手动点一下，虽然有所谓的 `auto mode`，但是还是不是很好。

这个时候我们可以开启 Claude 的 `bypass permissions` 模式，这样 Claude 就会自动的执行各种命令，而不会提示用户了。

## 如何开启

一般来说，我们习惯直接在用户级开启，我是 Linux，直接打开 `~/.claude/settings.json` 文件，然后补充内容如下：

```json
{
  "permissions": {
    "defaultMode": "bypassPermissions"
  }
}
```

随后重启 Claude Code，就可以看到这个模式的提示信息了：

![](/images/2026-06-20-11-05-29屏幕截图.png)

只要确认，进入 Claude Code，就会发现最下面的模式已经变成全自动模式了：

![](/images/2026-06-20-11-06-48屏幕截图.png)

在这个模式下，所有的命令执行、代码编辑，都会自动完成。
