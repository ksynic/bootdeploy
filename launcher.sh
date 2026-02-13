#!/usr/bin/env bash
set -euo pipefail

# 兼容部分终端环境
export TERM="${TERM:-xterm-256color}"

CYN='\033[0;36m'
GRN='\033[0;32m'
YEL='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

hr(){ printf "${CYN}------------------------------------------------------------${NC}\n"; }
pause(){ read -r -p "按回车继续..." _ < /dev/tty; }

need_root_hint() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    printf "${YEL}提示：建议使用 root/sudo 运行安装项${NC}\n"
    printf "例如：sudo bash <(curl -fsSL https://raw.githubusercontent.com/ksynic/bootdeploy/main/launcher.sh)\n"
    hr
  fi
}

run_remote() {
  local label="$1"
  local rel="$2"
  local url="https://raw.githubusercontent.com/ksynic/bootdeploy/main/$rel"
  local tmp="/tmp/bootdeploy_$(basename "$rel")"

  hr
  printf "${GRN}▶ %s${NC}\n" "$label"
  printf "拉取并运行：%s\n" "$url"
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
  return $rc
}

while true; do
  clear >/dev/null 2>&1 || true
  hr
  printf "  BootDeploy 主菜单（远程执行版）\n"
  hr
  printf "  1. AlpineXray 安装\n"
  printf "  2. Alpine sing-box 安装\n"
  printf "  3. DebianXray 安装\n"
  printf "  4. Debian sing-box 安装\n"
  printf "  0. 退出\n"
  hr

  read -r -p "输入选项: " choice < /dev/tty

  case "$choice" in
    1) need_root_hint; run_remote "AlpineXray 安装" "AlpineXray/install.sh" ;;
    2) need_root_hint; run_remote "Alpine sing-box 安装" "AlpineSingbox/install.sh" ;;
    3) need_root_hint; run_remote "DebianXray 安装" "DebianXray/install.sh" ;;
    4) need_root_hint; run_remote "Debian sing-box 安装" "DebianSingbox/install.sh" ;;
    0|q|quit|exit) exit 0 ;;
    *)
      printf "${RED}无效选项：%s${NC}\n" "$choice"
      pause
      ;;
  esac
done
