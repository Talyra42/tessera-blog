# Tessera

Talyra42 的个人博客，基于 [Hexo](https://hexo.io/) 搭建，使用 tessera 主题。

线上地址：<https://blog.talyra42.top/>

## 环境准备

```bash
pnpm install
```

## 常用命令

### 创建文章

```bash
npx hexo new post "文章标题"
```

生成的 Markdown 文件位于 [source/_posts/](source/_posts/)。

### 本地运行

```bash
./run.sh
```

等价于 `pnpm clean && pnpm server`，会先清理缓存再启动本地服务，默认访问 <http://localhost:4000>。

### 构建与部署

```bash
pnpm build    # 生成静态文件到 public/
pnpm deploy   # 部署
```

## 写作规范

### 插入图片

图片素材统一放在 [source/images/](source/images/) 目录下，在文章中通过根路径引用：

```markdown
![描述文字](/images/example.jpg)
```

> 路径以 `/` 开头表示网站根路径，构建后图片会被复制到 `public/images/`，链接稳定且方便复用，不受文章 permalink 影响。

## 目录结构

```
.
├── source/
│   ├── _posts/      # 文章
│   └── images/      # 图片素材
├── themes/tessera/  # 主题
├── _config.yml      # 站点配置
├── run.sh           # 本地运行脚本
└── package.json
```
