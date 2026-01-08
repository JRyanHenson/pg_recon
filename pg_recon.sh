#!/usr/bin/env bash
# /home/kali/pg_recon/pg_recon.sh
# Driver script: sets up workspace + runs selected recon modes.
#
# Mode rules (per your request):
# - all  : run EVERYTHING except udp-all (full UDP)
# - nmap : run ALL nmap steps except udp-all (full UDP)
# - web  : run ALL web scans (dir busting + curl snapshots + nikto)

set -euo pipefail

# Ensure directories are owned by the invoking (non-root) user even when running with sudo
owner_user() { echo "${SUDO_USER:-$(id -un)}"; }
owner_group() {
  local u
  u="$(owner_user)"
  id -gn "$u" 2>/dev/null || echo "$u"
}
ensure_dir_owned() {
  local dir="$1"
  local u g
  u="$(owner_user)"
  g="$(owner_group)"
  if [[ $(id -u) -eq 0 ]]; then
    install -d -m 755 -o "$u" -g "$g" "$dir"
  else
    install -d -m 755 "$dir"
  fi
}

usage() {
  cat <<'EOF'
Usage:
  ./pg_recon.sh <ExerciseName> <IP> [mode]

Modes:
  all            (default) nmap + all web scans (dir + curl + nikto) EXCEPT udp-all/full UDP
  nmap           all nmap scans + scripts (EXCEPT udp-all/full UDP)
  nmap-tcp       basic TCP + all TCP + scripts
  nmap-udp       medium UDP + scripts
  nmap-tcp-basic basic TCP only
  nmap-tcp-all   all TCP only
  nmap-udp-basic basic UDP only (top 100)
  nmap-udp-medium medium UDP only (top 1000)
  nmap-udp-all   full UDP only (slow; all 65535 ports)
  nmap-scripts   run nmap scripts on discovered open ports (needs prior scans)
  web-dir-basic      gobuster basic (needs full TCP scan)
  web-dir-advanced   gobuster advanced (needs full TCP scan)
  web-dir-files      gobuster common files scan (needs full TCP scan)
  web-dir-lowercase  gobuster lowercase medium wordlist (needs full TCP scan)
  web-curl       curl each HTTP(S) port; save to per-port directory (needs full TCP scan)
  web-nikto      nikto -h on each HTTP(S) port; save to per-port directory (needs full TCP scan)
  web            run ALL web scans: dir (basic/adv/files/lowercase) + curl + nikto (needs full TCP scan)

Examples:
  ./pg_recon.sh Shenzi 192.168.113.10
  ./pg_recon.sh Shenzi 192.168.113.10 nmap
  ./pg_recon.sh Shenzi 192.168.113.10 web
  ./pg_recon.sh Shenzi 192.168.113.10 nmap-udp-all
EOF
  exit 1
}

EX_NAME="${1:-}"
IP="${2:-}"
MODE="${3:-all}"
[[ -z "$EX_NAME" || -z "$IP" ]] && usage

SAFE_NAME="${EX_NAME// /_}"

# Fixed base directory + fixed lib location
BASE_DIR="/home/kali/ProvingGround/$SAFE_NAME"
NMAP_DIR="$BASE_DIR/nmap"
GOBUSTER_DIR="$BASE_DIR/gobuster"
EXPLOITS_DIR="$BASE_DIR/exploits"
WEB_DIR="$BASE_DIR/web"

ensure_dir_owned "$NMAP_DIR"
ensure_dir_owned "$GOBUSTER_DIR"
ensure_dir_owned "$EXPLOITS_DIR"
ensure_dir_owned "$WEB_DIR"

# Gobuster command logging directory
GOBUSTER_CMD_DIR="$GOBUSTER_DIR/commands"
ensure_dir_owned "$GOBUSTER_CMD_DIR"

# Export environment for the library
export IP SAFE_NAME BASE_DIR NMAP_DIR GOBUSTER_DIR EXPLOITS_DIR GOBUSTER_CMD_DIR WEB_DIR

# Output files
export TCP_BASIC_OUT="$NMAP_DIR/basic_tcp.nmap"
export TCP_FULL_OUT="$NMAP_DIR/full_tcp.nmap"
export TCP_FULL_GNMAP="$NMAP_DIR/full_tcp.gnmap"

export UDP_BASIC_OUT="$NMAP_DIR/basic_udp.nmap"
export UDP_BASIC_GNMAP="$NMAP_DIR/basic_udp.gnmap"

export UDP_MEDIUM_OUT="$NMAP_DIR/medium_udp.nmap"
export UDP_MEDIUM_GNMAP="$NMAP_DIR/medium_udp.gnmap"

export UDP_FULL_OUT="$NMAP_DIR/full_udp.nmap"
export UDP_FULL_GNMAP="$NMAP_DIR/full_udp.gnmap"

export TCP_SCRIPTS_OUT="$NMAP_DIR/scripts_tcp.nmap"
export UDP_SCRIPTS_OUT="$NMAP_DIR/scripts_udp.nmap"

# Fixed library path
LIB="/home/kali/pg_recon/pg_recon.lib"
[[ -f "$LIB" ]] || { echo "[!] Missing library: $LIB" >&2; exit 1; }
# shellcheck source=/dev/null
source "$LIB"

echo "[+] Target: $SAFE_NAME ($IP)"
echo "[+] Workspace: $BASE_DIR"
echo "[+] Mode: $MODE"
echo

run_nmap_all_except_udp_all() {
  # All nmap scans except full UDP:
  # - basic TCP
  # - all TCP
  # - medium UDP
  # - scripts on open ports
  nmap_basic_tcp
  nmap_all_tcp
  nmap_medium_udp
  nmap_scripts_on_open_ports
}

run_web_all() {
  # All web scans (dir busting + curl + nikto)
  web_all
}

case "$MODE" in
  all)
    # Everything except udp-all (full UDP)
    run_nmap_all_except_udp_all
    run_web_all
    ;;
  nmap)
    # All nmap except udp-all
    run_nmap_all_except_udp_all
    ;;
  web)
    # All web scans
    run_web_all
    ;;
  dir)
    # Backward compatibility alias for web
    echo "[*] Mode 'dir' has been renamed to 'web'; running web scans."
    run_web_all
    ;;
  nmap-tcp|tcp)
    nmap_basic_tcp
    nmap_all_tcp
    nmap_scripts_on_open_ports
    ;;
  nmap-udp|udp)
    nmap_medium_udp
    nmap_scripts_on_open_ports
    ;;
  nmap-tcp-basic|tcp-basic)    nmap_basic_tcp ;;
  nmap-tcp-all|tcp-all)        nmap_all_tcp ;;
  nmap-udp-basic|udp-basic)    nmap_basic_udp ;;
  nmap-udp-medium|udp-medium)  nmap_medium_udp ;;
  nmap-udp-all|udp-all)        nmap_all_udp ;;
  nmap-scripts|scripts)    nmap_scripts_on_open_ports ;;
  web-dir-basic|dir-basic)          dir_search_basic ;;
  web-dir-advanced|dir-advanced)    dir_search_advanced ;;
  web-dir-files|dir-files)          dir_search_files ;;
  web-dir-lowercase|dir-lowercase)  dir_search_lowercase ;;
  web-curl)                          web_curl_snapshots ;;
  web-nikto)                         web_nikto_scan ;;
  -h|--help|help) usage ;;
  *)
  echo "[!] Unknown mode: $MODE" >&2
  usage
  ;;
esac

# If we were run with sudo/root, reset ownership to the invoking user
if [[ $(id -u) -eq 0 ]]; then
  chown -R "$(owner_user)":"$(owner_group)" "$BASE_DIR"
fi

echo
echo "[+] Done."
echo "[+] Nmap output: $NMAP_DIR"
echo "[+] Gobuster output: $GOBUSTER_DIR"
echo "[+] Gobuster commands: $GOBUSTER_CMD_DIR"
