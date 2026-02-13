#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/ksynic/bootdeploy.git"
INSTALL_DIR="$HOME/bootdeploy"

# ===== 自举：确保在真实仓库目录运行（解决 /dev/fd、/proc/self/fd）=====
bootstrap_if_needed() {
  # 尝试获取脚本所在目录（管道运行时可能是 /dev/fd 或 /proc/.../fd）
  local src="${BASH_SOURCE[0]}"
  local rp=""
  rp="$(readlink -f "$src" 2>/dev/null || true)"

  # 计算“当前根目录”
  local root=""
  root="$(cd "$(dirname "$src")" 2>/dev/null && pwd || true)"

  # 关键文件（只要有一个不存在，就说明不是仓库目录）
  local must1="AlpineSingbox/install.sh"
  local must2="AlpineXray/install.sh"
  local must3="DebianSingbox/install.sh"
  local must4="DebianXray/install.sh"

  # 判断是否是“fd 临时路径”
  local is_fd="false"
  if [[ "$src" == /dev/fd/* ]] || [[ "$root" == /dev/fd* ]]; then
    is_fd="true"
  fi
  if [[ "$rp" == /proc/*/fd/* ]] || [[ "$rp" == /proc/self/fd/* ]]; then
    is_fd="true"
  fi

  # 判断是否缺关键文件
  local missing="false"
  if [[ -z "$root" ]] || [[ ! -f "$root/$must1" ]] || [[ ! -f "$root/$must2" ]] || [[ ! -f "$root/$must3" ]] || [[ ! -f "$root/$must4" ]]; then
    missing="true"
  fi

  # 只要是 fd 运行，或者缺关键文件 -> bootstrap
  if [[ "$is_fd" == "true" || "$missing" == "true" ]]; then
    echo "检测到非仓库目录运行（可能是 /dev/fd 或缺少目录结构），开始自举到：$INSTALL_DIR"

    # 确保有 git
    if ! command -v git >/dev/null 2>&1; then
      echo "❌ 系统未安装 git，请先安装 git 后再运行。"
      echo "Debian/Ubuntu: apt-get update && apt-get install -y git"
      echo "Alpine: apk add --no-cache git"
      exit 1
    fi

    if [[ ! -d "$INSTALL_DIR/.git" ]]; then
      rm -rf "$INSTALL_DIR" >/dev/null 2>&1 || true
      git clone "$REPO_URL" "$INSTALL_DIR"
    fi

    cd "$INSTALL_DIR"
    git pull --rebase || git pull || true

    echo "重新启动本地版本：$INSTALL_DIR/launcher.sh"
    exec bash "$INSTALL_DIR/launcher.sh"
  fi
}

bootstrap_if_needed

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
    printf "当前运行目录：%s\n" "$ROOT_DIR"
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
    0|q|quit|exit) exit 0 ;;
    *) printf "${RED}无效选项：%s${NC}\n" "$choice"; pause ;;
  esac
done
