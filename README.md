# PG Recon

Automated recon helper for Proving Grounds/OSCP targets. Run `pg_recon.sh` from `~/pg_recon` to create a per-exercise workspace, perform Nmap scans, and do web recon (gobuster, curl snapshots, nikto) on discovered HTTP(S) services.

## Quick Start
```bash
cd ~/pg_recon
./pg_recon.sh "<ExerciseName>" <IP>              # default: nmap + web (no full UDP)
./pg_recon.sh "<ExerciseName>" <IP> nmap         # all nmap except full UDP
./pg_recon.sh "<ExerciseName>" <IP> web          # web dir bust + curl + nikto
./pg_recon.sh "<ExerciseName>" <IP> nmap-udp-all # full UDP (slow)
```

Outputs land in `/home/kali/ProvingGround/<ExerciseName>/`:
- `nmap/` for scan results (full TCP/UDP, scripts)
- `gobuster/` for dir busting output + commands
- `web/` for curl/nikto per-port captures

## Modes (high level)
- `all` (default): nmap (no full UDP) + all web scans
- `nmap`: all nmap scans except full UDP
- `nmap-tcp-all`, `nmap-tcp-basic`, `nmap-udp-medium`, `nmap-udp-all`, `nmap-scripts` (aliases without `nmap-` also accepted)
- Web: `web` (dir-basic/advanced/files/lowercase + curl + nikto), or individual `web-dir-basic`, `web-dir-advanced`, `web-dir-files`, `web-dir-lowercase`, `web-curl`, `web-nikto`

## Requirements
- Nmap, gobuster, curl, nikto installed and in `$PATH`.
- Run `nmap-tcp-all` before web modes so HTTP ports are detected.
- Scripts support sudo; ownership is reset to the invoking user when run as root.

## Git Basics
```bash
git add pg_recon.sh pg_recon.lib README.md
git commit -m "Describe your change"
git push
```
