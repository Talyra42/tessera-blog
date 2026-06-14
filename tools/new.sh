#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ] || [ -z "${1// }" ]; then
  echo "用法: ./tools/new.sh \"文章标题\""
  echo "错误: 缺少文章标题，未创建文章。"
  exit 1
fi

title="$1"

npx hexo new post "$title"
