#!/usr/bin/env bash
set -euo pipefail

export TERM="${TERM:-xterm-256color}"

# ---------------- color & tty ----------------
supports_color() {
  [[ -t 1 ]] || return 1
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
  REV=$'\033[7m'
  NC=$'\033[0m'
else
  BLU=""; CYN=""; GRN=""; YEL=""; RED=""; MAG=""; WHT=""; DIM=""; BOLD=""; REV=""; NC=""
fi

hr(){ printf "${CYN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }
pause(){ read -r -p "$(printf "${DIM}按回车继续...${NC}")" _ < /dev/tty; }
die(){ printf "${RED}❌ %s${NC}\n" "$*"; exit 1; }

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

  if bash "$tmp"; then
    rm -f "$tmp" || true
    hr
    printf "${GRN}✅ 完成：%s${NC}\n" "$label"
    pause
    return 0
  else
    local rc=$?
    rm -f "$tmp" || true
    hr
    printf "${RED}❌ 失败：%s（退出码 %d）${NC}\n" "$label" "$rc"
    pause
    return "$rc"
  fi
}

# ---------------- TUI ----------------
cleanup() {
  stty echo 2>/dev/null || true
  tput cnorm 2>/dev/null || true
}
trap cleanup EXIT

# items: "title|color|action"
# action = "remote:<path>" or "msg:<text>" or "exit"
MENU_ITEMS=(
  "AlpineXray 安装|GRN|remote:AlpineXray/install.sh"
  "Alpine sing-box 安装|GRN|remote:AlpineSingbox/install.sh"
  "DebianXray 安装|GRN|remote:DebianXray/install.sh"
  "Debian sing-box 安装|GRN|remote:DebianSingbox/install.sh"
  "一键卸载（占位）|YEL|msg:卸载暂未实现：建议新增 uninstall.sh 或在各 install.sh 内实现。"
  "还原 VPS（占位）|YEL|msg:还原/清理暂未实现：更推荐云厂商快照恢复；如需安全清理脚本可再加。"
  "退出|RED|exit"
)

render_menu() {
  local selected="$1"
  clear >/dev/null 2>&1 || true
  hr
  center_line "${BOLD}${MAG}BootDeploy${NC} ${DIM}· 专业运维面板（↑↓ 选择 / Enter 执行 / q 退出）${NC}"
  hr

  printf "${DIM}提示：脚本将从 GitHub 拉取 install.sh 并在本机执行（不 clone/pull）。${NC}\n"
  printf "${DIM}当前主机：$(hostname) · 用户：$(whoami) · 时间：$(date '+%F %T')${NC}\n"
  hr

  local i=0
  for item in "${MENU_ITEMS[@]}"; do
    IFS='|' read -r title color _action <<<"$item"
    local num=$((i+1))

    # resolve color var name
    local c=""
    case "$color" in
      GRN) c="$GRN" ;;
      YEL) c="$YEL" ;;
      RED) c="$RED" ;;
      *) c="$NC" ;;
    esac

    if [[ "$i" -eq "$selected" ]]; then
      printf "  ${REV}${BOLD}${BLU}%2d.${NC}${REV} %s%s${NC}${REV} ${NC}\n" "$num" "$c" "$title"
    else
      printf "  ${BOLD}${BLU}%2d.${NC} %s%s${NC}\n" "$num" "$c" "$title"
    fi
    i=$((i+1))
  done

  hr
  printf "${DIM}操作：↑/↓ 或 j/k 选择 · Enter 执行 · q 退出${NC}\n"
}

get_key() {
  # read one key from /dev/tty
  local k
  IFS= read -rsn1 k < /dev/tty || return 1

  # arrow keys are escape sequences: \x1b [ A/B
  if [[ "$k" == $'\x1b' ]]; then
    local k2 k3
    IFS= read -rsn1 k2 < /dev/tty || true
    IFS= read -rsn1 k3 < /dev/tty || true
    printf "%s" "$k$k2$k3"
    return 0
  fi

  printf "%s" "$k"
}

do_action() {
  local idx="$1"
  IFS='|' read -r title _color action <<<"${MENU_ITEMS[$idx]}"

  case "$action" in
    remote:*)
      need_root_hint
      run_remote "$title" "${action#remote:}"
      ;;
    msg:*)
      hr
      printf "${YEL}%s${NC}\n" "${action#msg:}"
      pause
      ;;
    exit)
      hr
      printf "${GRN}✅ 已退出。${NC}\n"
      exit 0
      ;;
    *)
      die "未知 action：$action"
      ;;
  esac
}

main() {
  [[ -t 0 || -t 1 ]] || die "当前不是交互终端，无法显示面板。请直接在 SSH 终端运行。"

  tput civis 2>/dev/null || true
  stty -echo 2>/dev/null || true

  local selected=0
  local max=$(( ${#MENU_ITEMS[@]} - 1 ))

  while true; do
    render_menu "$selected"

    local key
    key="$(get_key)" || true

    case "$key" in
      $'\x1b[A'|k) # up
        selected=$((selected-1))
        (( selected < 0 )) && selected=$max
        ;;
      $'\x1b[B'|j) # down
        selected=$((selected+1))
        (( selected > max )) && selected=0
        ;;
      "") # Enter
        # restore echo for running scripts
        stty echo 2>/dev/null || true
        tput cnorm 2>/dev/null || true
        do_action "$selected"
        # hide cursor again
        tput civis 2>/dev/null || true
        stty -echo 2>/dev/null || true
        ;;
      q|Q)
        do_action "$max" # exit item
        ;;
      [1-9])
        # quick jump by number
        local n=$((key-1))
        if (( n >= 0 && n <= max )); then
          selected="$n"
        fi
        ;;
      *)
        : ;;
    esac
  done
}

main
