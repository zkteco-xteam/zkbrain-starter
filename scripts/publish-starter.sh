#!/usr/bin/env bash
set -e

TARGET_REPO="git@github.com:zkteco-xteam/zkbrain-starter.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=============================================================================="
echo "🌟 准备将公开脚手架发布到公司官方开源仓库: $TARGET_REPO"
echo "=============================================================================="

cd "$STARTER_ROOT"

if [ ! -d ".git" ]; then
    echo "📦 正在初始化独立的公开 Git 仓库..."
    git init -b main
    git remote add origin "$TARGET_REPO"
else
    git remote set-url origin "$TARGET_REPO"
fi

echo "📝 正在暂存并提交模板文件..."
git add .
git commit -m "feat: 发布 ZKBrain AI-Ready 跨平台脑机接口开源脚手架 v1.0.0" || true

echo "🚀 正在推送到公开 GitHub 仓库..."
git push origin main --force

echo "🎉 恭喜！ZKBrain Starter 公开脚手架已成功发布至: https://github.com/zkteco-xteam/zkbrain-starter"
