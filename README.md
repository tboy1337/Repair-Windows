# Windows Repair and Optimization Scripts

This repository provides a collection of batch scripts to repair and optimize Windows systems. These scripts automate various maintenance and repair tasks, making it easier to keep your Windows PC running smoothly. 

## Table of Contents
- [Features](#features)
- [Scripts Overview](#scripts-overview)
- [Usage](#usage)
- [Requirements](#requirements)
- [License](#license)

## Features
- Automate common repair and maintenance tasks for Windows systems.
- Improve system performance by freeing up disk space and defragmenting drives.
- Repair essential Windows services and files, including resetting Windows Update and Winsock.
- Tools for system health checks, including CHKDSK and DISM scans.

## Scripts Overview

### Repair and Optimization Scripts

### 1. `dism_sfc_scan.cmd`
   - Runs the Deployment Imaging Service and Management Tool (DISM) and System File Checker (SFC) to scan and repair corrupted system files.

### 2. `defrag_optimise.cmd`
   - Defragments and optimizes all system drives, helping improve system performance on traditional HDDs and SSDs.

### 3. `free_space_quick.cmd` & `free_space_max.cmd`
   - Clears unnecessary temporary files and frees up disk space to improve performance.

### 4. `repair_volumes.cmd`
   - Repairs volume errors using the CHKDSK utility on all detected drives.

### 5. `reset_windows_update.cmd`
   - Resets the Windows Update components to fix issues related to stuck or failed updates.

### 6. `reset_winsock.cmd`
   - Resets the Winsock catalog to resolve network connectivity issues.

### 7. `boot_repair.cmd`
   - Comprehensive boot repair tool that fixes boot sector issues, runs system file checks, performs startup repairs, memory diagnostics, and advanced boot repairs in Windows Recovery Environment (must be run in Windows RE).

### 8. `chkdsk_scan_quick.cmd`
   - Runs a quick CHKDSK scan for FAT and NTFS drives to check and repair file system errors.

### 9. `chkdsk_scan_mid.cmd`
   - Runs a medium-level CHKDSK scan for more thorough checking.

### 10. `chkdsk_scan_max.cmd`
   - Runs a maximum thorough CHKDSK scan including bad sector recovery.

### 11. `enable_ultimate_performance.cmd`
   - Enables the Ultimate Performance power plan to maximize system performance.

### 12. `ntfs_optimise.cmd`
   - Optimizes NTFS file system by increasing memory usage for metadata and reserving more space for the Master File Table (MFT).

### 13. `flush_dns.cmd`
   - Flushes the DNS resolver cache to resolve networking issues.

### 14. `repair_wmi.cmd`
   - Repairs Windows Management Instrumentation (WMI) repository.

### 15. `reset_tcpip.cmd`
   - Resets the TCP/IP stack to fix network connectivity problems.

### Git Utilities (in `Git/` folder)
These scripts help manage multiple Git repositories:

- `git_gc_all.cmd`: Performs garbage collection on all Git repositories in the current directory.
- `git_pull_all.cmd`: Pulls latest changes for all Git repositories in the current directory.
- `git_push_all.cmd`: Pushes changes for all Git repositories in the current directory.
- `git_set_details.cmd`: Sets Git user name and email details.
- `set_git_crlf.cmd`: Configures Git to use CRLF line endings.
- `set_git_lf.cmd`: Configures Git to use LF line endings.

### Miscellaneous Utilities (in `Misc/` folder)
Additional helpful scripts:

- `get_system_info.cmd`: Generates a detailed system information report including hardware and OS details.
- `print_queue_viewer.ps1`: Views and manages the print queue.
- `proxy_converter.py`: Converts proxy formats (Python script).
- `restore_pip_default.cmd`: Restores default pip configuration.
- `tts.cmd`: Text-to-speech utility.
- `unpack_archives.ps1`: Unpacks various archive formats.

## Usage

1. Download or clone this repository to your local machine.
2. Run the desired `.cmd` by right-clicking and selecting "Run as administrator".

## Requirements
- Windows OS (Windows 7 or higher recommended)
- Administrator privileges for full functionality

## License
This project is licensed under the terms of the [MIT License](LICENCE.txt).

---

**Disclaimer:** These scripts are provided as-is. Always back up your data before performing repairs or maintenance tasks.
