#!/bin/bash

# Ubuntu Linux System Integrity Check and Repair Script
# Equivalent to Windows DISM/SFC functionality

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

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script requires root privileges."
        print_error "Please run with: sudo $0"
        exit 1
    fi
}

# Update package database
update_package_db() {
    print_status "Updating package database..."
    if apt update > /dev/null 2>&1; then
        print_success "Package database updated successfully"
    else
        print_error "Failed to update package database. Error code: $?"
        return 1
    fi
}

# Check for broken packages
check_broken_packages() {
    print_status "Checking for broken packages..."
    
    # Check for broken dependencies
    BROKEN_COUNT=$(apt list --broken 2>/dev/null | grep -c "broken" || true)
    
    if [[ $BROKEN_COUNT -gt 0 ]]; then
        print_warning "Found $BROKEN_COUNT broken packages"
        HAS_CORRUPTION=1
        REPAIR_NEEDED=1
    else
        print_success "No broken packages detected"
    fi
}

# Check package integrity
check_package_integrity() {
    print_status "Checking package integrity..."
    
    # Create temporary file for debsums output
    TEMP_FILE=$(mktemp)
    
    # Check if debsums is installed
    if ! command -v debsums &> /dev/null; then
        print_status "Installing debsums for integrity checking..."
        apt install -y debsums > /dev/null 2>&1
    fi
    
    # Run debsums to check file integrity
    if debsums -c > "$TEMP_FILE" 2>&1; then
        print_success "All package files have correct checksums"
    else
        CHANGED_FILES=$(wc -l < "$TEMP_FILE")
        if [[ $CHANGED_FILES -gt 0 ]]; then
            print_warning "Found $CHANGED_FILES files with incorrect checksums"
            HAS_CORRUPTION=1
        fi
    fi
    
    rm -f "$TEMP_FILE"
}

# Check filesystem integrity
check_filesystem() {
    print_status "Checking filesystem integrity..."
    
    # Get root filesystem
    ROOT_FS=$(df / | tail -1 | awk '{print $1}')
    
    # Check if it's an ext filesystem
    if file -s "$ROOT_FS" | grep -q "ext[2-4]"; then
        print_status "Running filesystem check on $ROOT_FS..."
        
        # Run fsck in read-only mode to avoid unmounting issues
        if fsck -n "$ROOT_FS" > /dev/null 2>&1; then
            print_success "Filesystem integrity check passed"
        else
            print_warning "Filesystem issues detected on $ROOT_FS"
            HAS_CORRUPTION=1
        fi
    else
        print_status "Non-ext filesystem detected, skipping fsck"
    fi
}

# Repair broken packages
repair_packages() {
    if [[ $REPAIR_NEEDED -eq 1 ]]; then
        print_status "Attempting to repair broken packages..."
        
        # Fix broken dependencies
        if apt --fix-broken install -y > /dev/null 2>&1; then
            print_success "Fixed broken package dependencies"
        else
            print_error "Failed to fix broken packages. Error code: $?"
        fi
        
        # Reconfigure packages that may be in a broken state
        print_status "Reconfiguring packages..."
        if dpkg --configure -a > /dev/null 2>&1; then
            print_success "Package reconfiguration completed"
        else
            print_error "Failed to reconfigure packages. Error code: $?"
        fi
    fi
}

# Clean package cache and remove orphaned packages
cleanup_system() {
    print_status "Cleaning package cache..."
    if apt autoremove -y > /dev/null 2>&1; then
        print_success "Removed orphaned packages"
    else
        print_error "Failed to remove orphaned packages. Error code: $?"
    fi
    
    print_status "Cleaning package cache..."
    if apt autoclean > /dev/null 2>&1; then
        print_success "Package cache cleaned"
    else
        print_error "Failed to clean package cache. Error code: $?"
    fi
}

# Check and repair GRUB if needed
check_grub() {
    print_status "Checking GRUB bootloader..."
    
    if command -v grub-install &> /dev/null; then
        # Update GRUB configuration
        if update-grub > /dev/null 2>&1; then
            print_success "GRUB configuration updated"
        else
            print_warning "Failed to update GRUB configuration. Error code: $?"
        fi
    else
        print_status "GRUB not found, skipping bootloader check"
    fi
}

# Check system logs for critical errors
check_system_logs() {
    print_status "Checking system logs for critical errors..."
    
    # Check for recent critical errors in syslog
    CRITICAL_ERRORS=$(journalctl --since="24 hours ago" --priority=crit --no-pager -q | wc -l)
    
    if [[ $CRITICAL_ERRORS -gt 0 ]]; then
        print_warning "Found $CRITICAL_ERRORS critical errors in the last 24 hours"
        print_status "Run 'journalctl --since=\"24 hours ago\" --priority=crit' to view them"
    else
        print_success "No critical errors found in recent logs"
    fi
}

# Main execution
main() {
    echo "================================================"
    echo "Ubuntu System Integrity Check and Repair Script"
    echo "================================================"
    echo
    
    check_root
    
    # Perform checks
    update_package_db
    check_broken_packages
    check_package_integrity
    check_filesystem
    check_system_logs
    
    # Perform repairs if needed
    if [[ $HAS_CORRUPTION -eq 1 ]] || [[ $REPAIR_NEEDED -eq 1 ]]; then
        echo
        print_status "Issues detected, performing repairs..."
        repair_packages
    else
        print_success "No corruption or issues detected"
    fi
    
    # Cleanup
    cleanup_system
    check_grub
    
    echo
    echo "================================================"
    print_success "System integrity check completed"
    echo "================================================"
    
    # Suggest reboot if repairs were made
    if [[ $HAS_CORRUPTION -eq 1 ]] || [[ $REPAIR_NEEDED -eq 1 ]]; then
        echo
        print_warning "System repairs were performed. A reboot is recommended."
        echo "Run 'sudo reboot' when convenient."
    fi
}

# Trap to ensure cleanup on exit
trap 'echo; print_status "Script interrupted"; exit 1' INT TERM

# Run main function
main

exit 0 