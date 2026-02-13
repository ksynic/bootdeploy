#!/usr/bin/env bash
set -euo pipefail

# ===== 配置 =====
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
GLOB_PATTERN="*.sh"
SELF_NAME="$(basename "$0")"

# ===== 颜色（终端支持就会显示）=====
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'; MAGENTA=$'\033[0;35m'; CYAN=$'\033[0;36m'
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; MAGENTA=""; CYAN=""; BOLD=""; DIM=""; RESET=""
fi

hr() { printf "%s\n" "------------------------------------------------------------"; }
pause() { read -r -p "按回车继续..." _; }

# 从脚本里提取描述：使用一行注释 `# DESC: xxxx`
get_desc() {
  local file="$1"
  local desc
  desc="$(grep -m1 -E '^[[:space:]]*#\s*DESC:' "$file" 2>/dev/null | sed -E 's/^[[:space:]]*#\s*DESC:\s*//')"
  [[ -n "${desc:-}" ]] && echo "$desc" || echo "（无描述，可在脚本里加：# DESC: ...）"
}

# 收集脚本列表（排除 menu.sh 自己）
load_scripts() {
  mapfile -t SCRIPTS < <(find "$SCRIPTS_DIR" -maxdepth 1 -type f -name "$GLOB_PATTERN" -printf "%f\n" \
    | sort \
    | grep -v -x "$SELF_NAME")
}

run_script() {
  local script="$1"
  local path="$SCRIPTS_DIR/$script"

  if [[ ! -f "$path" ]]; then
    echo "${RED}❌ 找不到脚本：$path${RESET}"
    return 1
  fi

  if [[ ! -x "$path" ]]; then
    chmod +x "$path" || true
  fi

  echo "${CYAN}▶ 执行：${BOLD}$script${RESET}"
  echo "${DIM}路径：$path${RESET}"
  hr
  # 用 bash 执行更稳（不依赖 shebang 是否正确）
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
    echo "把脚本放到：$SCRIPTS_DIR"
    hr
    echo "0) 退出"
    read -r -p "请输入选项: " choice
    [[ "$choice" == "0" ]] && exit 0
    continue
  fi

  # 显示脚本列表
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
