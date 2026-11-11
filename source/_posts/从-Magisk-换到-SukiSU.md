---
title: 从 Magisk 换到 SukiSU
date: 2026-11-11 18:10:00
tags:
- android
- magisk
- kernelsu
- sukisu
- 内核
categories:
- android
series: 小米 Root 手记
---

两台机器第一次 Root 用的都是 Magisk（中文社区一般叫"面具"）。用了不到一天，我就琢磨着换掉。

## 一开始为什么用面具

一开始用面具，不是因为觉得它更好，是因为那时候只有它能用。

把 K90 的时间线摆出来就明白了：

```txt
14:15  接手设备，确认 BL 已解锁，此时没有任何 Root
14:35  用 CVE-2026-98260 拿到一次性临时 Root
15:13  趁临时 Root 还在，dd 导出分区镜像
15:31  Magisk v31.1 修补 init_boot_a，fastboot 刷入
```

临时 Root 是一次性的，重启就失效。在那几分钟里，我能做的事只有三样：导分区、用 App 离线补丁一个镜像文件、`fastboot flash` 一个分区。这三件事恰好就是面具的安装模型。

换到 KSU 会多一层麻烦：要么你得先有持久 Root 才能热加载，要么你得离线把 `ksuinit` 打进镜像，多一个没人验证过的变量。而当时手上既没有 TWRP（第三方恢复环境），也没有 4.0.6 的线刷包兜底，公开的最新只到 4.0.5。万一 bootloop，我连退路都没有。

再加上那天真正想保住的东西只有两样：广告过滤用的 hosts 和一个纯脚本的防砖模块，两个面具都原生支持。

所以第一天用面具，三条约束摆在那儿，也没什么别的选。

## 为什么换

第二天我把这事重新想了一遍，理由其实很朴素：我就是觉得面具好像不是很现代，KSU 感觉就是高级很多。

具体点说：

- 面具是用户态实现的，一个叫 `magiskd` 的守护进程在跑，靠注入 `init` 和 ramdisk 里的脚本来工作；
- KernelSU（下面简称 KSU）把 `su` 做在内核里，用户态没有常驻进程；
- KSU 还有两个面具侧没有的东西：按应用给权限的 App Profile（可以只给某个组、某些 capability，而不是"给不给 root"二选一），还有 SUSFS 那种内核级的路径和挂载伪装。

当时也问了下值不值得换，答复是不建议。理由是换框架治不了那两个加固 App（它们查的是 BL 状态），而 AdAway、Brick Guardian 这些面具专属的链路要重做。

这话不算错，但它把 AdAway 当成了我的主要用途。实际上我就是装上试了试，八万多条规则拦得挺欢，我日常几乎感知不到。真正让我放下顾虑的是另一件事：既然改的是同一个分区，回滚只要两分钟，那这个决定的风险其实不高。

## 改的其实是同一个分区

Android 13 以后，出厂带 GKI（Generic Kernel Image，通用内核镜像）的机器，开机用的 ramdisk（内存盘）不在 `boot` 分区，而在单独的 `init_boot` 分区。面具改的是 `init_boot`。

KSU 的 LKM（Loadable Kernel Module，可加载内核模块）模式改的也是 `init_boot`。

所以两者抢同一个分区，不能共存：迁移必须先刷回原厂 `init_boot`，中间有一段没 Root 的裸奔窗口。但操作面完全一样，回滚就是把面具的修补版刷回去，两分钟，数据不动。

而且两台机器的 KMI（Kernel Module Interface，内核模块接口）都在预编译 LKM 的覆盖范围内：

| 设备 | 内核 | KMI |
|---|---|---|
| K90 Pro Max | 6.12.69-android16-6 | `android16-6.12` |
| Pad 8 | 6.6.118-android15-8 | `android15-6.6` |

SukiSU-Ultra 的 release 里直接带了这两个 KMI 的 `.ko`，不用编内核。要编内核的话，风险和量级完全是另一回事。

于是我改主意了。先拿 Pad 8 试，它一个模块都没有，成本最低，跑通了再做 K90。

## 实际操作

装 SukiSU 管理器，先看首页显示什么。显示"未安装"代表它认这颗内核，可以继续；显示"不支持"就得自己编内核，那就该停手了。

然后是最容易错的一步：喂给管理器修补的必须是原厂 `init_boot`，不能用当前正在跑的那份。因为当前分区已经被面具改过了，拿它再补一层，等于在脏镜像上叠脏东西。

```bash
adb push init_boot_stock.img /sdcard/Download/
```

在管理器里选「选择并修补一个文件」，选这个文件，产出 `ksu_patched.img`，拉回电脑留档，然后刷入：

```bash
adb reboot bootloader
fastboot flash init_boot_a ksu_pad8.img
fastboot reboot
```

只刷 `_a` 槽，`_b` 先留着，真出问题还能切槽。验证就看 su 的上下文变没变：

```bash
adb shell su -c id
# uid=0(root) ... context=u:r:ksu:s0
```

之前是 `u:r:magisk:s0`，现在换成 `u:r:ksu:s0`，这两个字符串一换，框架就是真的换了。

## 那个 Unknown symbol 的坑

这是整件事里最值得记的一段。

动手之前我想先确认这颗内核收不收第三方模块，做法很直接：把 `.ko` 推进去，`insmod` 一下。结果一律是 `Unknown symbol`。SukiSU 的试了，KernelSU 官方的试了，KernelSU Next 的也试了，三个全挂。

按正常逻辑，到这儿就该判断"内核不接受外部模块，LKM 模式不可行"，我差点就写进文档了。

但有个细节不对：如果内核真的不支持模块加载，`/proc/modules` 应该是空的。而实际上 `CONFIG_MODULES` 是开的，只是内核多开了一个开关：

```txt
CONFIG_TRIM_UNUSED_KSYMS=y
```

这个选项会把没被内置模块用到的导出符号裁掉。厂商为了减小体积、缩小攻击面越来越常开。后果是内核里那些符号其实都在，只是从导出表里删了，第三方模块链接时找不到符号名，就报 `Unknown symbol`。

这是假阴性。

正确的测法是换一个加载器。KSU 自带一个叫 `ksud` 的工具，它的 `insmod` 子命令会读 `/proc/kallsyms` 拿到符号的真实地址，运行时手动重定位，绕过导出表：

```bash
su -c '/data/local/tmp/ksud insmod /data/local/tmp/ksu.ko'
su -c 'grep -i kernelsu /proc/modules'
```

```txt
kernelsu 487424 0 - Live
```

`Live` 出来了，说明能装。dmesg 里 `mount_hide: enabled (3/3 files hooked)`、`avc_spoof: ... spoofing enabled` 这些初始化也都正常跑完。

顺带一提，`ksud boot-patch` 生成启动镜像走的是同一套加载器，所以刷进去能正常开机，这不是巧合。

判断内核收不收模块，不能用裸 `insmod` 测。测出来的是"导出表里有没有这个符号"，不是"内核能不能加载模块"，这两件事在新一点的内核上已经分开了。

## 清干净

换完之后系统里会留一堆面具的东西。Pad 8 上我先删两个模块目录，再删 `/data/adb/magisk` 和 `magisk.db`，然后卸载 App：

```bash
su -c 'rm -rf /data/adb/modules/hosts'
su -c 'rm -rf /data/adb/modules/magisk-brick-guardian'
su -c 'rm -rf /data/adb/magisk /data/adb/magisk.db'
adb uninstall com.topjohnwu.magisk
```

清完 `/data/adb` 只剩 `ksu/`、`ksud`、空的 `modules/`、`post-fs-data.d/`、`service.d/`。

还有一处容易忘：AdAway 之前改的 hosts。它用的是 systemless hosts 模块挂载，模块一删，`/system/etc/hosts` 就回到原厂那两行了。K90 上顺手把 AdAway 也卸了。

我有点电子洁癖，系统里同时躺着两套权限体系会很难受，所以这一步做得比较彻底。清完冷启动复验了一遍，开机正常，`adb shell su` 直接可用。

## SUSFS

Pad 8 上另外装了个模块 `susfs_guard_lkm`，版本 v2.3.0-r18.9-1。

SUSFS 是一套内核级的伪装，能把 root 相关的路径、挂载信息从 `/proc` 里藏掉，比面具的 DenyList 深一层。它传统上要改内核，这个模块把它做成了可加载的 LKM，免编内核。

装完验证：

```bash
adb shell su -c 'ls /proc/ | grep susfs'
```

能看到九个 `susfs_*` 节点，说明装进去了。不过到现在我只加载了模块，没配任何规则，想先看清楚它的实际行为再决定要不要开。

K90 上什么都没装，一个模块也没有。

## 最后

换完最直观的变化是系统里少了一套东西：一个框架、零到一条模块，没有两套权限体系并存。App Profile 这种按应用授权的粒度也用上了，SUSFS 那条路留着，需要的时候能开。

没换来的也得说清楚。那两个加固 App 照样崩，因为它们查的是 `verifiedbootstate=orange`，这是 BL 解锁的硬件状态，换哪个框架都变不回去。Brick Guardian 也失效了，它是面具模块，靠面具的启动脚本计数，KSU 下不算数，现在防砖就是刷回镜像，简单但得有台电脑。

至于 Zygisk，要另装 ZygiskNext，我没有这需求就没装。
