#!/usr/bin/env bash
set -euo pipefail

# 兼容一些控制台 TERM 为空/奇怪导致 tput/clear 出错
export TERM="${TERM:-xterm-256color}"

# ---------------- color support (never print \033 literally) ----------------
supports_color() {
  [[ -t 1 ]] || return 1
  [[ "${NO_COLOR:-0}" != "1" ]] || return 1
  [[ "${TERM:-}" != "dumb" ]] || return 1
  command -v tput >/dev/null 2>&1 || return 1
  [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]
}

if supports_color; then
  BLU=$'\033[0;34m'
  CYN=$'\033[0;36m'
  GRN=$'\033[0;32m'
  YEL=$'\033[0;33m'
  RED=$'\033[0;31m'
  MAG=$'\033[0;35m'
  WHT=$'\033[1;37m'
  DIM=$'\033[2m'
  BOLD=$'\033[1m'
  NC=$'\033[0m'
else
  BLU=""; CYN=""; GRN=""; YEL=""; RED=""; MAG=""; WHT=""; DIM=""; BOLD=""; NC=""
fi

# ---------------- UI helpers ----------------
hr(){ printf "${CYN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }
pause(){ read -r -p "$(printf "${DIM}按回车继续...${NC}")" _ < /dev/tty; }

center_line() {
  local s="$1"
  local cols="${COLUMNS:-80}"
  local len="${#s}"
  local pad=$(( (cols - len) / 2 ))
  (( pad < 0 )) && pad=0
  printf "%*s%s\n" "$pad" "" "$s"
}

need_root_hint() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    printf "${YEL}⚠️  建议使用 root/sudo 运行安装项（写 /etc、装服务、开端口）${NC}\n"
    printf "${BLU}ℹ️  例如：sudo bash <(curl -fsSL https://raw.githubusercontent.com/ksynic/bootdeploy/main/launcher.sh)${NC}\n"
    hr
  fi
}

# ---------------- Remote runner (no clone/pull) ----------------
run_remote() {
  local label="$1"
  local rel="$2"
  local url="https://raw.githubusercontent.com/ksynic/bootdeploy/main/$rel"
  local tmp="/tmp/bootdeploy_$(basename "$rel")"

  hr
  printf "${BOLD}${GRN}▶ %s${NC}\n" "$label"
  printf "${DIM}拉取并运行：%s${NC}\n" "$url"
  hr

  if ! curl -fsSL -o "$tmp" "$url"; then
    printf "${RED}❌ 下载失败：%s${NC}\n" "$url"
    pause
    return 1
  fi

  chmod +x "$tmp" || true
  bash "$tmp"
  local rc=$?

  rm -f "$tmp" || true
  hr
  if [[ $rc -eq 0 ]]; then
    printf "${GRN}✅ 完成：%s${NC}\n" "$label"
  else
    printf "${RED}❌ 失败：%s（退出码 %d）${NC}\n" "$label" "$rc"
  fi
  pause
  return "$rc"
}

draw_menu() {
  clear >/dev/null 2>&1 || true
  hr
  center_line "${BOLD}${MAG}BootDeploy${NC} ${DIM}· 远程执行版（不 clone/pull）${NC}"
  hr

  printf "  ${BOLD}${BLU}1.${NC} ${GRN}AlpineXray 安装${NC}\n"
  printf "  ${BOLD}${BLU}2.${NC} ${GRN}Alpine sing-box 安装${NC}\n"
  printf "  ${BOLD}${BLU}3.${NC} ${GRN}DebianXray 安装${NC}\n"
  printf "  ${BOLD}${BLU}4.${NC} ${GRN}Debian sing-box 安装${NC}\n"
  printf "  ${BOLD}${BLU}5.${NC} ${YEL}一键卸载（占位）${NC}\n"
  printf "  ${BOLD}${BLU}6.${NC} ${YEL}还原 VPS（占位）${NC}\n"
  printf "\n"
  printf "  ${BOLD}${RED}0.${NC} ${RED}退出${NC}\n"

  hr
}

# ---------------- Main loop ----------------
while true; do
  draw_menu
  read -r -p "$(printf "${BOLD}输入选项${NC} ${DIM}(0-6)${NC}: ")" choice < /dev/tty

  case "${choice,,}" in
    1) need_root_hint; run_remote "AlpineXray 安装" "AlpineXray/install.sh" ;;
    2) need_root_hint; run_remote "Alpine sing-box 安装" "AlpineSingbox/install.sh" ;;
    3) need_root_hint; run_remote "DebianXray 安装" "DebianXray/install.sh" ;;
    4) need_root_hint; run_remote "Debian sing-box 安装" "DebianSingbox/install.sh" ;;
    5)
      need_root_hint
      printf "${YEL}卸载暂未实现：建议新增 uninstall.sh 或在各 install.sh 内实现卸载逻辑。${NC}\n"
      pause
      ;;
    6)
      need_root_hint
      printf "${YEL}还原/清理暂未实现：更推荐云厂商快照恢复；如需安全清理脚本可再加。${NC}\n"
      pause
      ;;
    0|q|quit|exit)
      printf "${GRN}✅ 已退出。${NC}\n"
      exit 0
      ;;
    *)
      printf "${RED}无效选项：%s${NC}\n" "$choice"
      pause
      ;;
  esac
done
