---
title: WSL2 使用手册
date: 2026-06-28 16:33:25
tags:
- wsl2
- dev
categories:
- dev
---

## 什么是 WSL2

WSL 是微软为 Windows 开发的 Linux 兼容层，允许用户在 Windows 上直接运行 Linux 二进制文件。WSL2 是第二代版本，采用真正的 Linux 内核，性能大幅提升。

## 安装

### 查看在线发行版

默认直接使用会安装 Ubuntu，可以先看看在线都有哪些 Linux 可以安装：

```bash
wsl --list --online
```

随后可能会输出：

```txt
以下是可安装的有效分发的列表。
使用“wsl.exe --install <Distro>”安装。

NAME                            FRIENDLY NAME
Ubuntu                          Ubuntu
Ubuntu-26.04                    Ubuntu 26.04 LTS
Ubuntu-24.04                    Ubuntu 24.04 LTS
Ubuntu-22.04                    Ubuntu 22.04 LTS
openSUSE-Tumbleweed             openSUSE Tumbleweed
openSUSE-Leap-16.0              openSUSE Leap 16.0
SUSE-Linux-Enterprise-15-SP7    SUSE Linux Enterprise 15 SP7
SUSE-Linux-Enterprise-16.0      SUSE Linux Enterprise 16.0
kali-linux                      Kali Linux Rolling
Debian                          Debian GNU/Linux
AlmaLinux-8                     AlmaLinux OS 8
AlmaLinux-9                     AlmaLinux OS 9
AlmaLinux-Kitten-10             AlmaLinux OS Kitten 10
AlmaLinux-10                    AlmaLinux OS 10
archlinux                       Arch Linux
FedoraLinux-44                  Fedora Linux 44
FedoraLinux-43                  Fedora Linux 43
eLxr                            eLxr 12.12.0.0 GNU/Linux
OracleLinux_7_9                 Oracle Linux 7.9
OracleLinux_8_10                Oracle Linux 8.10
OracleLinux_9_5                 Oracle Linux 9.5
SUSE-Linux-Enterprise-15-SP6    SUSE Linux Enterprise 15 SP6
```

### 安装特定版本

这里记住上面的版本的 NAME 字段，比如我们需要安装 `Ubuntu 26.04 LTS`，则复制 `Ubuntu-26.04`，随后执行如下命令进行安装：

```bash
wsl --install -d Ubuntu-26.04
```

### 指定安装位置

默认来说，发行版会安装在 C 盘下，如果需要修改位置，可以增加一个参数：

```bash
wsl --install -d Ubuntu-26.04 --location "D:\WSL\Ubuntu"
```

### 查看已安装的发行版

安装后，可以通过如下命令查看安装在本地的发行版：

```bash
wsl --list --verbose
```

示例输出如下：

```txt
  NAME              STATE           VERSION
* docker-desktop    Stopped         2
  Ubuntu-26.04      Running         2
```

这里带 `*` 的是默认的 WSL 容器，如果直接启动 wsl，就会直接进入该容器。

## 配置

### 创建账户

安装的时候，会同时让你创建用户名和密码，这里输入自己想要的用户名和密码即可，这里就不多说了。

当然需要注意：

- 用户名可以随便，和 Windows 的用户名无关
- 密码输入的时候不会回显
- 需要牢记密码

## 启动

### 默认启动

默认来说，会启动前面说到的，设置的默认的发行版，直接通过如下命令启动：

```bash
wsl
```

### 启动特定发行版

通过如下命令启动特定发行版：

```bash
wsl -d Ubuntu-26.04
```

### 设置默认发行版

通过 set 来设置默认的发行版：

```bash
wsl -s Ubuntu-26.04
```

随后，直接 `wsl` 就可以启动默认发行版了。

## 停止

我们退出发行版以后，其实他还会运行一段时间，如果需要立刻停止，可以使用：

```bash
wsl -t Ubuntu-26.04
```

## 卸载

不再使用了，可以通过如下命令彻底从硬盘上删除发行版：

```bash
wsl --unregister Ubuntu-26.04
```

需要注意，这是会删除文件的，如果有东西的话，最好进行备份。

## 导出

如果需要对发行版进行备份，或者是导出，然后再别的地方进行导入，则可以使用如下命令：

```bash
wsl --export Ubuntu-26.04 "D:\WSL\Backup\FileName.tar"
```

这样他会在目标位置生成一个叫做 `FileName.tar` 的压缩包出来。

---

导入的时候，可以使用如下命令：

```bash
wsl --import Ubuntu "D:\WSL\Ubuntu-26.04" "D:\WSL\Backup\FileName.tar"
```

第一个参数是名称，第二个参数是导入以后存放的位置，第三个参数是压缩包的位置。
