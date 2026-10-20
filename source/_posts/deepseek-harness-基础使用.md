---
title: DeepSeek Harness 基础使用
date: 2026-10-20 09:24:32
tags:
- dsh
categories:
- ai
layout: post
---

## 什么是 DSH

简单说就是 DeepSeek 官方的对标 Codex、Claude Code 的工具。

{% asset_img 20261020-092914.png 20261020-092914 %}

全程 DeepSeek Harness，简称 DSH，后续也以 DSH 称呼。

## 安装

目前 dsh 已经有了官方的桌面版本，直接前往 [官网](https://www.deepseek.com/harness/) 进行下载即可：

{% asset_img 20261020-093229.png 20261020-093229 %}

## 开始使用

dsh 的设计是以工作区为基础的，对于工作区来说就是不同的文件夹。如果是从 Codex 迁移过来的，那么可以在侧边栏的工作区中配置一下展示的方式：

{% asset_img 20261020-093346.png 20261020-093346 %}

这里的按工作区树，就是按照电脑上的真实路径进行分组；随后就可以在特定的工作区中开始工作了。

## 安装插件

dsh 的核心就是插件系统，各种功能都可以通过插件使用。例如上面右下角的那个小鲸鱼插件。

对于插件可以直接去 [Github](https://github.com/topics/dsh-plugin) 进行搜索：

{% asset_img 20261020-093956.png 20261020-093956 %}

随后对于安装，由于使用的是桌面客户端，所以需要手动安装；如果用的是控制台版本，那么可以直接交给 dsh 进行安装。