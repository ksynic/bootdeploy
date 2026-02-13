#!/bin/bash
set -e

# ===== 可配置：把你的脚本放这里 =====
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

run_script() {
  local script="$1"
  local path="$SCRIPTS_DIR/$script"

  if [[ ! -f "$path" ]]; then
    echo "❌ 找不到脚本：$path"
    return 1
  fi

  if [[ ! -x "$path" ]]; then
    echo "ℹ️ 没有执行权限，自动加权限：$path"
    chmod +x "$path"
  fi

  echo "▶ 开始执行：$script"
  "$path"
  echo "✅ 执行完成：$script"
}

pause() {
  read -r -p "按回车继续..." _
}

while true; do
  clear
  echo "=============================="
  echo "        脚本菜单 (Menu)        "
  echo "=============================="
  echo "1) 运行 a.sh"
  echo "2) 运行 b.sh"
  echo "3) 运行 c.sh"
  echo "4) 全部顺序执行"
  echo "5) 查看脚本目录"
  echo "0) 退出"
  echo "------------------------------"
  read -r -p "请输入选项: " choice

  case "$choice" in
    1) run_script "a.sh"; pause ;;
    2) run_script "b.sh"; pause ;;
    3) run_script "c.sh"; pause ;;
    4)
      run_script "a.sh"
      run_script "b.sh"
      run_script "c.sh"
      pause
      ;;
    5)
      echo "脚本目录：$SCRIPTS_DIR"
      ls -lah "$SCRIPTS_DIR"
      pause
      ;;
    0) echo "👋 已退出"; exit 0 ;;
    *) echo "⚠️ 无效选项：$choice"; pause ;;
  esac
done
