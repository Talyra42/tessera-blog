---
title: 小米平板 8 解锁 BL 的一夜
date: 2026-11-11 17:40:00
tags:
- android
- bootloader
- 内核漏洞
- xiaomi
categories:
- android
series: 小米 Root 手记
---

感谢莫离然然大佬的工具箱，让我很方便的就完成了手机的解锁。

但是对于平板却没有这么方便了。

同样是小米，同样是 HyperOS 4，同样是国行，K90 Pro Max 真的算是秒解，但是 Pad 8 直接报"提权文件推送失败"。这篇讲的就是从这句报错到 `fastboot` 显示 `unlocked` 之间的十几个小时，中间包括一次内核漏洞的移植。

结论：这台机器当时没有任何现成方案，最后是拿一个 shell 漏洞的载荷、按这颗内核的编译号重新对了一遍偏移，才拿到临时 Root，再用它去写工程 ABL（高通平台的引导程序，Android Bootloader）完成解锁。

## 工具为什么不行

工具叫 `Xiaomi-QC解锁BL工具v2.5Plus`，酷安上莫离然然做的。流程分两步：

1. 先用漏洞拿到临时 Root（界面上叫"提权"或者"宽容提权"）；
2. 用这个 Root 权限把工程版 ABL 和分区表刷进去，让 BL 变成未锁定状态，解锁完再还原官方分区表。

所以它能不能用，完全取决于第一步在你的系统版本上成不成立。

把工具自带的更新日志翻出来，作者自己写着"不可能保证后续新版本系统每个机型都能支持提权，后续将随缘内置提权"。意思很明白：工具缺的正是临时 Root，这活儿得你自己干。

那先确认是不是操作问题。三条实测：

```txt
工具自带 adb（34.0.1）识别设备正常，5037 端口是它在占
手动 adb push 到 /data/local/tmp 成功，读写删都正常
开机后 getenforce → Enforcing
```

连接没问题、路径没问题，那就是通道被堵了。再验证两条老路：

```txt
fastboot oem set-gpu-preemption-value 0 androidboot.selinux=permissive
→ FAILED (remote: 'Value must be 1 or ...')

service call miui.mqsas.IMQSNative ...
→ Command not allowed for shell user
```

第一条是往内核命令行里塞 `androidboot.selinux=permissive`，被参数校验挡住了。第二条是早年那个 `mqsas` 服务执行入口，正确的 transaction 其实是 `runCommand=4` 和 `captureLogByRunCommand=14`（不是老教程里的 21），两个都返回"shell 用户不允许"；自己写个 App 用 `ServiceManager.getService` 去拿 binder，拿到的是 `null`，普通应用根本看不见这个服务。

两条路都断了。顺手把其他几条也排掉：

- 官方解锁通道：国行早就名额制加答题，社区普遍反馈走不通；
- 9008 深刷（高通 EDL 模式）：要免授权 firehose，SM8735 没有公开可靠的，而且一定清数据、失去保修；
- `fastboot boot unlock_8735-Ennea.img`：直接回 `Fastboot boot command is not available in locked device`。锁着的机器连临时引导都不让加载，这是设计如此。

## 从内核想办法

剩下的只有一条：从内核里拿 Root。

当时手上有三个载荷，全试过。

**GhostLock（CVE-2026-43499）** 是 futex 的 PI 链上有个释放后重用，官方在 6.6.140 修的。这台是 6.6.118，版本号上"理论上还没修"。问题是这类载荷要按内核编译号提偏移，而这颗内核的编译号是 `ab16143355`，没有现成 profile。跑起来日志固定是：

```txt
slide bad leaked pointer=1e4d5d80e0014fae
slide attempt N failed
```

十轮，App 上下文和 shell 上下文都试了，一直滑不出来。可能是被补丁了，也可能只是 profile 不对，反正这个 build 没戏。

**CVE-2026-64560** 的载荷更省事，`--preflight` 就直接拒：

```txt
TARGET_PROFILE_GATE_FAIL fingerprint=yupei
```

它只认 15 / 15 Pro / 15 Ultra / Pad 8 Pro。硬绕指纹校验会按错误的内核偏移去写内存，那就不是解锁而是砖了，放弃。

**CVE-2026-98260** 是 POSIX CPU timer 的释放后重用，修复边界在 6.6.158，6.6.118 在窗口内。社区里有个叫 Shark 的项目放了 `libk66118.so`，是给 6.6.118 编译的，里面写死了几套 profile 常量。

有戏，但没有针对 `ab16143355` 的。自己算。

## 从 OTA 里抠内核

要对偏移，先得有这颗内核的二进制。

设备上 `/proc/config.gz` 能看配置，但拿不到可分析的镜像。于是去下官方 OTA：`OS4.0.11.0.XPZCNXM` 的完整包，10,050,724,900 字节，差不多 10 GB。

整包下下来不现实，就用 HTTP Range 只取 `boot` 分区那一段，再按 payload 的压缩方式解出来。最后拿到 36,801,024 字节的内核，`strings` 里能搜到 `ab16143355`，对上了。

有了镜像，就能从里面恢复这个 build 的真实地址：

```txt
timer site        0xffffffc080195d50
copy site         0xffffffc0800ab93c
k_itimer 大小     0x108
cred 大小         0xb8
task_struct 大小  0x12c0（这个是错的，后面踩了）
selinux_state     0x80
```

然后给载荷打补丁：把 profile 里的常量换成这台机器的值，把那条"按 uname 选 profile"的分支改掉（不然它自己会判成不匹配），再修一个字符串。

第一次跑，`FAIL=probe REASON=kernel mismatch got=...ab16143355`。分支改完，probe 过了。

然后是真正的麻烦。载荷要伪造一个 cred（内核里代表"我是谁、有什么权限"的结构），尺寸用的就是上面那个 `0x12c0`。跑起来 `task=0`，拿不到任务结构。翻内核 trace 才发现这个 build 里 `copy_process+0x140` 申请的是 5312 字节，也就是 `0x14c0`。

改完再跑，这次成了：

```txt
[+] child report stage=2 uid=0 euid=0 setuid(0)=0 resuid=0/0/0
PLANT_CRED_OK
uid=0(root) gid=0(root) context=u:r:kernel:s0
CapEff: 000001ffffffffff
Permissive
```

`u:r:kernel:s0` 是内核域，`CapEff` 是全 capability，SELinux Permissive。块设备读写也验了，`dd` 能读 `abl_a` 的头 4 KB。

中间还有个特别蠢的错误：第一次改指令时手算机器码写成了 `0x052A980D`，反汇编出来是 `clasta`，一跑就 SIGILL。正确值是 `0x5282980D`。

## 让 Root 活下来

拿到 Root 只解决了一半问题。

这个 Root 的寿命等于载荷进程的寿命，进程一退，cred 就没了。而且 adbd 是 production 构建编译的，`adb root` 直接回：

```txt
adbd cannot run as root in production builds
```

也就是说，不可能让 `adb shell` 天然就是 root，得自己造一个通道。

思路是让载荷 fork 一个子进程，子进程拿着全 capability 的 cred 停在那里，再开一对命名管道（FIFO）当初级的 stdin/stdout，我往里写命令、从另一头读结果。

中间踩了两次坑：第一次用 `setsid` 把守护进程丢到后台，结果 capability 丢了，`dd` 报 `Permission denied`；改成前台跑，命令一结束进程就被收走。最后是 fork 一个子 shell、`trap '' HUP` 忽略挂断信号，路径分开用 `root3_in` / `root3_out`，才稳住。

接下来还有一层：`su` 得让 `adb shell` 能看见。往 `/system/bin` 上挂 overlayfs 不行，`mount: 'overlay'->'/system/bin': Invalid argument`；挂 tmpfs 可以，但只对执行 mount 的那个进程的 mount namespace 生效，`adb shell` 在另一个 namespace 里，看不见。

解法是用 `nsenter` 进 adbd 的 namespace 去挂：

```bash
nsenter -t <adbd_pid> -m -- mount -t tmpfs tmpfs /system/xbin
```

这样 `adb shell` 就能看到 `/system/xbin/su`，而 `su` 只是个 382 字节的脚本，把参数转给管道守护进程。

到这里，`adb shell su -c id` 回 `uid=0` 了。

## 把工具骗过去

回到那个解锁工具，它菜单里有个方案 3：「已经自行提权完成后写入」。选了之后它第一件事是检查 shell 有没有 Root：

```txt
请直接输入对应数字1/2/3： 3

检查Shell是否获取到Root！
[成功]adb Shell权限已提升Root
```

前一晚这里还是 `[失败] Shell获取Root权限失败！！！`，差别就在于 `/system/xbin/su` 能不能用。

过了这一关，工具开始推工程 ABL：

```txt
开始推送工程abl.elf...
开始写入工程abl到abl_a分区...
成功写入abl_a
开始写入工程abl到abl_b分区...
成功写入abl_b
将设备重启到Fastboot...
```

然后平板屏幕上出现了一行大字：

```txt
The system has been destroyed
```

那一瞬间心跳停了半拍。后来才明白这是正常的：工程版 ABL 不是给正常开机用的，它就是让机器停在"我坏了"的状态等你进 fastboot。只要还能进 fastboot，就没砖。

手动按进 fastboot，工具继续跑，加载解锁载荷、改 GPT（GUID 分区表）、解锁完再还原官方分区表，最后 `fastboot erase userdata` 清数据。

进系统，设置里显示：BL 未锁定。

## 事后

前后十几个小时，绝大部分时间花在两次"我以为要成了"的失败上：一次是偏移滑不出来，一次是 `0x12c0` 和 `0x14c0`。

最坑的是后面那个。BTF 里给的 `0x12c0` 和实际分配的 `0x14c0` 差了 512 字节，表现就是 `task=0`，什么都拿不到。这种东西没人会告诉你，只能翻内核 trace 一条条对。

这套流程换个编译号就得重新算一遍偏移，所以它更像一次性的运气，谈不上通用方案。如果你手上的机器也卡在"工具不支持提权"，先去社区看看有没有人放了对应编译号的 payload，没有就再等等。

下一篇讲解锁之后的事：两台机器怎么从 Magisk 换成 SukiSU。
