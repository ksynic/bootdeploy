#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/ksynic/bootdeploy.git"
INSTALL_DIR="$HOME/bootdeploy"

# ===== 自举检测（解决 /dev/fd 问题）=====
SELF_PATH="$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"

if [[ "$SELF_PATH" == /dev/fd/* ]] || [[ "$SELF_PATH" == *"curl"* ]]; then
  echo "检测到通过临时管道运行，开始自动部署到 $INSTALL_DIR..."

  if [[ ! -d "$INSTALL_DIR" ]]; then
    git clone "$REPO_URL" "$INSTALL_DIR"
  fi

  cd "$INSTALL_DIR"
  git pull || true

  echo "重新启动本地版本..."
  exec bash "$INSTALL_DIR/launcher.sh"
fi

# ===== 正常运行逻辑 =====

CYN='\033[0;36m'
GRN='\033[0;32m'
YEL='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

hr(){ printf "${CYN}------------------------------------------------------------${NC}\n"; }
pause(){ read -r -p "按回车继续..." _; }

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_script() {
  local label="$1"
  local rel="$2"
  local path="$ROOT_DIR/$rel"

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
    printf "${YEL}提示：建议使用 root/sudo 运行安装项${NC}\n"
    printf "例如：sudo bash launcher.sh\n"
    hr
  fi
}

while true; do
  clear || true
  hr
  printf "  BootDeploy 主菜单（运行路径：%s）\n" "$ROOT_DIR"
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
    5)
      need_root_hint
      echo "请在各 install.sh 中实现卸载逻辑，或告诉我安装路径我帮你做完整卸载。"
      pause
      ;;
    6)
      need_root_hint
      echo "建议通过云厂商控制台恢复系统快照。如需安全清理版，我可为你写完整逻辑。"
      pause
      ;;
    0|q|quit|exit)
      exit 0
      ;;
    *)
      printf "${RED}无效选项：%s${NC}\n" "$choice"
      pause
      ;;
  esac
done
