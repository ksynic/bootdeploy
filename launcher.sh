#!/usr/bin/env bash
set -euo pipefail

# =========  UI  =========
RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[0;33m'
BLU='\033[0;34m'
CYN='\033[0;36m'
NC='\033[0m'

hr() { printf "${CYN}------------------------------------------------------------${NC}\n"; }
title() {
  clear || true
  hr
  printf "${BLU}  BootDeploy 主菜单${NC}\n"
  printf "  路径：%s\n" "$(pwd)"
  hr
}
pause() { read -r -p "按回车继续..." _; }

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    printf "${YEL}提示：建议使用 root 运行（否则安装/卸载可能失败）。${NC}\n"
    printf "你可以用：sudo bash launcher.sh\n"
    pause
  fi
}

# =========  helper  =========
script_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# 在多个可能的目录名里找 install.sh（兼容你现有的拼写）
find_install_sh() {
  local candidates=("$@")
  local base
  base="$(script_dir)"
  for d in "${candidates[@]}"; do
    if [[ -f "$base/$d/install.sh" ]]; then
      printf "%s\n" "$base/$d/install.sh"
      return 0
    fi
  done
  return 1
}

run_install() {
  local name="$1"; shift
  local path
  if ! path="$(find_install_sh "$@")"; then
    printf "${RED}❌ 未找到 ${name} 的 install.sh。请确认目录存在且包含 install.sh${NC}\n"
    hr
    printf "我尝试过这些路径：\n"
    for d in "$@"; do printf "  - %s/install.sh\n" "$d"; done
    hr
    pause
    return 1
  fi

  title
  printf "${GRN}▶ 开始：%s${NC}\n" "$name"
  printf "使用脚本：%s\n" "$path"
  hr
  chmod +x "$path" || true
  # shellcheck disable=SC1090
  bash "$path"
  hr
  printf "${GRN}✅ 完成：%s${NC}\n" "$name"
  pause
}

# =========  uninstall / restore  =========
stop_disable_service() {
  local svc="$1"

  # systemd
  if command -v systemctl >/dev/null 2>&1; then
    systemctl stop "$svc" >/dev/null 2>&1 || true
    systemctl disable "$svc" >/dev/null 2>&1 || true
    systemctl daemon-reload >/dev/null 2>&1 || true
  fi

  # openrc
  if command -v rc-service >/dev/null 2>&1; then
    rc-service "$svc" stop >/dev/null 2>&1 || true
  fi
  if command -v rc-update >/dev/null 2>&1; then
    rc-update del "$svc" default >/dev/null 2>&1 || true
  fi
}

remove_files() {
  # 只清理常见路径：你可以按自己实际安装路径再加
  rm -f  /usr/local/bin/xray /usr/bin/xray /bin/xray 2>/dev/null || true
  rm -f  /usr/local/bin/sing-box /usr/bin/sing-box /bin/sing-box 2>/dev/null || true

  rm -f  /etc/systemd/system/xray.service /etc/systemd/system/sing-box.service 2>/dev/null || true
  rm -f  /lib/systemd/system/xray.service /lib/systemd/system/sing-box.service 2>/dev/null || true

  rm -f  /etc/init.d/xray /etc/init.d/sing-box 2>/dev/null || true

  rm -rf /etc/xray /etc/sing-box 2>/dev/null || true
  rm -rf /var/log/xray /var/log/sing-box 2>/dev/null || true
  rm -rf /var/lib/xray /var/lib/sing-box 2>/dev/null || true
}

uninstall_xray_singbox() {
  title
  need_root
  printf "${YEL}⚠️ 将卸载：Xray / sing-box（仅清理常见安装项）${NC}\n"
  printf "会尝试停止服务、删除二进制、删除配置目录。\n"
  hr
  read -r -p "确认继续卸载？(y/N): " yn
  if [[ "${yn,,}" != "y" ]]; then
    printf "已取消。\n"
    pause
    return 0
  fi

  stop_disable_service "xray" || true
  stop_disable_service "sing-box" || true
  remove_files

  printf "${GRN}✅ 卸载/清理完成。${NC}\n"
  pause
}

restore_vps_soft() {
  title
  need_root
  printf "${RED}⚠️ 还原 VPS（安全版）${NC}\n"
  printf "这个“还原”不会重装系统，只会：\n"
  printf "  - 停止/禁用 xray、sing-box 服务\n"
  printf "  - 删除 xray、sing-box 二进制/配置/日志（常见路径）\n"
  printf "  - 不会删除你的其它程序/用户/系统文件\n"
  hr
  read -r -p "确认执行“安全还原”？(y/N): " yn
  if [[ "${yn,,}" != "y" ]]; then
    printf "已取消。\n"
    pause
    return 0
  fi

  stop_disable_service "xray" || true
  stop_disable_service "sing-box" || true
  remove_files

  printf "${GRN}✅ 安全还原完成。${NC}\n"
  pause
}

# =========  menu  =========
menu() {
  title
  printf "${CYN}请选择：${NC}\n"
  printf "  ${GRN}1.${NC} AlpineXray 安装\n"
  printf "  ${GRN}2.${NC} Alpine sing-box 安装\n"
  printf "  ${GRN}3.${NC} DebianXray 安装\n"
  printf "  ${GRN}4.${NC} Debian sing-box 安装\n"
  printf "  ${YEL}5.${NC} 一键卸载 Xray/sing-box\n"
  printf "  ${RED}6.${NC} 还原 VPS（安全清理版）\n"
  printf "  ${BLU}0.${NC} 退出\n"
  hr
}

main() {
  while true; do
    menu
    read -r -p "输入选项: " choice
    case "$choice" in
      1)
        run_install "AlpineXray 安装" \
          "AlpineXray" "ApineXray" "Alpine/Xray" "AlpineXrayCore"
        ;;
      2)
        run_install "Alpine sing-box 安装" \
          "Alpinesing-box" "Aplinesingbox" "AlpineSingbox" "Alpine/sing-box" "Alpine/singbox"
        ;;
      3)
        run_install "DebianXray 安装" \
          "DebianXray" "DebainXray" "Debian/Xray"
        ;;
      4)
        run_install "Debian sing-box 安装" \
          "Debiansing-box" "DebainSingbox" "DebianSingbox" "Debian/sing-box" "Debian/singbox"
        ;;
      5)
        uninstall_xray_singbox
        ;;
      6)
        restore_vps_soft
        ;;
      0|q|quit|exit)
        printf "Bye.\n"
        exit 0
        ;;
      *)
        printf "${RED}无效选项：%s${NC}\n" "$choice"
        pause
        ;;
    esac
  done
}

main
