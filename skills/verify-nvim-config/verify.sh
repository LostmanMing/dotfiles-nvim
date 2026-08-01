#!/usr/bin/env bash
# verify-nvim-config: 校验本仓库 Neovim 配置
# 用法：
#   skills/verify-nvim-config/verify.sh             # 校验所有 .lua + 启动烟测
#   skills/verify-nvim-config/verify.sh a.lua b.lua # 只语法校验指定文件 + 启动烟测
# 说明：交互/UI/键位类改动仍需按 SKILL.md 用 tmux 真实会话验证，本脚本只覆盖语法与启动。
set -u

# 仓库根（此脚本位于 <root>/skills/verify-nvim-config/）
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 2

fail=0

# 1. 语法校验
if [ "$#" -gt 0 ]; then
    files=("$@")
else
    mapfile -t files < <(find init.lua lua -name '*.lua' 2>/dev/null)
fi

echo "== 语法校验 =="
for f in "${files[@]}"; do
    err=$(nvim --headless -u NONE -c "lua local ok,e=loadfile('$f'); if not ok then io.stderr:write(e) end" -c "qa" 2>&1)
    if [ -n "$err" ]; then
        echo "FAIL  $f"
        echo "      $err"
        fail=1
    else
        echo "OK    $f"
    fi
done

# 2. 完整配置启动烟测
echo "== 启动烟测 =="
out=$(nvim --headless "+lua vim.defer_fn(function() print('STARTUP_OK') vim.cmd('qa!') end, 2000)" 2>&1)
if echo "$out" | grep -q "STARTUP_OK" && ! echo "$out" | grep -qiE "error|E[0-9]+:"; then
    echo "OK    完整配置启动无报错"
else
    echo "FAIL  启动有问题："
    echo "$out" | tail -20
    fail=1
fi

echo
if [ "$fail" -eq 0 ]; then
    echo "全部通过。交互/键位/UI 类改动请再按 SKILL.md 用 tmux 真实会话验证。"
else
    echo "存在失败项，修复后重跑。"
fi
exit "$fail"
