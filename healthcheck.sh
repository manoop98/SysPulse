#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

separator="================================================================================"

print_header() {
    echo -e "\n${CYAN}${BOLD}$1${RESET}"
    echo "$separator"
}

# ------------------------ CPU Usage ------------------------

top_output=$(top -bn1)

cpu_idle=$(echo "$top_output" | grep "Cpu(s)" | sed 's/.*, *\([0-9.]*\)%* id.*/\1/')
cpu_usage=$(awk -v idle="$cpu_idle" 'BEGIN { printf("%.1f", 100 - idle) }')

print_header "🖥️  CPU Usage"
echo -e "Usage         : ${GREEN}${cpu_usage}%${RESET}"

# ------------------------ Memory Usage ------------------------

read total_memory available_memory <<< $(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {print t, a}' /proc/meminfo)
used_memory=$((total_memory - available_memory))

used_memory_percent=$(awk -v u=$used_memory -v t=$total_memory 'BEGIN { printf("%.1f", (u / t) * 100) }')
free_memory_percent=$(awk -v a=$available_memory -v t=$total_memory 'BEGIN { printf("%.1f", (a / t) * 100) }')

# Convert from kB to MB 
total_memory_mb=$(awk -v t=$total_memory 'BEGIN { printf("%.1f", t/1024) }')
used_memory_mb=$(awk -v u=$used_memory 'BEGIN { printf("%.1f", u/1024) }')
available_memory_mb=$(awk -v a=$available_memory 'BEGIN { printf("%.1f", a/1024) }')

print_header "🧠 Memory Usage"
printf "Total Memory    : ${YELLOW}%-10s MB${RESET}\n" "$total_memory_mb"
printf "Used Memory     : ${YELLOW}%-10s MB${RESET} (%s%%)\n" "$used_memory_mb" "$used_memory_percent"
printf "Free/Available  : ${YELLOW}%-10s MB${RESET} (%s%%)\n" "$available_memory_mb" "$free_memory_percent"

# ------------------------ Disk Usage ------------------------

df_output=$(df -h /)
size_disk=$(echo "$df_output" | awk 'NR==2 {printf $2}')
read used_disk available_disk <<< $(echo "$df_output" | awk 'NR==2 {print $3, $4}')

df_output_raw=$(df /)
read size_disk_kb used_disk_kb available_disk_kb <<< $(echo "$df_output_raw" | awk 'NR==2 {print $2, $3, $4}')

used_disk_percent=$(echo "scale=2; $used_disk_kb *100/$size_disk_kb" | bc)
available_disk_percent=$(echo "scale=2; $available_disk_kb *100/$size_disk_kb" | bc)

print_header "💾 Disk Usage"
printf "Disk Size       : ${YELLOW}%-10s${RESET}\n" "$size_disk"
printf "Used Space      : ${YELLOW}%-10s${RESET} (%s%%)\n" "$used_disk" "$used_disk_percent"
printf "Available Space : ${YELLOW}%-10s${RESET} (%s%%)\n" "$available_disk" "$available_disk_percent"

# ------------------------ Top Processes ------------------------

print_header "🔥 Top 5 Processes by CPU"
ps aux --sort=-%cpu | awk 'NR==1 || NR<=6 { printf "%-10s %-6s %-5s %-5s %s\n", $1, $2, $3, $4, $11 }'

print_header "🧠 Top 5 Processes by Memory"
ps aux --sort=-%mem | awk 'NR==1 || NR<=6 { printf "%-10s %-6s %-5s %-5s %s\n", $1, $2, $3, $4, $11 }'

# ------------------------ System Diagnostics ------------------------

print_header "🧮 df -Th (Filesystem Disk Type & Usage)"
df -Th

print_header "🔌 netstat -ntlp (Listening TCP Ports)"
netstat -ntlp 2>/dev/null || echo "netstat not available"

print_header "📊 free -h (Memory Usage Overview)"
free -h

print_header "👥 w (Logged-in Users & Load)"
w

print_header "🗂️  /etc/fstab (Filesystem Mount Info)"
cat /etc/fstab

print_header "📦 OS Release Info"
cat /etc/os-release

print_header "📁 lsblk (Block Device Info)"
lsblk

print_header "🛠️  Running Services"
systemctl list-units --type=service --state=running
