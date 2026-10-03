# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概览

Talyra42 的个人博客（<https://blog.talyra42.top/>），Hexo 8 静态站点。主题 **Tessera** 以完整源码形式内联在 [themes/tessera/](themes/tessera/)（不是 git submodule，222 个文件受版本控制），作者与本仓库同一人。文章内容为中文，`permalink: :year/:month/:day/:title/`。

## 常用命令

包管理用 **bun**（存在 `bun.lock`）。仓库内没有 CI / 部署配置：`_config.yml` 的 `deploy.type` 为空，线上部署依靠 `bun run build` 产出的 `public/`（`_config.yml` 注释提到 Vercel）。

```bash
bun install                 # 安装依赖
./tools/new.sh "文章标题"    # 新建文章（内部调用 npx hexo new post，套用 scaffolds/post.md）
./tools/run.sh              # 本地预览 = bun run clean && bun run server，默认 http://localhost:4000
bun run build               # hexo generate → public/
bun run clean               # hexo clean
bun run server              # hexo server（不清理缓存）
bun run deploy              # hexo deploy（当前配置为空，实际部署靠构建产物）
```

`tools/*.sh` 是 POSIX 脚本，Windows 下需在 Git Bash 中运行（Bash 工具可直接执行），不要用 PowerShell 调 `./tools/run.sh`。

没有测试框架；仓库级别的验证手段就是 `bun run build` 跑通、产物正常。

## 架构要点

### 配置的三层合并（改主题行为时的关键）

主题配置按以下顺序合并，后者覆盖前者：

1. [themes/tessera/scripts/common/default_config.js](themes/tessera/scripts/common/default_config.js) — 代码内置默认值
2. [themes/tessera/_config.yml](themes/tessera/_config.yml) — 主题自带配置（28KB，中文注释）
3. [_config.tessera.yml](_config.tessera.yml) — **站点级个性化覆盖，本仓库只应改这里**

合并由 Hexo 的 `_config.[theme].yml` 机制加上主题内 [init.js](themes/tessera/scripts/events/init.js) 的 `before_generate` 钩子完成（`deepMerge(defaultConfig, hexo.theme.config)`，优先级 1）。**对象是深合并，数组是整组替换**——所以覆盖 `home_top.icons`、`home_top.category` 这类数组时必须写全，不会与主题默认值合并。`init.js` 还在此处校验 Hexo ≥ 5.3.0、拦截已废弃的 `tessera.yml`、并把 `comments.use` 归一化为数组。

站点根 `_config.yml` 只管 Hexo 本身（URL、permalink、目录、渲染器、生成器），不含主题项。

### 主题内部结构

主题通过 Hexo 插件 API 在 `themes/tessera/scripts/` 注册钩子，无需在站点层写插件：

- `events/` — `before_generate` 配置合并、stylus 渲染期变量注入、CDN、404、右键菜单数据等
- `filters/` — `random_cover.js`（`cover.random_cover_dir` 指定的目录随机取封面，优先于 `default_cover`）、正文懒加载
- `helpers/`、`tag/` — Pug 助手与标签插件（note/tabs/gallery/timeline/mermaid/chartjs/flink/button/series/hide/inlineImg/label/score）

模板在 `layout/**.pug`，样式在 `source/css/**.styl`（Stylus），前端脚本在 `source/js/`，多语言在 `languages/`（七套 key 必须保持一致）。

### 主题更新方式

`themes/tessera/dist/tessera-v1.1.3.zip` 是上游 release 包（`dist/` 被主题自身 `.gitignore` 忽略，不进版本库）。更新主题 = 解压覆盖 `themes/tessera/`，因此**直接改主题目录的改动会在下次升级时丢失**——站点自定义一律放 `_config.tessera.yml`。若确实需要改主题源码，记住这里是 vendored 副本，改动不会回流到上游仓库 `LumiDesk/hexo-theme-tessera`。

### 内容约定

- 文章在 [source/_posts/](source/_posts/)，front matter：`title` / `date` / `tags` / `categories`。
- 图片统一放 [source/images/](source/images/)，文章中以**根路径**引用：`![](/images/foo.png)`。虽然 `_config.yml` 开了 `post_asset_folder: true`，但本仓库不使用每篇文章的资源目录，也没有 `asset_img` 用法。
- 未设 `cover` 的文章从 [source/cover/](source/cover/) 随机取封面（`cover.random_cover_dir: cover`）。
- 独立页面放 `source/about/`、`source/categories/`、`source/tags/`，用 front matter 的 `type: about|categories|tags` 绑定主题模板。
- 部分主题功能依赖站点根目录的 Hexo 插件：字数统计/阅读时长需 `hexo-wordcount`，本地搜索需 `hexo-generator-searchdb`（均已在 `package.json`）。启用 `_config.tessera.yml` 里的 `wordcount` / `search` 前先确认对应插件已安装。

## 其他

- `db.json`、`public/`、`node_modules/` 均被 gitignore，不要提交；`db.json` 是 Hexo 缓存，渲染异常时先 `bun run clean`。
- Dependabot 每日检查 npm 依赖（[.github/dependabot.yml](.github/dependabot.yml)）。
- [.hexo-workbench.yml](.hexo-workbench.yml) 供 VS Code 的 Hexo Workbench 扩展使用（新建文章的 front matter 模板），与 Hexo 构建无关。
