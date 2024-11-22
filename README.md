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

### 1. `DISM_and_SFC_Scan.cmd`
   - Runs the Deployment Imaging Service and Management Tool (DISM) and System File Checker (SFC) to scan and repair corrupted system files.

### 2. `Defrag_and_Optimise.cmd`
   - Defragments and optimizes all system drives, helping improve system performance on traditional HDDs and SSDs.

### 3. `Free_Space.cmd` & `Free_Space_2.cmd`
   - Clears unnecessary temporary files and frees up disk space to improve performance.

### 4. `Repair_Volumes.cmd`
   - Repairs volume errors using the CHKDSK utility on all detected drives.

### 5. `Reset_Windows_Update.cmd`
   - Resets the Windows Update components to fix issues related to stuck or failed updates.

### 6. `Reset_winsock.cmd`
   - Resets the Winsock catalog to resolve network connectivity issues.

### 7. `bootrec.cmd`
   - Utilizes the `bootrec` tool to fix boot sector issues, which can help resolve problems with booting Windows (need to be in WindowsRE to use this).

### 8. `chkdsk_Scan.cmd`
   - Runs the CHKDSK utility for FAT and NTFS drives to check and repair file system errors.

## Usage

1. Download or clone this repository to your local machine.
2. Run the desired `.cmd` by right-clicking and selecting "Run as administrator".

## Requirements
- Windows OS (Windows 7 or higher recommended)
- Administrator privileges for full functionality

## License
This project is licensed under the terms of the [MIT License](LICENSE.txt).

---

**Disclaimer:** These scripts are provided as-is. Always back up your data before performing repairs or maintenance tasks.
