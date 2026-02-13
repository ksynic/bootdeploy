#!/usr/bin/env bash
set -euo pipefail

# ---- terminal safety ----
export TERM="${TERM:-xterm-256color}"

# ---- colors ----
CYN='\033[0;36m'
GRN='\033[0;32m'
YEL='\033[0;33m'
RED='\033[0;31m'
BLU='\033[0;34m'
MAG='\033[0;35m'
WHT='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# ---- ui helpers ----
hr(){ printf "${CYN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }
ok(){ printf "${GRN}✅ %s${NC}\n" "$*"; }
warn(){ printf "${YEL}⚠️  %s${NC}\n" "$*"; }
err(){ printf "${RED}❌ %s${NC}\n" "$*"; }
info(){ printf "${BLU}ℹ️  %s${NC}\n" "$*"; }
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
    warn "建议使用 root/sudo 运行安装项（写 /etc、装服务、开端口常需要权限）"
    info "例如：sudo bash <(curl -fsSL https://raw.githubusercontent.com/ksynic/bootdeploy/main/launcher.sh)"
    hr
  fi
}

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
    err "下载失败：$url"
    warn "可能原因：网络/DNS/被拦截/URL 不存在"
    pause
    return 1
  fi

  chmod +x "$tmp" || true

  info "开始执行脚本..."
  if bash "$tmp"; then
    ok "完成：$label"
    rm -f "$tmp" || true
    pause
    return 0
  else
    local rc=$?
    err "失败：$label（退出码 $rc）"
    rm -f "$tmp" || true
    pause
    return "$rc"
  fi
}

draw_menu() {
  clear >/dev/null 2>&1 || true
  hr
  center_line "${BOLD}${MAG}BootDeploy${NC} ${DIM}· 远程执行版（不 clone/pull）${NC}"
  hr
  printf "${WHT}  1.${NC} ${GRN}AlpineXray 安装${NC}\n"
  printf "${WHT}  2.${NC} ${GRN}Alpine sing-box 安装${NC}\n"
  printf "${WHT}  3.${NC} ${GRN}DebianXray 安装${NC}\n"
  printf "${WHT}  4.${NC} ${GRN}Debian sing-box 安装${NC}\n"
  printf "${WHT}  5.${NC} ${YEL}一键卸载（占位）${NC}\n"
  printf "${WHT}  6.${NC} ${YEL}还原 VPS（占位）${NC}\n"
  printf "\n"
  printf "${WHT}  0.${NC} ${RED}退出${NC}\n"
  hr
}

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
      warn "卸载暂未实现：建议新增 uninstall.sh 或在各 install.sh 内实现卸载逻辑。"
      pause
      ;;
    6)
      need_root_hint
      warn "还原/清理暂未实现：更推荐云厂商快照恢复；如需安全清理脚本可再加。"
      pause
      ;;
    0|q|quit|exit)
      ok "已退出。"
      exit 0
      ;;
    *)
      err "无效选项：$choice"
      pause
      ;;
  esac
done
