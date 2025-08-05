#!/bin/bash

# Ubuntu Linux System Integrity Check and Repair Script
# Equivalent to Windows DISM/SFC functionality
# Fixed version with improved error handling and safety

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
HAS_CORRUPTION=0
REPAIR_NEEDED=0
DRY_RUN=0
LOG_FILE="/tmp/system_integrity_check.log"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# Usage function
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -d, --dry-run    Show what would be done without making changes"
    echo "  -h, --help       Show this help message"
    echo "  -l, --log FILE   Specify log file location (default: $LOG_FILE)"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run)
                DRY_RUN=1
                shift
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script requires root privileges."
        print_error "Please run with: sudo $0"
        exit 1
    fi
}

# Initialize log file
init_log() {
    echo "=== System Integrity Check Started: $(date) ===" > "$LOG_FILE"
    print_status "Log file: $LOG_FILE"
}

# Update package database
update_package_db() {
    print_status "Updating package database..."
    local temp_log=$(mktemp)
    
    if apt update > "$temp_log" 2>&1; then
        print_success "Package database updated successfully"
    else
        local exit_code=$?
        print_error "Failed to update package database. Exit code: $exit_code"
        print_error "Details in log: $(cat "$temp_log" | tail -3)"
        rm -f "$temp_log"
        return 1
    fi
    
    rm -f "$temp_log"
}

# Check for broken packages
check_broken_packages() {
    print_status "Checking for broken packages..."
    local temp_log=$(mktemp)
    
    # Check for packages with unmet dependencies
    if apt-get check > "$temp_log" 2>&1; then
        print_success "No broken packages detected"
    else
        print_warning "Found broken package dependencies"
        print_status "Details: $(cat "$temp_log" | head -5)"
        HAS_CORRUPTION=1
        REPAIR_NEEDED=1
    fi
    
    # Check for packages in inconsistent state
    local broken_packages=$(dpkg -l | grep -E "^(iU|rc)" | wc -l)
    if [[ $broken_packages -gt 0 ]]; then
        print_warning "Found $broken_packages packages in inconsistent state"
        HAS_CORRUPTION=1
        REPAIR_NEEDED=1
    fi
    
    rm -f "$temp_log"
}

# Check package integrity
check_package_integrity() {
    print_status "Checking package integrity..."
    
    # Check if debsums is available
    if ! command -v debsums &> /dev/null; then
        if [[ $DRY_RUN -eq 1 ]]; then
            print_status "Would install debsums for integrity checking (dry-run mode)"
            return 0
        else
            print_status "Installing debsums for integrity checking..."
            local temp_log=$(mktemp)
            if apt install -y debsums > "$temp_log" 2>&1; then
                print_success "debsums installed successfully"
            else
                print_error "Failed to install debsums"
                cat "$temp_log" | tail -3 | while read line; do print_error "$line"; done
                rm -f "$temp_log"
                return 1
            fi
            rm -f "$temp_log"
        fi
    fi
    
    # Run debsums to check file integrity (only if not dry-run)
    if [[ $DRY_RUN -eq 0 ]]; then
        local temp_file=$(mktemp)
        if timeout 300 debsums -c > "$temp_file" 2>&1; then
            print_success "All package files have correct checksums"
        else
            local changed_files=$(grep -c "FAILED" "$temp_file" 2>/dev/null || echo "0")
            if [[ $changed_files -gt 0 ]]; then
                print_warning "Found $changed_files files with incorrect checksums"
                print_status "Run 'debsums -c' manually to see details"
                HAS_CORRUPTION=1
            else
                print_success "Package integrity check completed"
            fi
        fi
        rm -f "$temp_file"
    else
        print_status "Would check package file checksums (dry-run mode)"
    fi
}

# Check filesystem integrity
check_filesystem() {
    print_status "Checking filesystem integrity..."
    
    # Check for filesystem errors in dmesg and system logs
    if dmesg | grep -i "filesystem error\|ext[234]-fs error\|corruption\|journal\|superblock" > /dev/null 2>&1; then
        print_warning "Filesystem errors detected in kernel messages"
        HAS_CORRUPTION=1
    else
        print_success "No filesystem errors in kernel messages"
    fi
    
    # Check for filesystem errors in systemd journal
    if journalctl --since="7 days ago" --grep="filesystem.*error|ext[234].*error" --no-pager -q > /dev/null 2>&1; then
        print_warning "Filesystem errors found in system journal (last 7 days)"
        HAS_CORRUPTION=1
    fi
    
    # Check disk usage and warn if critical
    local root_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $root_usage -gt 95 ]]; then
        print_warning "Root filesystem is ${root_usage}% full - this may cause system issues"
    elif [[ $root_usage -gt 85 ]]; then
        print_status "Root filesystem is ${root_usage}% full"
    fi
    
    # Note about full filesystem check
    print_status "Note: Complete filesystem check requires unmounting and is not performed on running system"
    print_status "To perform full check, boot from live USB and run: fsck -f /dev/[root-device]"
}

# Repair broken packages
repair_packages() {
    if [[ $REPAIR_NEEDED -eq 1 ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            print_status "Would attempt to repair broken packages (dry-run mode)"
            print_status "Would run: apt --fix-broken install"
            print_status "Would run: dpkg --configure -a"
            return 0
        fi
        
        print_status "Attempting to repair broken packages..."
        local temp_log=$(mktemp)
        
        # Fix broken dependencies
        print_status "Fixing broken dependencies..."
        if apt --fix-broken install -y > "$temp_log" 2>&1; then
            print_success "Fixed broken package dependencies"
        else
            print_error "Failed to fix broken packages"
            cat "$temp_log" | tail -5 | while read line; do print_error "$line"; done
        fi
        
        # Reconfigure packages that may be in a broken state
        print_status "Reconfiguring packages..."
        if dpkg --configure -a >> "$temp_log" 2>&1; then
            print_success "Package reconfiguration completed"
        else
            print_error "Failed to reconfigure packages"
            cat "$temp_log" | tail -5 | while read line; do print_error "$line"; done
        fi
        
        rm -f "$temp_log"
    fi
}

# Clean package cache and remove orphaned packages
cleanup_system() {
    if [[ $DRY_RUN -eq 1 ]]; then
        print_status "Would remove orphaned packages (dry-run mode)"
        print_status "Would clean package cache (dry-run mode)"
        return 0
    fi
    
    local temp_log=$(mktemp)
    
    print_status "Removing orphaned packages..."
    if apt autoremove -y > "$temp_log" 2>&1; then
        local removed=$(grep -c "Removing" "$temp_log" 2>/dev/null || echo "0")
        if [[ $removed -gt 0 ]]; then
            print_success "Removed $removed orphaned packages"
        else
            print_success "No orphaned packages to remove"
        fi
    else
        print_error "Failed to remove orphaned packages"
        cat "$temp_log" | tail -3 | while read line; do print_error "$line"; done
    fi
    
    print_status "Cleaning package cache..."
    if apt autoclean >> "$temp_log" 2>&1; then
        print_success "Package cache cleaned"
    else
        print_error "Failed to clean package cache"
        cat "$temp_log" | tail -3 | while read line; do print_error "$line"; done
    fi
    
    rm -f "$temp_log"
}

# Check and repair GRUB if needed
check_grub() {
    print_status "Checking GRUB bootloader..."
    
    if command -v update-grub &> /dev/null; then
        if [[ $DRY_RUN -eq 1 ]]; then
            print_status "Would update GRUB configuration (dry-run mode)"
            return 0
        fi
        
        local temp_log=$(mktemp)
        # Update GRUB configuration
        if update-grub > "$temp_log" 2>&1; then
            print_success "GRUB configuration updated"
        else
            print_warning "Failed to update GRUB configuration"
            cat "$temp_log" | tail -3 | while read line; do print_warning "$line"; done
        fi
        rm -f "$temp_log"
    else
        print_status "GRUB not found, skipping bootloader check"
    fi
}

# Check system logs for critical errors
check_system_logs() {
    print_status "Checking system logs for critical errors..."
    
    # Check for recent critical errors in systemd journal
    local critical_errors=0
    if command -v journalctl &> /dev/null; then
        critical_errors=$(journalctl --since="24 hours ago" --priority=crit --no-pager -q 2>/dev/null | wc -l)
    fi
    
    if [[ $critical_errors -gt 0 ]]; then
        print_warning "Found $critical_errors critical errors in the last 24 hours"
        print_status "Run 'journalctl --since=\"24 hours ago\" --priority=crit' to view them"
    else
        print_success "No critical errors found in recent logs"
    fi
    
    # Check for kernel oops or panics
    if dmesg | grep -i "oops\|panic\|segfault\|general protection fault" > /dev/null 2>&1; then
        print_warning "Kernel errors detected in dmesg"
        print_status "Run 'dmesg | grep -i \"oops\\|panic\\|segfault\"' for details"
    fi
}

# Check system services status
check_services() {
    print_status "Checking critical system services..."
    
    local failed_services=$(systemctl --failed --no-legend --no-pager 2>/dev/null | wc -l)
    if [[ $failed_services -gt 0 ]]; then
        print_warning "Found $failed_services failed system services"
        print_status "Run 'systemctl --failed' to view them"
    else
        print_success "All system services are running normally"
    fi
}

# System summary
print_summary() {
    echo
    echo "================================================"
    print_status "SYSTEM INTEGRITY SUMMARY"
    echo "================================================"
    
    if [[ $HAS_CORRUPTION -eq 1 ]]; then
        print_warning "Issues were detected during the scan"
    else
        print_success "No major issues detected"
    fi
    
    if [[ $REPAIR_NEEDED -eq 1 ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            print_status "Repairs would be attempted (dry-run mode)"
        else
            print_status "Repairs were attempted"
        fi
    fi
    
    echo "================================================"
}

# Main execution
main() {
    echo "================================================"
    echo "Ubuntu System Integrity Check and Repair Script"
    echo "================================================"
    echo
    
    if [[ $DRY_RUN -eq 1 ]]; then
        print_status "Running in DRY-RUN mode - no changes will be made"
        echo
    fi
    
    check_root
    init_log
    
    # Perform checks
    print_status "Starting system integrity checks..."
    echo
    
    update_package_db || true
    check_broken_packages || true
    check_package_integrity || true
    check_filesystem || true
    check_system_logs || true
    check_services || true
    
    # Perform repairs if needed
    echo
    if [[ $HAS_CORRUPTION -eq 1 ]] || [[ $REPAIR_NEEDED -eq 1 ]]; then
        print_status "Issues detected, performing repairs..."
        repair_packages || true
    else
        print_success "No corruption or issues detected requiring repair"
    fi
    
    # Cleanup
    echo
    print_status "Performing system cleanup..."
    cleanup_system || true
    check_grub || true
    
    print_summary
    
    # Suggest reboot if repairs were made
    if [[ $HAS_CORRUPTION -eq 1 ]] || [[ $REPAIR_NEEDED -eq 1 ]]; then
        if [[ $DRY_RUN -eq 0 ]]; then
            echo
            print_warning "System repairs were performed. A reboot is recommended."
            print_status "Run 'sudo reboot' when convenient."
        fi
    fi
    
    echo
    print_success "System integrity check completed successfully"
    print_status "Full log available at: $LOG_FILE"
}

# Trap to ensure cleanup on exit
trap 'echo; print_status "Script interrupted"; exit 1' INT TERM

# Parse command line arguments
parse_args "$@"

# Run main function
main

exit 0 