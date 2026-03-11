#!/bin/bash

set -euo pipefail

# Colors for output using $'...' syntax for proper escape handling
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
BLUE=$'\033[0;34m'
BOLD=$'\033[1m'
NC=$'\033[0m' # No Color

# Optional: Disable colors by setting NO_COLOR=1
if [ -n "${NO_COLOR:-}" ]; then
    RED=''
    GREEN=''
    YELLOW=''
    CYAN=''
    BLUE=''
    BOLD=''
    NC=''
fi

print_error() {
    echo -e "${RED}Error:${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

print_success() {
    echo -e "${GREEN}Success:${NC} $1"
}

show_help() {
    # Use global color variables
    local cmd
    cmd=$(basename "$0")

    cat << HELPEOF
${BOLD}Symbolicate IPS - Crash Log Symbolicator${NC}

${BOLD}Usage:${NC}
  ${GREEN}${cmd}${NC} [options] ${YELLOW}<path_to_ips>${NC} ${YELLOW}<path_to_dsym>${NC}

${BOLD}Description:${NC}
  Symbolicate .ips or .crash files using .dSYM files to convert
  memory addresses into readable function names and file locations.

${BOLD}Arguments:${NC}
  ${YELLOW}path_to_ips   ${NC}Path to the .ips or .crash crash file
  ${YELLOW}path_to_dsym  ${NC}Path to the .dSYM bundle

${BOLD}Options:${NC}
  ${GREEN}-h${NC}, ${GREEN}--help      ${NC}Show this help message
  ${GREEN}-o${NC}, ${GREEN}--output    ${NC}Specify custom output file
  ${GREEN}-v${NC}, ${GREEN}--verbose   ${NC}Show detailed progress information
  ${GREEN}-q${NC}, ${GREEN}--quiet     ${NC}Suppress non-essential output

${BOLD}Examples:${NC}
  ${BLUE}${cmd}${NC} ${YELLOW}~/Downloads/crash.ips${NC} ${YELLOW}~/Downloads/app.dSYM${NC}
  ${BLUE}${cmd}${NC} ${GREEN}-o${NC} custom_output.txt ${YELLOW}~/Downloads/crash.crash${NC} ${YELLOW}~/Downloads/app.dSYM${NC}
  ${BLUE}${cmd}${NC} ${GREEN}-q${NC} crash.ips app.dSYM ${NC}> output.txt
HELPEOF
}

# Parse arguments
OUTPUT_FILE=""
VERBOSE=0
QUIET=0
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -q|--quiet)
            QUIET=1
            shift
            ;;
        -*)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Restore positional arguments
set -- "${POSITIONAL_ARGS[@]}"

# Check argument count
if [ "$#" -ne 2 ]; then
    print_error "Invalid number of arguments"
    show_help
    exit 1
fi

IPS_FILE="$1"
DSYM_FILE="$2"

# ============================================
# INPUT VALIDATION
# ============================================

# Check if IPS_FILE is provided and exists
if [ -z "$IPS_FILE" ]; then
    print_error "No IPS file path provided"
    exit 1
fi

if [ ! -e "$IPS_FILE" ]; then
    print_error "IPS file not found: $IPS_FILE"
    exit 1
fi

if [ ! -f "$IPS_FILE" ]; then
    print_error "IPS path is not a file: $IPS_FILE"
    exit 1
fi

# Validate file extension (supports .ips, .ips.gz, .crash)
if [[ ! "$IPS_FILE" =~ \.ips$|\.ips\.gz$|\.crash$ ]]; then
    print_warning "File does not have .ips or .crash extension: $IPS_FILE"
fi

# Check if DSYM_FILE is provided and exists
if [ -z "$DSYM_FILE" ]; then
    print_error "No dSYM file path provided"
    exit 1
fi

if [ ! -e "$DSYM_FILE" ]; then
    print_error "dSYM file not found: $DSYM_FILE"
    exit 1
fi

# Validate dSYM path - can be a single .dSYM bundle or a directory containing .dSYM bundles
if [ -d "$DSYM_FILE" ]; then
    # Check if this directory IS a dSYM bundle (has Contents/Resources/DWARF)
    # vs a directory CONTAINING dSYM bundles
    if [ -d "$DSYM_FILE/Contents/Resources/DWARF" ]; then
        # It's a single dSYM bundle
        if [ $VERBOSE -eq 1 ]; then
            echo "Using single dSYM bundle: $DSYM_FILE"
        fi
    else
        # Directory containing multiple dSYM bundles - find the main app dSYM
        if [ $QUIET -eq 0 ]; then
            print_warning "Detected directory containing dSYM bundles, searching for main app dSYM..."
        fi

        # Find .app.dSYM (main app bundle) - exclude the parent directory itself
        app_dsym=""
        app_dsym=$(find "$DSYM_FILE" -maxdepth 1 -name "*.app.dSYM" -type d ! -path "$DSYM_FILE" | head -n 1)

        if [ -z "$app_dsym" ]; then
            # Try any .dSYM as fallback
            app_dsym=$(find "$DSYM_FILE" -maxdepth 1 -name "*.dSYM" -type d ! -path "$DSYM_FILE" | head -n 1)
        fi

        if [ -z "$app_dsym" ]; then
            print_error "No .dSYM bundle found in directory: $DSYM_FILE"
            exit 1
        fi

        if [ $QUIET -eq 0 ]; then
            echo "Using dSYM: $app_dsym"
        fi

        DSYM_FILE="$app_dsym"

        if [ ! -d "$DSYM_FILE/Contents/Resources/DWARF" ]; then
            print_error "Invalid dSYM bundle: missing Contents/Resources/DWARF directory"
            exit 1
        fi
    fi
else
    print_error "dSYM path is not a directory: $DSYM_FILE"
    exit 1
fi

# ============================================
# XCODE PATH DISCOVERY
# ============================================

find_xcode() {
    local xcode_path=""

    # Try xcode-select first (works for Xcode-beta and custom installations)
    if command -v xcode-select &> /dev/null; then
        xcode_path=$(xcode-select -p 2>/dev/null | sed 's/\/Contents\/Developer//')
        if [ -n "$xcode_path" ] && [ -d "$xcode_path" ]; then
            echo "$xcode_path"
            return 0
        fi
    fi

    # Try DEVELOPER_DIR environment variable
    if [ -n "${DEVELOPER_DIR:-}" ]; then
        xcode_path="${DEVELOPER_DIR%/Contents/Developer}"
        if [ -d "$xcode_path" ]; then
            echo "$xcode_path"
            return 0
        fi
    fi

    # Try common Xcode installation locations
    local xcode_locations=(
        "/Applications/Xcode.app"
        "/Applications/Xcode-beta.app"
        "/Applications/Xcode_16.app"
        "/Applications/Xcode-16.app"
    )

    for path in "${xcode_locations[@]}"; do
        if [ -d "$path" ]; then
            echo "$path"
            return 0
        fi
    done

    return 1
}

XCODE_PATH=$(find_xcode)

if [ -z "$XCODE_PATH" ]; then
    print_error "Could not find Xcode installation"
    echo "Please ensure Xcode is installed in /Applications/ or set DEVELOPER_DIR environment variable"
    exit 1
fi

if [ $QUIET -eq 0 ]; then
    echo "Found Xcode at: $XCODE_PATH"
fi

# Find symbolicatecrash tool
SYMBOLICATE_PATH=$(find "$XCODE_PATH/Contents/SharedFrameworks/DVTFoundation.framework" -name symbolicatecrash -type f 2>/dev/null | head -n 1)

if [ -z "$SYMBOLICATE_PATH" ]; then
    print_error "Could not find 'symbolicatecrash' tool in $XCODE_PATH"
    exit 1
fi

if [ $QUIET -eq 0 ]; then
    echo "Found symbolicatecrash at: $SYMBOLICATE_PATH"
fi

# ============================================
# SETUP OUTPUT FILE
# ============================================

if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="symbolicated_crash_$(date +%Y%m%d_%H%M%S).txt"
fi

# Check if output file already exists (only for non-timestamped)
if [ -f "$OUTPUT_FILE" ] && [[ ! "$OUTPUT_FILE" =~ symbolicated_crash_[0-9]{8}_[0-9]{6}\.txt$ ]]; then
    read -r -p "Output file '$OUTPUT_FILE' already exists. Overwrite? [y/N] " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# ============================================
# RUN SYMBOLICATION
# ============================================

export DEVELOPER_DIR="$XCODE_PATH/Contents/Developer"

if [ $QUIET -eq 0 ]; then
    echo "Symbolicating..."
    echo "  Input:  $IPS_FILE"
    echo "  dSYM:   $DSYM_FILE"
    echo "  Output: $OUTPUT_FILE"
elif [ $VERBOSE -eq 1 ]; then
    echo "Running symbolicatecrash with:"
    echo "  DEVELOPER_DIR=$DEVELOPER_DIR"
    echo "  Tool: $SYMBOLICATE_PATH"
    echo "  Args: -d \"$DSYM_FILE\" \"$IPS_FILE\""
fi

# Run symbolication, capture both stdout and stderr
# Use a temp file to detect if output is empty
TEMP_OUTPUT=$(mktemp)
trap 'rm -f "$TEMP_OUTPUT" "${TEMP_OUTPUT}.err"' EXIT

# Run symbolication - capture stdout and stderr separately
# Filter out verbose "Checking..." messages from stdout, keep stderr for errors
if "$SYMBOLICATE_PATH" -d "$DSYM_FILE" "$IPS_FILE" 2>"${TEMP_OUTPUT}.err" | grep -v "^Checking " > "$TEMP_OUTPUT"; then
    # Check if output is empty (after filtering)
    if [ ! -s "$TEMP_OUTPUT" ]; then
        print_warning "Symbolication completed but produced no output"
        echo "This may indicate a UUID mismatch between the IPS and dSYM files."
        echo ""
        echo "To verify UUIDs:"
        echo "  1. Get dSYM UUID: dwarfdump --uuid \"$DSYM_FILE\""
        echo "  2. Check 'Binary Images' section in your .ips file for matching UUID"
        rm -f "${TEMP_OUTPUT}.err"
        exit 1
    fi

    # Move temp output to final location
    mv "$TEMP_OUTPUT" "$OUTPUT_FILE"
    rm -f "${TEMP_OUTPUT}.err"
    trap - EXIT

    if [ $QUIET -eq 0 ]; then
        print_success "Symbolicated crash saved to: $OUTPUT_FILE"

        # Show preview of output (unless quiet mode)
        if [ $VERBOSE -eq 1 ]; then
            echo ""
            echo "Preview (first 10 lines):"
            echo "---"
            head -n 10 "$OUTPUT_FILE"
            echo "---"
        fi
    fi
else
    EXIT_CODE=$?
    trap - EXIT

    # Keep the output file for debugging if it has content, otherwise remove it
    if [ -s "$TEMP_OUTPUT" ]; then
        mv "$TEMP_OUTPUT" "$OUTPUT_FILE"
        # Append stderr to output file for debugging
        if [ -s "${TEMP_OUTPUT}.err" ]; then
            echo "" >> "$OUTPUT_FILE"
            echo "=== Standard Error ===" >> "$OUTPUT_FILE"
            cat "${TEMP_OUTPUT}.err" >> "$OUTPUT_FILE"
        fi
        rm -f "${TEMP_OUTPUT}.err"

        if [ $QUIET -eq 0 ]; then
            print_error "Symbolication failed (exit code: $EXIT_CODE)"
            echo "Output saved to: $OUTPUT_FILE for debugging"
            echo ""
            echo "Common causes:"
            echo "  - UUID mismatch between IPS and dSYM"
            echo "  - dSYM is stripped or incomplete"
            echo "  - IPS file format is corrupted"
        fi
    else
        rm -f "$TEMP_OUTPUT"
        rm -f "${TEMP_OUTPUT}.err"
        if [ $QUIET -eq 0 ]; then
            print_error "Symbolication failed (exit code: $EXIT_CODE)"
            echo "This usually indicates a UUID mismatch."
        fi
    fi

    if [ $QUIET -eq 0 ]; then
        echo ""
        echo "Troubleshooting:"
        echo "  1. Run: dwarfdump --uuid \"$DSYM_FILE\""
        echo "  2. Compare UUID to 'Binary Images' section in your .ips file"
        echo "  3. Make sure you have the exact dSYM from the build that crashed"
    fi

    exit $EXIT_CODE
fi
