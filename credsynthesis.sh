#!/bin/bash

# ============================================================
#  CRED-SYNTHESIS v3.0 (Final Release)
#  Targeted Credential Synthesis Engine
# ============================================================

# --- CONFIGURATION ---
TOOL_NAME="CRED-SYNTHESIS"
CACHE_DIR="./credsynth_cache"
CUPP_DIR="$CACHE_DIR/cupp"
UA_DIR="$CACHE_DIR/username-anarchy"
CUPP_BIN="python3 $CUPP_DIR/cupp.py"
UA_BIN="$UA_DIR/username-anarchy"

# --- COLORS ---
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- LOGO ---
print_logo() {
    clear
    echo -e "${CYAN}"
    echo "   ██████╗██████╗ ███████╗██████╗ "
    echo "  ██╔════╝██╔══██╗██╔════╝██╔══██╗"
    echo "  ██║     ██████╔╝█████╗  ██║  ██║"
    echo "  ██║     ██╔══██╗██╔══╝  ██║  ██║"
    echo "  ╚██████╗██║  ██║███████╗██████╔╝"
    echo "   ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝ "
    echo -e "  ${BOLD}S Y N T H E S I S${NC} | ${YELLOW}Advanced Credential Generator${NC}"
    echo -e "${CYAN}==========================================${NC}"
    echo ""
}

# --- HELPERS ---
status() { echo -e "${BLUE}[*] $1...${NC}"; }
success() { echo -e "${GREEN}[+] $1${NC}"; }
error() { echo -e "${RED}[!] $1${NC}"; }

# --- 1. DEPENDENCY CHECK ---
check_deps() {
    status "Initializing Synthesis Environment"
    if ! command -v git &>/dev/null; then error "Git is missing."; exit 1; fi
    if ! command -v python3 &>/dev/null; then error "Python3 is missing."; exit 1; fi
    mkdir -p "$CACHE_DIR"

    if [ ! -d "$CUPP_DIR" ]; then
        status "Downloading CUPP..."
        git clone --quiet https://github.com/Mebus/cupp.git "$CUPP_DIR"
    fi
    if [ ! -d "$UA_DIR" ]; then
        status "Downloading Username Anarchy..."
        git clone --quiet https://github.com/urbanadventurer/username-anarchy.git "$UA_DIR"
    fi
}

# --- 2. UNIFIED INPUT ---
collect_data() {
    echo -e "\n${CYAN}--- [ PHASE 1: TARGET PROFILING ] ---${NC}"
    echo -e "${YELLOW}Tip: Press Enter to skip unknown fields.${NC}\n"

    read -p "First Name           : " FIRST
    if [ -z "$FIRST" ]; then error "First Name is mandatory!"; exit 1; fi
    read -p "Surname              : " LAST
    read -p "Nickname             : " NICK
    read -p "Birthdate (DDMMYYYY) : " DOB

    echo -e "\n${BOLD}--- Relations ---${NC}"
    read -p "Partner's Name       : " P_NAME
    read -p "Partner's Nickname   : " P_NICK
    read -p "Partner's DOB        : " P_DOB
    
    echo -e ""
    read -p "Child's Name         : " C_NAME
    read -p "Child's Nickname     : " C_NICK
    read -p "Child's DOB          : " C_DOB

    echo -e "\n${BOLD}--- Context ---${NC}"
    read -p "Pet's Name           : " PET
    read -p "Company Name         : " COMPANY
    echo -e "Extra keywords (comma separated, e.g. admin,football,secret):"
    read -p "> " KW_INPUT

    # --- POLICY ---
    echo -e "\n${CYAN}--- [ PHASE 2: POLICY DEFINITION ] ---${NC}"
    echo -e "${PURPLE}Note: Leave Max Length empty for no limit.${NC}"
    
    read -p "Min Length (default: 6)         : " POL_MIN
    POL_MIN=${POL_MIN:-6}
    
    read -p "Max Length (empty = no limit)   : " POL_MAX
    # Если пусто, ставим 9999 (практически бесконечность)
    if [ -z "$POL_MAX" ]; then POL_MAX=9999; fi

    read -p "Require Digits [0-9]? (Y/n)     : " POL_DIGIT
    read -p "Require Uppercase [A-Z]? (Y/n)  : " POL_UPPER
    read -p "Require Lowercase [a-z]? (Y/n)  : " POL_LOWER
    
    echo -e "${BOLD}Special Characters Filter${NC} (!@#$%^&*)"
    read -p "Minimum count required (0, 1, 2...)? [Default: 1]: " POL_SPEC_COUNT
    POL_SPEC_COUNT=${POL_SPEC_COUNT:-1}
}

# --- 3. SYNTHESIS ENGINE ---
synthesize() {
    echo -e "\n${CYAN}--- [ PHASE 3: SYNTHESIS STARTED ] ---${NC}"

    # === A. USERNAMES ===
    status "Synthesizing Usernames..."
    OUT_USER="usernames_${FIRST}.txt"
    if [ -n "$LAST" ]; then
        "$UA_BIN" "$FIRST" "$LAST" > "$OUT_USER" 2>/dev/null
        if [ -n "$NICK" ]; then "$UA_BIN" "$NICK" >> "$OUT_USER" 2>/dev/null; fi
    else
        "$UA_BIN" "$FIRST" > "$OUT_USER" 2>/dev/null
    fi
    sort -u "$OUT_USER" -o "$OUT_USER"
    success "Username list compiled: $OUT_USER"


    # === B. PASSWORDS (RAW) ===
    status "Synthesizing Raw Password Candidates (CUPP)..."
    
    KW_OPT="n"
    KW_DATA=""
    if [ -n "$KW_INPUT" ]; then KW_OPT="y"; KW_DATA="$KW_INPUT"; fi

    (
        echo "$FIRST"; echo "$LAST"; echo "$NICK"; echo "$DOB"
        echo "$P_NAME"; echo "$P_NICK"; echo "$P_DOB"
        echo "$C_NAME"; echo "$C_NICK"; echo "$C_DOB"
        echo "$PET"; echo "$COMPANY"
        echo "$KW_OPT"
        if [ "$KW_OPT" == "y" ]; then echo "$KW_DATA"; fi
        echo "y"; echo "y"; echo "y" # Special, Numbers, Leet
    ) | $CUPP_BIN -i > /dev/null 2>&1

    RAW_FILE="${FIRST}.txt"
    if [ ! -f "$RAW_FILE" ]; then RAW_FILE=$(ls *.txt | grep -v "usernames_" | head -n 1); fi
}

# --- 4. FILTERING ENGINE ---
filter_results() {
    status "Engaging Policy Filters on Raw Data..."
    
    OUT_PASS="passwords_${FIRST}_secure.txt"
    TMP_FILTER="temp_synthesis.txt"

    if [ ! -f "$RAW_FILE" ]; then error "Generation failed."; exit 1; fi

    RAW_COUNT=$(wc -l < "$RAW_FILE")
    status "Raw candidates: $RAW_COUNT"

    # 1. Length Filter (Min & Max)
    awk "length(\$0) >= $POL_MIN && length(\$0) <= $POL_MAX" "$RAW_FILE" > "$TMP_FILTER"

    # 2. Digit Filter [0-9]
    if [[ ! "$POL_DIGIT" =~ ^[Nn]$ ]]; then
        grep -E '[0-9]' "$TMP_FILTER" > "${TMP_FILTER}.2" && mv "${TMP_FILTER}.2" "$TMP_FILTER"
    fi

    # 3. Uppercase Filter [A-Z]
    if [[ ! "$POL_UPPER" =~ ^[Nn]$ ]]; then
        grep -E '[A-Z]' "$TMP_FILTER" > "${TMP_FILTER}.2" && mv "${TMP_FILTER}.2" "$TMP_FILTER"
    fi

    # 4. Lowercase Filter [a-z]
    if [[ ! "$POL_LOWER" =~ ^[Nn]$ ]]; then
        grep -E '[a-z]' "$TMP_FILTER" > "${TMP_FILTER}.2" && mv "${TMP_FILTER}.2" "$TMP_FILTER"
    fi

    # 5. Special Character Count
    if [ "$POL_SPEC_COUNT" -gt 0 ]; then
        awk -v min="$POL_SPEC_COUNT" '{
            count = 0;
            n = split($0, chars, "")
            for (i=1; i<=n; i++) {
                if (chars[i] ~ /[!@#$%^&*]/) count++
            }
            if (count >= min) print $0
        }' "$TMP_FILTER" > "${TMP_FILTER}.2" && mv "${TMP_FILTER}.2" "$TMP_FILTER"
    fi

    sort -u "$TMP_FILTER" > "$OUT_PASS"
    rm "$RAW_FILE" "$TMP_FILTER" 2>/dev/null
    
    FINAL_COUNT=$(wc -l < "$OUT_PASS")
    
    echo -e "\n${CYAN}==========================================${NC}"
    echo -e "${BOLD}         SYNTHESIS COMPLETE               ${NC}"
    echo -e "${CYAN}==========================================${NC}"
    echo -e "Target Identity : ${BOLD}$FIRST $LAST${NC}"
    echo -e "1. Usernames    : $OUT_USER ($(wc -l < $OUT_USER))"
    echo -e "2. Passwords    : $OUT_PASS"
    echo -e "   Count        : ${BOLD}$FINAL_COUNT${NC} (Filtered from $RAW_COUNT)"
    echo -e "   Policy       : Len:$POL_MIN-$POL_MAX, SpecChars>=$POL_SPEC_COUNT"
    echo -e "${CYAN}==========================================${NC}"
}

# --- RUN ---
print_logo
check_deps
collect_data
synthesize
filter_results
