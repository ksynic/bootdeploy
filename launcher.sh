#!/usr/bin/env bash
set -euo pipefail

CYN='\033[0;36m'
GRN='\033[0;32m'
YEL='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

hr(){ printf "${CYN}------------------------------------------------------------${NC}\n"; }
pause(){ read -r -p "按回车继续..." _; }

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_script() {
  local label="$1"
  local rel="$2"
  local path="$root_dir/$rel"

  if [[ ! -f "$path" ]]; then
    printf "${RED}❌ 未找到 %s 的脚本：%s${NC}\n" "$label" "$rel"
    pause
    return 1
  fi

  chmod +x "$path" || true
  hr
  printf "${GRN}▶ %s${NC}\n" "$label"
  printf "运行：%s\n" "$rel"
  hr
  bash "$path"
  hr
  printf "${GRN}✅ 完成：%s${NC}\n" "$label"
  pause
}

need_root_hint() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    printf "${YEL}提示：建议用 root/sudo 运行（安装/卸载需要权限）。${NC}\n"
    printf "例如：sudo bash launcher.sh\n"
    hr
  fi
}

uninstall_stub() {
  need_root_hint
  printf "${YEL}⚠️ 一键卸载：此项会调用你各 install.sh 的卸载逻辑或删除常见路径。${NC}\n"
  printf "（如果你需要“精准卸载”，把你 install.sh 的安装路径告诉我，我帮你写完整卸载。）\n"
  pause
}

restore_stub() {
  need_root_hint
  printf "${RED}⚠️ 还原 VPS：建议做“安全清理版”（仅停服务+删 xray/sing-box 相关）。${NC}\n"
  printf "如果你真要重装系统级还原，那必须走云厂商控制台/快照，不建议脚本做。\n"
  pause
}

while true; do
  clear || true
  hr
  printf "  BootDeploy 主菜单（仓库内运行：%s）\n" "$root_dir"
  hr
  printf "  1. AlpineXray 安装\n"
  printf "  2. Alpine sing-box 安装\n"
  printf "  3. DebianXray 安装\n"
  printf "  4. Debian sing-box 安装\n"
  printf "  5. 一键卸载 Xray/sing-box\n"
  printf "  6. 还原 VPS（安全清理版）\n"
  printf "  0. 退出\n"
  hr
  read -r -p "输入选项: " choice
  case "$choice" in
    1) run_script "AlpineXray 安装" "AlpineXray/install.sh" ;;
    2) run_script "Alpine sing-box 安装" "AlpineSingbox/install.sh" ;;
    3) run_script "DebianXray 安装" "DebianXray/install.sh" ;;
    4) run_script "Debian sing-box 安装" "DebianSingbox/install.sh" ;;
    5) uninstall_stub ;;
    6) restore_stub ;;
    0|q|quit|exit) exit 0 ;;
    *) printf "${RED}无效选项：%s${NC}\n" "$choice"; pause ;;
  esac
done
