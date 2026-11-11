---
title: Root 之后的收尾：精简、备份和几条红线
date: 2026-11-11 18:40:00
tags:
- android
- root
- 备份
- debloat
categories:
- android
series: 小米 Root 手记
---

解锁和换框架只是把门打开了，真正花时间的在后面：把系统收拾成自己能接受的样子，然后确保玩坏了能退回来。

## 三种卸法

卸系统应用有三种做法，效果差得挺远。

第一种是 `pm uninstall --user 0 <包名>`。它只是把包从"用户 0"里摘掉，APK 还躺在只读分区里，随时能恢复。绝大多数情况都用这个。

第二种是 `pm disable-user`。不删，只禁用。HyperOS 4 里这个命令对 `/system` 下的应用会被拒，所以实际用得不多。

第三种是不带 `--user` 的 `pm uninstall`，影响面覆盖所有用户，但系统应用的 APK 一样删不掉。日常用不到。

区别在恢复的时候最明显：

```bash
# 恢复（需要 root）
adb shell su -c "pm install-existing --user 0 com.xiaomi.market"
```

一条命令就回来了，因为 APK 一直在。

反过来，恢复出厂设置会让所有卸掉的包回来。它们本来就没被删除，只是从用户层摘掉了名字。这件事我在动手之前就知道了，所以不心疼。

## 哪些能删，哪些碰不得

K90 那天处理了 47 个包，Pad 8 处理了 31 个，大致是这么分的：

| 类别 | K90 | Pad 8 | 处理方式 |
|---|---|---|---|
| 第三方渠道预装 | 24 | 5 | 卸载 |
| 小米自家应用 | 8 | 16 | 卸载 |
| 广告 / 统计 / 云控 | 9 | 7 | 卸载 |
| 系统自带（更新器、邮件、浏览器） | — | 3 | 卸载 |
| 只读分区上卸不掉的 | 6 | 0 | 禁用 |

渠道预装的来源是 `/cust/app/customized/partner-*`，抖音、快手、今日头条、淘宝、拼多多、美团、WPS 这一批。Pad 8 上还有几个输入法（百度、搜狗），也卸了，因为默认用的是讯飞。

但有两个包我删过一次，又老老实实装回去了：

```txt
com.miui.personalassistant   智能助理，桌面小组件依赖
com.miui.hybrid              快应用框架，launcher 依赖
```

单独卸载 `com.miui.hybrid` 的后果是桌面直接崩。当时的现象是桌面起不来、连图标都没有，只能重启进设置去处理，装回来重启才正常。这两个现在写在清单里当禁区。

类似的还有 `com.miui.packageinstaller`（系统安装器）。社区里有实测记录，卸了它重启开不了机，只能恢复出厂。我本来想换成原生安装器，看到这条记录就算了，改用 MT 管理器配 root 静默安装——没有界面、没有广告、没有拦截，代价是绕过系统安全检查，APK 来源得自己把关。

## 更新器和几个替换

`com.android.updater` 两台都卸了。原因很直接：HyperOS 的更新通道检测到系统被改动之后各种别扭，而且更新完 Root 必掉，还得重新刷一遍。

代价是收不到安全补丁。恢复的办法是：

```bash
adb shell su -c "pm install-existing --user 0 com.android.updater"
```

其实装回来也没多大事。改过 `init_boot` 之后增量包大概率校验不过，要更新就下完整包。这事我在文档里留了一条，等哪天有值得更新的版本再说。

顺带做了几处替换：

- 浏览器卸了系统自带的，换成 Via，再用 `cmd role add-role-holder android.app.role.BROWSER mark.via` 把默认角色给它；
- 应用商店卸了小米的，改用 Play 商店加 Obtainium（直接从 GitHub Release 拉更新）；
- 输入法 Pad 8 用讯飞，百度和搜狗卸掉；
- 桌面不动。第三方 launcher 在 HyperOS 上问题不少，不值得。

## 备份

这一节是整篇里最要紧的。

临时 Root 的窗口只有几分钟，重启就没了。拿到 Root 之后第一件事应该是导分区，不是先装东西。

```bash
adb shell su -c "dd if=/dev/block/by-name/init_boot_a of=/sdcard/init_boot_a.img bs=4M"
adb pull /sdcard/init_boot_a.img .
```

两台机器备的东西差不多：

| 文件 | 大小 | 用途 |
|---|---|---|
| `init_boot_a/b.img` | 8 MB ×2 | Root 就改在这上面，必须留原厂 |
| `boot_a/b.img` | 96 MB ×2 | 内核所在分区，内核出问题才用得到 |
| `vbmeta_a/b.img` | 128 KB ×2 | 校验启动链，刷错会开不了机 |
| `ksu_*.img` | 8 MB | 当前 Root 镜像，回滚用 |
| `magisk_patched-*.img` | 8 MB | 旧方案，应急用 |

拉回来之后两边各算一遍 sha256：设备上 `sha256sum`、电脑上 `Get-FileHash`，两个值必须一样，镜像头能看出是 `ANDROID!` 就说明没截断。

`dd` 是流式的，中途出问题的话文件大小可能对、内容却是错的，而临时 root 只剩几分钟，没人有空回头检查。所以拉回来之后一定再算一遍。

除了分区，还备了两样：`/data/adb` 整个目录打成一个 tar（模块、授权记录、配置都在里面，K90 那份 2.5 MB），以及照片。

照片这块有个坑值得一提。`adb push` 推中文目录名会截断，`Game-原神` 过去变成 `Game-?`，十个相册推完名字全废。后来改成在电脑上打 tar、推 tar、设备上解压：

```bash
adb push photos.tar /sdcard/
adb shell "cd /sdcard && tar -xf photos.tar && rm photos.tar"
```

370 张相机照片、169 张相册照片，中文相册名一个没坏。之后还要重建一次媒体库索引，不然相册里看不到新文件。

## 双槽这东西

小米这些机器用的是 A/B 双分区：`boot_a` / `boot_b`，`init_boot_a` / `init_boot_b`，系统在其中一个槽上跑。

好处很实在：刷之前另一个槽还是好的，真刷坏了切过去还能开机；OTA 更新是往空闲槽写，写完切换，失败回退。所以刷 `init_boot` 的时候我一般只刷当前用的槽，另一个留着当保险。

代价是每次都要确认自己刷的是哪个槽。`fastboot flash init_boot ksu.img` 不带后缀，fastboot 会按分区的 `has-slot` 属性补上当前槽；写 `init_boot_a` 就是明确指定。我习惯写全，出问题时好排查。

## 不要碰的几件事

重新上锁是最危险的。`fastboot flashing lock`、`fastboot oem lock`、任何叫 `flash_all_lock` 的脚本，都不要碰。解锁是单向门，重新上锁会清空数据，而且改过的分区一律开不了机。我解锁花了一整夜，重锁只要一条命令，救不回来。

`fastboot erase userdata` 也一样。解锁流程里工具会让你执行一次，那是必要的，除此之外任何时候都不要。

还有，不要在工具报"不支持提权"之后反复点"一键解锁"。它会在没有 Root 的情况下尝试写分区，这是变砖的高发路径，工具作者自己在旧版本修过这个问题。

来路不明的降级包也别刷。小米有防回滚（anti-rollback），版本号倒着刷会直接黑砖，只能 9008 救。

## 出了问题怎么退

| 现象 | 大概率原因 | 怎么办 |
|---|---|---|
| 卡开机动画、无限重启 | 刷进去的镜像有问题 | 进 fastboot 刷回原厂 `init_boot` |
| 能开机但没有 root | 镜像没生效 | 检查刷的是不是当前槽 |
| 装模块之后开不了机 | 模块脚本出错 | 在模块目录里 `touch disable`，框架会跳过它 |
| 桌面崩溃 | 删了 launcher 依赖的包 | 装回来，重启 |
| 管理器显示"不支持" | 内核不接受这个 LKM | 停手，刷回原厂镜像 |
| 连 fastboot 都进不去 | 分区表或 ABL 坏了 | 只能 9008 深刷，找专业人士 |

`disable` 这个文件是个开关，只要它存在，Magisk 和 KSU 都会跳过这个模块，不用删掉，等系统能开机了再慢慢查。

K90 上还装过一个叫 Brick Guardian 的防砖模块，机制是开机计数：连续几次没起来就自动禁用可疑模块，再不行禁用全部（跳过自己），最后解冻应用。它是面具专用的，靠面具的启动脚本计数，换框架之后失效了。所以现在防砖就是电脑加一根线加一份校验过的镜像。

两台机器最后停在这个状态：

```txt
BL          已解锁
Root        SukiSU-Ultra v4.3.0-r2（LKM 模式）
模块        K90 无；Pad 8 一条 susfs_guard_lkm（未配规则）
精简        K90 47 个包；Pad 8 31 个包
备份        双槽 boot / init_boot / vbmeta + /data/adb 快照 + 照片
OTA         已卸载更新器，需要时手动装回
```

剩下没做的事也很清楚：OTA 什么时候更、SUSFS 规则要不要配、应用数据要不要用 DataBackup 全量备一次。都不急，反正现在这样已经能用了。
