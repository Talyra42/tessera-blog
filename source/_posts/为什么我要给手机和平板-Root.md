---
title: 为什么我要给手机和平板 Root
date: 2026-11-11 17:10:00
tags:
- android
- root
- hyperos
- xiaomi
- 隐私
categories:
- android
series: 小米 Root 手记
---

十一月初，我把两台小米设备的 Bootloader（BL）都解锁了，一台是 Redmi K90 Pro Max（代号 `myron`），一台是 Xiaomi Pad 8（代号 `yupei`）。现在两台机器都跑在 SukiSU 上。

那么：好端端的设备，为什么要去动它最底层的两个东西。

## 设备情况

|         | Redmi K90 Pro Max         | Xiaomi Pad 8               |
| ------- | ------------------------- | -------------------------- |
| 系统    | HyperOS OS4.0.6.0.XPMCNXM | HyperOS OS4.0.12.0.XPZCNXM |
| Android | 17（SDK 37）              | 17（SDK 37）               |
| 内核    | 6.12.69-android16-6       | 6.6.118-android15-8        |
| BL      | 已解锁                    | 已解锁                     |
| Root    | SukiSU-Ultra v4.3.0-r2    | 同左                       |

两台都是出厂系统，没刷第三方 ROM，也没降级，安全补丁分别是 2026-10 和 2026-09。

## 一、好奇

> 也算是圆了小时候的梦，当时对这个可感兴趣了

我在 B 站刷到一堆人 Root 手机，改图标、改字体、装模块，看着挺热闹，就想自己也试试。

结果第一步就卡住了，小米官方直接把申请解锁 BL 的通道关了。想解锁只能走第三方工具，而那些工具的做法是先拿到一个"临时 Root"（重启就失效的 Root，只活在这几分钟里），再用它去改 BL。

K90 比较走运，工具在它这版系统上还能提权，几步下来就解了。Pad 8 不行，工具直接报：

```txt
推送提权文件失败！！！
当你来到这里的时候 说明工具已经不支持您现在的版本提权了！
```

具体是怎么解锁的呢？可以直接看看下一篇文章哦！

## 二、预装和广告

解锁之后第一件事是把不要的东西卸掉。

HyperOS 4 在这一块比前几代收得更紧：普通 adb 权限（`shell` 用户）用 `pm uninstall --user 0` 卸第三方预装没问题，但一旦目标是 `/system` 下的应用，就会直接告诉你没权限。`pm disable-user` 也一样，HyperOS 里被禁了。

这就形成了一个挺别扭的局面：广告和统计组件恰恰都在 `/system` 里，反而卸不掉。要么留着，要么拿 Root。

K90 那天一共处理了 47 个包：

- 第三方渠道预装 24 个，抖音、快手、今日头条、淘宝、拼多多、美团、WPS 之类，来源是 `/cust/app/customized/partner-*`；
- 小米自家 8 个，小米商城、有品、社区、音乐、云盘、换机；
- 广告和统计 9 个，`systemAdSolution`、`analytics`、`ab`（A/B 实验与云控）、`uireporter`、`bugreport`、`thirdappassistant`（后台推装）、`hybrid`、`personalassistant`、`partnerbookmarks`；
- 只禁用不删的 6 个，锁屏画报、小米视频、游戏中心、虚拟 SIM 之类。

包数从 429 掉到 381。

## 三、数据上报

前两个理由其实都不足以让我冒这个险。11 月 11 号下午刷到一个视频，说小米系统里有几个"运营商上报组件"一直在后台采集信息，视频点了三个包名：

```txt
com.mobiletools.systemhelper      → 说这是联通的
com.miui.dmregservice             → 说这是移动的
com.xiaomi.registration           → 说这是电信的
```

手机正好连着电脑，我就自己查了一遍。

第一个，`com.mobiletools.systemhelper` 前一天已经卸了。视频里点名的多半是另一个同名的 `com.qualcomm.qti.services.systemhelper`——那是高通的显示和旋转服务，dex 里全是 `DisplayManager`、`sys_rotation`、`accelerometer_rotation` 这些东西，APK 只有 29 KB，manifest 里写着 `android:enabled="false"`，出厂就是关着的。跟运营商没关系，视频认错了人。

第二个，`com.xiaomi.registration` 是做 SIM 卡自动注册的，状态里有 `autosms_provision=true`、`register_regtime=2026-11-10 14:50:30`，确实活着，但干的是开卡激活的活，不是采集。

第三个，`com.miui.dmregservice` 才是真的。它的 Volley 缓存里躺着三条 POST，时间戳是 11 号 14:22:50：

```txt
POST https://a.fxltsbl.com/accept/batteryCharging
POST https://a.fxltsbl.com/accept/wifiInfo?version=v2
POST https://a.fxltsbl.com/accept/network?version=v2

appkey=A100000005
imei=863908089164503
```

三条都返回 200。它的库里有 `cmcc_dm.db`，`sim_iccid` 是 `898600...`，移动的号段，表结构里还留着 cell、IMSI、ICCID 这些字段。而且我查的时候表已经空了——采集、上传、清库，本机上什么都不留。

所以视频说的三个包，一个认错了，一个方向不对，一个确实在传 WiFi 信息、基站信息和充电状态，还带着 IMEI。数据不是小米自己收的，走的是运营商的 DM（Device Management）通道，服务器是个第三方域名。

那就删。三个一起卸：

```bash
adb shell su -c "pm uninstall --user 0 com.qualcomm.qti.services.systemhelper"
adb shell su -c "pm uninstall --user 0 com.miui.dmregservice"
adb shell su -c "pm uninstall --user 0 com.xiaomi.registration"
```

反正 APK 都在只读分区里，哪天发现 VoLTE 不正常，`pm install-existing` 装回来就行。

顺带记一个坑：前一天删 MiSight 的时候，APK 是卸掉了，但 `/system_ext/bin/misight` 这个 native 服务还在跑，定义在 `init.misight.rc` 里，`setprop ctl.stop misight` 只停到下次重启。删应用不等于关服务，以前我一直以为是一回事。

## 结语

总而言之，我冒着唯一设备变成板砖的风险，还是决定去走这么一遭了。
