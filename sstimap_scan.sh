#for_settings_up 10101010

# Advanced SSTImap Scanner - Universal Linux/Termux Version
# Features: Multiple detection methods, custom payloads, batch scanning, and more

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Detect environment
IS_TERMUX=false
if [ -d "/data/data/com.termux" ] || command -v termux-info >/dev/null 2>&1; then
    IS_TERMUX=true
fi

# Set paths based on environment
if [ "$IS_TERMUX" = true ]; then
    BASE_DIR="/storage/emulated/0/x"
    RESULT_DIR="${BASE_DIR}/result"
    SSTIMAP_DIR="$HOME/sstimap"
else
    BASE_DIR="$HOME/recon"
    RESULT_DIR="${BASE_DIR}/sstimap_results"
    SSTIMAP_DIR="$HOME/sstimap"
fi

# Create directories
mkdir -p "$RESULT_DIR"
mkdir -p "$SSTIMAP_DIR"

# Banner
clear
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    SSTIMAP ADVANCED SCANNER                    ║"
echo "║              SSTI Detection & Exploitation Tool               ║"
if [ "$IS_TERMUX" = true ]; then
    echo "║                       Termux Edition                        ║"
else
    echo "║                        Linux Edition                        ║"
fi
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check and install SSTImap if not present
check_sstimap() {
    if [ ! -f "$SSTIMAP_DIR/sstimap.py" ]; then
        echo -e "${YELLOW}[!] SSTImap not found. Installing...${NC}"
        
        # Install dependencies
        echo -e "${CYAN}[*] Installing dependencies...${NC}"
        if [ "$IS_TERMUX" = true ]; then
            pkg update -y
            pkg install -y python git
        else
            if command -v apt >/dev/null 2>&1; then
                sudo apt update -y
                sudo apt install -y python3 python3-pip git
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y python3 python3-pip git
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y python3 python3-pip git
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -S --noconfirm python python-pip git
            fi
        fi
        
        # Clone SSTImap
        cd "$HOME"
        git clone https://github.com/vladko312/SSTImap.git "$SSTIMAP_DIR"
        cd "$SSTIMAP_DIR"
        
        # Install Python requirements
        if [ -f "requirements.txt" ]; then
            if command -v pip3 >/dev/null 2>&1; then
                pip3 install -r requirements.txt
            else
                pip install -r requirements.txt
            fi
        fi
        
        chmod +x sstimap.py
        echo -e "${GREEN}[+] SSTImap installed successfully!${NC}"
        sleep 2
        clear
    fi
}

# Function to get target URL
get_target() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}[?] Enter target URL: ${NC}"
    echo -e "${YELLOW}Examples:${NC}"
    echo "  • https://example.com/page?param=test"
    echo "  • https://example.com/page/{{7*7}}"
    echo "  • https://example.com/api/user?name={{config}}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    read -r url
    
    if [ -z "$url" ]; then
        echo -e "${RED}[!] No URL provided!${NC}"
        return 1
    fi
    
    return 0
}

# Function to select scan mode
select_scan_mode() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Select Scan Mode:${NC}"
    echo -e "${GREEN}[1]${NC} 🚀 Fast Scan (Default settings)"
    echo -e "${GREEN}[2]${NC} 🔍 Deep Scan (Level 3, Threads 5)"
    echo -e "${GREEN}[3]${NC} 🎯 Aggressive Scan (Level 5, Threads 10)"
    echo -e "${GREEN}[4]${NC} 💀 Nuclear Scan (Level 8, Threads 20 - May crash apps)"
    echo -e "${GREEN}[5]${NC} 🕸️  OS Command Execution Attempt"
    echo -e "${GREEN}[6]${NC} 📁 File Read Attempt"
    echo -e "${GREEN}[7]${NC} 🔑 Custom Parameters"
    echo -e "${GREEN}[8]${NC} 📝 Batch Scan from File"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}[?] Choose option (1-8): ${NC}"
    read -r mode_choice
    
    case $mode_choice in
        1)
            SCAN_MODE="fast"
            SCAN_OPTS="-c 2 --level 1"
            ;;
        2)
            SCAN_MODE="deep"
            SCAN_OPTS="-c 5 --level 3"
            ;;
        3)
            SCAN_MODE="aggressive"
            SCAN_OPTS="-c 10 --level 5"
            ;;
        4)
            SCAN_MODE="nuclear"
            SCAN_OPTS="-c 20 --level 8"
            ;;
        5)
            SCAN_MODE="os_command"
            SCAN_OPTS="--os-cmd"
            echo -e "${YELLOW}[?] Enter OS command to execute (e.g., id, whoami): ${NC}"
            read -r os_cmd
            SCAN_OPTS="$SCAN_OPTS \"$os_cmd\""
            ;;
        6)
            SCAN_MODE="file_read"
            SCAN_OPTS="--read-file"
            echo -e "${YELLOW}[?] Enter file path to read (e.g., /etc/passwd): ${NC}"
            read -r file_path
            SCAN_OPTS="$SCAN_OPTS \"$file_path\""
            ;;
        7)
            SCAN_MODE="custom"
            echo -e "${YELLOW}[?] Enter custom parameters (e.g., -c 10 --level 4 --tamper): ${NC}"
            read -r custom_opts
            SCAN_OPTS="$custom_opts"
            ;;
        8)
            SCAN_MODE="batch"
            echo -e "${YELLOW}[?] Enter path to URL list file: ${NC}"
            read -r batch_file
            if [ ! -f "$batch_file" ]; then
                echo -e "${RED}[!] File not found: $batch_file${NC}"
                return 1
            fi
            BATCH_MODE=true
            ;;
        *)
            echo -e "${RED}[!] Invalid choice! Using fast scan mode.${NC}"
            SCAN_MODE="fast"
            SCAN_OPTS="-c 2 --level 1"
            ;;
    esac
}

# Function to select output format
select_output_format() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Select Output Format:${NC}"
    echo -e "${GREEN}[1]${NC} 📄 Text (Human readable)"
    echo -e "${GREEN}[2]${NC} 📊 JSON (Machine readable)"
    echo -e "${GREEN}[3]${NC} 📑 Both (Text + JSON)"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}[?] Choose option (1-3): ${NC}"
    read -r format_choice
    
    case $format_choice in
        2)
            OUTPUT_FORMAT="json"
            ;;
        3)
            OUTPUT_FORMAT="both"
            ;;
        *)
            OUTPUT_FORMAT="text"
            ;;
    esac
}

# Function to set additional options
set_additional_options() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Additional Options (y/n):${NC}"
    
    echo -e "${YELLOW}[?] Enable verbose output? (y/n): ${NC}"
    read -r verbose_choice
    if [[ $verbose_choice == "y" || $verbose_choice == "Y" ]]; then
        VERBOSE="-v"
    else
        VERBOSE=""
    fi
    
    echo -e "${YELLOW}[?] Enable random User-Agent? (y/n): ${NC}"
    read -r ua_choice
    if [[ $ua_choice == "y" || $ua_choice == "Y" ]]; then
        RANDOM_UA="--random-agent"
    else
        RANDOM_UA=""
    fi
    
    echo -e "${YELLOW}[?] Use proxy? (y/n): ${NC}"
    read -r proxy_choice
    if [[ $proxy_choice == "y" || $proxy_choice == "Y" ]]; then
        echo -e "${YELLOW}[?] Enter proxy URL (e.g., http://127.0.0.1:8080): ${NC}"
        read -r proxy_url
        PROXY="--proxy $proxy_url"
    else
        PROXY=""
    fi
    
    echo -e "${YELLOW}[?] Enable delay between requests? (y/n): ${NC}"
    read -r delay_choice
    if [[ $delay_choice == "y" || $delay_choice == "Y" ]]; then
        echo -e "${YELLOW}[?] Enter delay in seconds (e.g., 0.5, 1, 2): ${NC}"
        read -r delay_time
        DELAY="--delay $delay_time"
    else
        DELAY=""
    fi
}

# Function to scan single URL
scan_url() {
    local target_url="$1"
    local log_base="$2"
    
    echo -e "\n${BLUE}[*] Scanning: $target_url${NC}"
    
    # Sanitize URL for filename
    local safe_url=$(echo "$target_url" | sed 's|https\?://||' | sed 's|/|_|g' | sed 's/?/_/g' | cut -c1-100)
    local text_log="${log_base}_${safe_url}_${timestamp}.txt"
    local json_log="${log_base}_${safe_url}_${timestamp}.json"
    
    cd "$SSTIMAP_DIR"
    
    # Run scan based on output format
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        echo -e "${CYAN}[*] Running SSTImap (JSON output)...${NC}"
        ./sstimap.py -u "$target_url" $SCAN_OPTS $VERBOSE $RANDOM_UA $PROXY $DELAY -o "$json_log" 2>&1 | tee "$text_log"
    elif [ "$OUTPUT_FORMAT" = "both" ]; then
        echo -e "${CYAN}[*] Running SSTImap (Text + JSON output)...${NC}"
        ./sstimap.py -u "$target_url" $SCAN_OPTS $VERBOSE $RANDOM_UA $PROXY $DELAY -o "$json_log" 2>&1 | tee "$text_log"
    else
        echo -e "${CYAN}[*] Running SSTImap (Text output)...${NC}"
        ./sstimap.py -u "$target_url" $SCAN_OPTS $VERBOSE $RANDOM_UA $PROXY $DELAY 2>&1 | tee "$text_log"
    fi
    
    cd "$HOME"
    
    # Check if vulnerabilities found
    if grep -qi "vulnerable\|success\|found\|exploitable" "$text_log" 2>/dev/null; then
        echo -e "${RED}[!] POTENTIAL SSTI VULNERABILITY DETECTED!${NC}"
        echo -e "${RED}[!] Check log: $text_log${NC}"
        return 0
    else
        echo -e "${GREEN}[+] No SSTI vulnerabilities detected${NC}"
        return 1
    fi
}

# Function to display results summary
show_summary() {
    local log_file="$1"
    
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    SCAN SUMMARY                               ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    
    if [ -f "$log_file" ]; then
        echo -e "${CYAN}[+] Scan completed at: $(date)${NC}"
        echo -e "${CYAN}[+] Log file: $log_file${NC}"
        echo -e "${CYAN}[+] File size: $(du -h "$log_file" | cut -f1)${NC}"
        
        # Extract key information
        echo -e "\n${YELLOW}[+] Key Findings:${NC}"
        
        # Check for vulnerabilities
        if grep -qi "vulnerable" "$log_file"; then
            echo -e "  ${RED}⚠️  SSTI Vulnerabilities Detected!${NC}"
            grep -i "vulnerable" "$log_file" | head -5 | while read -r line; do
                echo -e "    • $line"
            done
        else
            echo -e "  ${GREEN}✓ No SSTI vulnerabilities detected${NC}"
        fi
        
        # Check for detected engines
        if grep -qi "engine" "$log_file"; then
            echo -e "\n${YELLOW}[+] Detected Template Engines:${NC}"
            grep -i "engine" "$log_file" | grep -v "Detecting" | head -5 | while read -r line; do
                echo -e "    • $line"
            done
        fi
        
        # Count total requests
        if grep -qi "request" "$log_file"; then
            local req_count=$(grep -ci "request" "$log_file")
            echo -e "\n${YELLOW}[+] Total requests made: $req_count${NC}"
        fi
    else
        echo -e "${RED}[!] Log file not found!${NC}"
    fi
    
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
}

# Function for batch scanning
batch_scan() {
    local batch_file="$1"
    local batch_log="${RESULT_DIR}/batch_scan_${timestamp}.txt"
    
    echo -e "${CYAN}[*] Starting batch scan from: $batch_file${NC}"
    echo -e "${CYAN}[*] Total URLs: $(wc -l < "$batch_file")${NC}"
    echo -e "${GREEN}[+] Batch log: $batch_log${NC}\n"
    
    local total=$(wc -l < "$batch_file")
    local current=0
    local vulnerable=0
    
    while IFS= read -r target_url; do
        [ -z "$target_url" ] && continue
        current=$((current + 1))
        
        echo -e "${BLUE}[$current/$total] Processing: $target_url${NC}"
        
        if scan_url "$target_url" "$RESULT_DIR/single_scan"; then
            vulnerable=$((vulnerable + 1))
            echo "$target_url - VULNERABLE" >> "$batch_log"
        else
            echo "$target_url - Not vulnerable" >> "$batch_log"
        fi
        
        echo "----------------------------------------"
    done < "$batch_file"
    
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Batch Scan Complete!${NC}"
    echo -e "Total URLs scanned: $total"
    echo -e "${RED}Vulnerable URLs found: $vulnerable${NC}"
    echo -e "Results saved to: $batch_log"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
}

# Function to save configuration
save_config() {
    local config_file="$RESULT_DIR/sstimap_config_${timestamp}.txt"
    
    cat > "$config_file" << EOF
# SSTImap Scan Configuration
# Generated: $(date)

[Scan Settings]
URL: $url
Scan Mode: $SCAN_MODE
Scan Options: $SCAN_OPTS
Output Format: $OUTPUT_FORMAT
Verbose: $VERBOSE
Random UA: $RANDOM_UA
Proxy: $PROXY
Delay: $DELAY

[Environment]
OS: $(uname -a)
Termux: $IS_TERMUX
Python: $(python3 --version 2>/dev/null || python --version)

[Timestamps]
Start Time: $start_time
End Time: $(date)
EOF
    
    echo -e "${GREEN}[+] Configuration saved to: $config_file${NC}"
}

# Main execution
main() {
    # Check SSTImap
    check_sstimap
    
    # Get target
    if ! get_target; then
        exit 1
    fi
    
    # Select scan mode
    select_scan_mode
    if [ "$SCAN_MODE" = "batch" ] && [ "$BATCH_MODE" = true ]; then
        batch_scan "$batch_file"
        exit 0
    fi
    
    # Select output format
    select_output_format
    
    # Set additional options
    set_additional_options
    
    # Timestamp and logging
    timestamp=$(date +"%Y%m%d_%H%M%S")
    start_time=$(date)
    log_base="${RESULT_DIR}/sstimap_scan"
    
    echo -e "\n${GREEN}[*] Starting SSTImap scan...${NC}"
    echo -e "[*] Target: $url"
    echo -e "[*] Mode: $SCAN_MODE"
    echo -e "[*] Started at: $start_time"
    echo -e "[*] Log directory: $RESULT_DIR"
    
    # Confirm before scanning
    echo -e "\n${YELLOW}[?] Start scan? (y/n): ${NC}"
    read -r confirm
    if [[ ! $confirm == "y" && ! $confirm == "Y" ]]; then
        echo -e "${RED}[!] Scan cancelled${NC}"
        exit 0
    fi
    
    # Run scan
    scan_url "$url" "$log_base"
    
    # Save configuration
    save_config
    
    # Show summary
    latest_log=$(ls -t "$RESULT_DIR"/*.txt 2>/dev/null | head -1)
    if [ -n "$latest_log" ]; then
        show_summary "$latest_log"
    fi
    
    echo -e "\n${GREEN}[+] Scan completed!${NC}"
    echo -e "[+] Results saved to: $RESULT_DIR"
    
    # Option to open results directory
    echo -e "\n${YELLOW}[?] Open results directory? (y/n): ${NC}"
    read -r open_dir
    if [[ $open_dir == "y" || $open_dir == "Y" ]]; then
        if [ "$IS_TERMUX" = true ]; then
            termux-open "$RESULT_DIR" 2>/dev/null || echo -e "${YELLOW}Results in: $RESULT_DIR${NC}"
        else
            xdg-open "$RESULT_DIR" 2>/dev/null || open "$RESULT_DIR" 2>/dev/null || echo -e "${YELLOW}Results in: $RESULT_DIR${NC}"
        fi
    fi
}

# Run main function with error handling
trap 'echo -e "\n${RED}[!] Script interrupted${NC}"; exit 1' INT TERM
main "$@"