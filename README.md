# Repair-Windows 🚀

![Windows Repair](https://img.shields.io/badge/Platform-Windows-blue?style=flat-square&logo=windows)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen?style=flat-square)

Welcome to **Repair-Windows** – your ultimate toolkit for fixing, optimizing, and maintaining your Windows 10/11 system like a pro! 🛠️ Whether you're dealing with boot issues, disk errors, or just want to squeeze out more performance, these scripts have got you covered.

No more digging through forums or running manual commands – just fire up these battle-tested CMD and PowerShell scripts and let them do the heavy lifting!

## Why This Repo? 💡
Windows can be a beast sometimes – corrupted files, slow performance, network glitches... you name it. This repo consolidates powerful, automated repair tools into one place. All scripts are designed to be:
- **Safe & Non-Destructive**: They prompt for admin rights and back up where needed.
- **Cross-Compatible**: Works on Windows 10 Pro and above (tested on 10.0.19045).
- **Easy to Use**: Just double-click or run from Command Prompt/PowerShell.

Inspired by real-world troubleshooting, these scripts use built-in Windows tools like DISM, SFC, CHKDSK, and more, wrapped in user-friendly batches.

## Features ✨
Here's a breakdown of the goodies:

### Core Repair Tools
- **boot_repair.cmd**: Fix boot issues and restore your system's startup sequence.
- **dism_sfc_scan.cmd**: Run DISM and SFC scans to repair corrupted system files.
- **chkdsk_scan_quick.cmd / mid.cmd / max.cmd**: Quick, medium, or thorough disk checks and repairs.
- **repair_wmi.cmd**: Rebuild and repair Windows Management Instrumentation (WMI) repository.

### Disk Optimization
- **defrag_optimise.cmd**: Defragment and optimize your drives for peak performance.
- **free_space_quick.cmd / mid.cmd / max.cmd**: Free up disk space by cleaning temp files, logs, and more.

### Network & Connectivity Fixes
- **flush_dns.cmd**: Clear DNS cache to resolve browsing issues.
- **reset_tcpip.cmd**: Reset TCP/IP stack.
- **reset_winsock.cmd**: Reset Winsock catalog.
- **reset_windows_update.cmd**: Fix stuck Windows Update services.

### Performance Boosters
- **enable_ultimate_performance.cmd**: Unlock the Ultimate Performance power plan for high-end hardware.
- **ntfs_optimise.cmd**: Tune NTFS file system settings.

### Git Utilities (in `./Git/`)
- **git_gc_all.cmd**: Clean up and optimize all Git repos.
- **git_pull_all.cmd / git_push_all.cmd**: Batch pull/push for multiple repos.
- **git_set_details.cmd**: Set global Git user details.
- **set_git_crlf.cmd / set_git_lf.cmd**: Configure line endings for cross-platform repos.

### Miscellaneous (in `./Misc/`)
- **get_system_info.cmd**: Generate a detailed system report.
- **print_queue_viewer.ps1**: View and manage print queues.
- **repair_volumes.cmd**: Repair all volumes on your system.
- **restore_pip_default.cmd**: Reset Python's pip to default settings.
- **tts.cmd**: Text-to-Speech utility for fun or accessibility.
- **unpack_archives.ps1**: Batch unpack archives (ZIP, RAR, etc.).

## Getting Started 🚀
1. **Clone the Repo**:
   ```
   git clone https://github.com/tboy1337/Repair-Windows.git
   cd Repair-Windows
   ```

2. **Requirements**:
   - Windows 10/11 (with admin privileges).
   - PowerShell 5.1+ (included in Windows).
   - Optional: Git, Python, Docker for specific scripts.

3. **Run a Script**:
   - Right-click a `.cmd` file and select "Run as administrator".
   - For `.ps1` files, open PowerShell as admin and run: `.\script.ps1`.
   - **Pro Tip**: Always back up important data before running repairs!

## Usage Examples 📝
- Fix system files: `dism_sfc_scan.cmd`
- Optimize disk: `defrag_optimise.cmd`
- Batch Git pull: `Git\git_pull_all.cmd`

For detailed usage, check each script's comments.

## Contributing 🤝
Love fixing Windows? Fork this repo, add your own scripts, and submit a PR!

## License 📄
This project is licensed under the MIT License - see [LICENSE.txt](./LICENSE.txt) for details.

---

*Disclaimer: These scripts are provided as-is. Always run with caution and understand what they do. Not responsible for any system issues.*