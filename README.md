## EVADE: *E*xternal *V*ault *A*ccess *D*efense *E*ngine

The **EVADE** system is a highly effective, architecture-agnostic solution designed to enforce **Complete OS Isolation** when running an operating system from a portable storage device (e.g., a USB drive). It ensures that all modifications, user data, and system changes are strictly contained on the external drive, preventing any unauthorized reading or writing to the host computer's internal storage devices.

### Core Concept and Purpose

**Acronym:** EVADE (External Vault Access Defense Engine)
**Goal:** To establish a **"Live System with Persistence on External Media Only"** security posture.

When you boot an OS from a USB drive on a host PC:

1.  The entire OS, including its filesystem root (`/`), is loaded into the host PC's RAM (volatile memory).
2.  All session activities (file creation, configuration changes, software installation) occur in RAM.
3.  The EVADE engine manages the persistence layer on the USB drive, ensuring all saves and restores target the external vault only.
4.  Crucially, the EVADE engine implements a defense mechanism that prevents the OS from mounting, accessing, or writing to any detected internal host drives.

**Security Feature (EVADE Security):** Full OS Isolation on a flash drive, ensuring zero impact on the host machine's local storage.

-----

### EVADE Architecture: The Defense Layers

EVADE works by implementing mandatory access control and device filtering at two key stages: **Boot Time** and **Runtime**.

#### 1\. Boot-Time Defense (The Isolation Kernel Hook)

This layer executes immediately after the OS kernel loads but before the main filesystem is fully accessed.

| Component | Mechanism | Purpose |
| :--- | :--- | :--- |
| **Kernel Command Line** | Use of specific boot parameters. | Instructs the kernel to restrict access. |
| **Udev Rules Hook** | A custom udev rule set (`99-evade-block.rules`). | Detects and blocks internal storage devices *before* they are assigned a mount point or standard device name (`/dev/sdX`). |
| **`nil-evade-init` Script** | Script within the initial RAM disk (initrd). | Identifies the boot media and creates a whitelist. **All other block devices are blacklisted or unlinked from `/dev`.** |

#### 2\. Runtime Defense (The Access Control Engine)

This layer runs continuously as a system service once the OS is fully operational.

| Component | Mechanism | Purpose |
| :--- | :--- | :--- |
| **Mandatory Access Control (MAC)** | **AppArmor** or **SELinux** policy loaded at startup. | Defines strict file system access policies. The policy explicitly denies read/write access to device paths (`/dev/sda*`, `/dev/nvme*`) that do not belong to the whitelisted USB drive. |
| **Storage Daemon Watch** | A continuous service (e.g., a simplified script or `systemd` service). | Periodically scans the `/dev` directory and ensures that no internal devices have been mounted or linked, re-applying the udev rules if necessary. |

-----

### Persistence Management (The Vault)

The persistence mechanism ensures that changes are saved only to the external drive.

| Component | Mechanism | Purpose |
| :--- | :--- | :--- |
| **Vault Directory** | `/mnt/EVADE-VAULT/mydata/` on the USB drive. | The designated safe location for the compressed system image. |
| **Restore on Boot** | **`filetool.sh -r`**. | Executes inside the `initrd`. Restores `mydata.tgz` from the Vault to the RAM filesystem. |
| **Auto-Save Daemon** | **`autosave.sh`**. | Runs in the background to periodically package changes and save them back to the Vault on the external drive. |

### Instructions for adding EVADE Security to your OS

#### Step 1: Preparing filetool files

1. Create files or move files named filetool (all 3) to the directory with the autorun scripts when the system starts (for example, in Tiny Core Linux, this is bootlocal.sh in /opt)

- [filetool.sh](filetool.sh)
- [.xfiletool.lst](.xfiletool.lst)
- [.filetool.lst](.filetool.lst)

#### Step 2: Adding the autosave/load script to the directory with the script for automatically running scripts when the OS starts

Place this script: (autosave.sh)[autosave.sh] in the folder with the script that runs scripts when the PC starts

#### Step 3: Adding autostart

At the very beginning of the file that runs other scripts at system startup, add: /directory/autosave.sh

Where / is the system root folder
directory - Replace where 'directory' with the name of the folder where your script that runs other scripts at system startup is located.

#### Step 4: Customize the autosave script

The autosave.sh script contains the following section:

```sh
echo "Initializing .filetool.lst with common user directories..."
cat << EOF > /opt/.filetool.lst
home
opt/
etc/hosts
etc/shadow
etc/passwd
etc/group
etc/fstab
# Add directories of your Unix-like OS to backup
EOF
```

From home to the end of etc/fstab, change or add your important folders to be saved in mydata.tgz **(⚠️ The more folders or files = the larger the save size)**

❗❗❗Also, be sure to add your folders and files after cat << EOF > /opt/.filetool.lst and before EOF in the file: [**.filetool.lst**](.filetool.lst)❗❗❗
