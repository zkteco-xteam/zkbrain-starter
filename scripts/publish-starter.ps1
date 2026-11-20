# ==============================================================================
# 🚀 ZKBrain Starter Kit 一键初始化并发布到公开 GitHub 仓库脚本
# ==============================================================================
$ErrorActionPreference = "Stop"

$TARGET_REPO = "git@github.com:zkteco-xteam/zkbrain-starter.git"
$CURRENT_DIR = Split-Path -Parent $PSScriptRoot

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "🌟 准备将公开脚手架发布到公司官方开源仓库: $TARGET_REPO" -ForegroundColor Yellow
Write-Host "==============================================================================" -ForegroundColor Cyan

Set-Location $CURRENT_DIR

# 1. 检查是否存在 .git 目录，若没有则初始化
if (-not (Test-Path ".git")) {
    Write-Host "📦 正在初始化独立的公开 Git 仓库..." -ForegroundColor Green
    git init -b main
    git remote add origin $TARGET_REPO
} else {
    git remote set-url origin $TARGET_REPO
}

# 2. 添加并提交全部模板文件
Write-Host "📝 正在暂存并提交模板文件..." -ForegroundColor Green
git add .
git commit -m "feat: 发布 ZKBrain AI-Ready 跨平台脑机接口开源脚手架 v1.0.0" -ErrorAction SilentlyContinue

# 3. 强推到公开仓库 main 分支
Write-Host "🚀 正在推送到公开 GitHub 仓库..." -ForegroundColor Green
git push origin main --force

Write-Host "`n🎉 恭喜！ZKBrain Starter 公开脚手架已成功发布至: https://github.com/zkteco-xteam/zkbrain-starter" -ForegroundColor Cyan
