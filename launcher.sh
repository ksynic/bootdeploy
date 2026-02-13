run_remote() {
  local label="$1"
  local rel="$2"
  local url="https://raw.githubusercontent.com/ksynic/bootdeploy/main/$rel"
  local tmp="/tmp/bootdeploy_$(basename "$rel")"

  hr
  printf "${GRN}▶ %s${NC}\n" "$label"
  printf "拉取并运行：%s\n" "$url"
  hr

  curl -fsSL -o "$tmp" "$url" || {
    printf "${RED}❌ 下载失败：%s${NC}\n" "$url"
    pause
    return 1
  }

  chmod +x "$tmp" || true
  bash "$tmp"
  rc=$?

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
