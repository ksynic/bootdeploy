#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SELF_NAME="$(basename "$0")"
GLOB_PATTERN="*.sh"

# 颜色（终端支持就显示）
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'; MAGENTA=$'\033[0;35m'; CYAN=$'\033[0;36m'
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; MAGENTA=""; CYAN=""; BOLD=""; DIM=""; RESET=""
fi

hr() { printf "%s\n" "------------------------------------------------------------"; }
pause() { read -r -p "按回车继续..." _; }

get_desc() {
  local file="$1"
  local desc=""
  desc="$(grep -m1 -E '^[[:space:]]*#\s*DESC:' "$file" 2>/dev/null | sed -E 's/^[[:space:]]*#\s*DESC:\s*//')"
  [[ -n "${desc:-}" ]] && echo "$desc" || echo "（无描述，可在脚本里加：# DESC: ...）"
}

# ✅ 不用 < <(...)，避免 /dev/fd 依赖
load_scripts() {
  SCRIPTS=()
  # 用 find + sort，然后 while read 收集到数组
  # -print0 / read -d '' 更安全（文件名含空格），但 mac 的 bash 3.2 对 read -d 支持也OK
  while IFS= read -r script; do
    [[ "$script" == "$SELF_NAME" ]] && continue
    SCRIPTS+=("$script")
  done < <(find "$SCRIPTS_DIR" -maxdepth 1 -type f -name "$GLOB_PATTERN" -printf "%f\n" 2>/dev/null | sort)

  # 如果你的环境 find 不支持 -printf（比如 macOS 默认 find），用下面替代（取消注释即可）：
  # while IFS= read -r path; do
  #   script="$(basename "$path")"
  #   [[ "$script" == "$SELF_NAME" ]] && continue
  #   SCRIPTS+=("$script")
  # done < <(find "$SCRIPTS_DIR" -maxdepth 1 -type f -name "$GLOB_PATTERN" 2>/dev/null | sort)
}

run_script() {
  local script="$1"
  local path="$SCRIPTS_DIR/$script"

  if [[ ! -f "$path" ]]; then
    echo "${RED}❌ 找不到脚本：$path${RESET}"
    return 1
  fi

  # 自动加执行权限（对本次运行有效；要持久化到 Git 需要 git update-index）
  if [[ ! -x "$path" ]]; then
    chmod +x "$path" || true
  fi

  echo "${CYAN}▶ 执行：${BOLD}$script${RESET}"
  echo "${DIM}路径：$path${RESET}"
  hr
  bash "$path"
  hr
  echo "${GREEN}✅ 完成：$script${RESET}"
}

run_all() {
  echo "${MAGENTA}${BOLD}▶ 顺序执行全部脚本${RESET}"
  hr
  for s in "${SCRIPTS[@]}"; do
    run_script "$s"
  done
  echo "${GREEN}${BOLD}✅ 全部执行完成${RESET}"
}

while true; do
  load_scripts
  clear

  echo "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════╗${RESET}"
  echo "${BOLD}${BLUE}║                     主菜单 Script Hub                   ║${RESET}"
  echo "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════╝${RESET}"
  echo "${DIM}目录：$SCRIPTS_DIR${RESET}"
  hr

  if (( ${#SCRIPTS[@]} == 0 )); then
    echo "${YELLOW}⚠️ 当前目录没有可执行脚本（*.sh）。${RESET}"
    hr
    echo "0) 退出"
    read -r -p "请输入选项: " choice
    [[ "$choice" == "0" ]] && exit 0
    continue
  fi

  for i in "${!SCRIPTS[@]}"; do
    idx=$((i+1))
    script="${SCRIPTS[$i]}"
    desc="$(get_desc "$SCRIPTS_DIR/$script")"
    printf "%s%2d)%s %s%s%s\n" "$CYAN" "$idx" "$RESET" "$BOLD" "$script" "$RESET"
    printf "    %s%s%s\n" "$DIM" "$desc" "$RESET"
  done

  hr
  echo "a) 全部顺序执行"
  echo "r) 刷新脚本列表"
  echo "0) 退出"
  hr

  read -r -p "请输入选项（数字/a/r/0）: " choice

  case "$choice" in
    0) echo "👋 已退出"; exit 0 ;;
    a|A) run_all; pause ;;
    r|R) continue ;;
    *)
      if [[ "$choice" =~ ^[0-9]+$ ]]; then
        n="$choice"
        if (( n >= 1 && n <= ${#SCRIPTS[@]} )); then
          run_script "${SCRIPTS[$((n-1))]}"
          pause
        else
          echo "${RED}❌ 无效编号：$choice${RESET}"
          pause
        fi
      else
        echo "${RED}❌ 无效输入：$choice${RESET}"
        pause
      fi
      ;;
  esac
done
