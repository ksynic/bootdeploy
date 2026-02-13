run_remote() {
  local label="$1"
  local path="$2"

  hr
  printf "${GRN}▶ %s${NC}\n" "$label"
  hr

  curl -fsSL "https://raw.githubusercontent.com/ksynic/bootdeploy/main/$path" | bash

  hr
  printf "${GRN}✅ 完成：%s${NC}\n" "$label"
  pause
}
