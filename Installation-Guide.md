# Venom Linux Installation Guide
A comprehensive installation guide for Venom Linux

### No Warrenty, Use At Your Own Risc
Venom Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.

### Minimum System Requirements
- x86_64 CPU
- 4 GB RAM (System Memory)
- 100 GB of Disk Space
- CD/DVD drive or a USB port for the installer media

### Getting Started
Venom Linux provides a few live installer images that contain a installer.
These live images come with a full desktop enviornement and basic applications configured for that environment.
MATE, Xfce4, LXDE and LXQT are available in addition to these flavors Venom Linux provides a Xorg-only iso and a base image.
The base image provides a minimal set of packages to install and setup a Venom Linux system.

All the installation images can be downloaded from the [Venom Linux Website](http://venomlinux.org/download.html)
It is advised to verify the mdsum of the downloaded iso file; e.g. `md5sum venom-xfce4-20200602.iso`
If the mdsum matches with the mdsum on the [download](https://venomlinux.org/download.html) page of the Venom Linux website you can move forward and either burn the iso image on a CD/DVD or create a bootable USB drive.

### Creating a Bootable USB drive on Linux
Identify you USB drive with *fdisk* by opening your favorite terminal emulator and typing:

`sudo fdisk -l`

The output of this will show the USB device as /dev/sdb or /dev/sdc, we will refer to /dev/sdx in this guide where x is the appropriote letter from the output of the fdisk command.
Next you need to make sure that your USB drive is not mounted by unmounting it with

`sudo umount /dev/sdx`

Now you are ready to write the downloaded iso to your USB drive, we will use the *dd* command for this.

**Warning: use the dd command with caution as it will overwrite any data on the USB drive.**

`sudo dd if=/home/username/Downloads/venom-xfce4-20191002.iso of=/dev/sdx bs=4M && sync`
Change the command to let dd find the iso in the correct directory and change the image name and device name of this example to the correct image name and device name. Note sdx, do **not** use partitions i.e. sdb1, sdc1, etc. instead use sdb, sdc, etc. The *sync* command at the end will flush all data.
dd will not print any output until the process is completed (or if it failed). 
Depending on your device, this process can take a few minutes.

### Burning on a CD or DVD

Any modern disk burning application should be able to write the iso file to a CD or DVD.
A few suggestions are:
- Brasero
- K3B
- Xfburn
- Infrarecorder (Windows)

In general live sessions will be less responsive on a CD or DVD than with a USB or hard drive.

### Booting up

Boot your machine using the previously-created installation medium. Depending on the BIOS manufacturer this can be done by starting the computer and press ESC, F1, F2, F8, F10 or F12 during the initial startup screen. A menu may appear giving you the option to give a CD/DVD or USB drive boot sequence priority over the hard drive, move it to the first position in the list. Or select the installation device (CD/DVD or USB). You can choose to run the live image from the media, or, if you have the resources available, you can load the contents of the image into RAM. This option takes some time at the beginning but provides a quicker installation procedure.

Once the live image has booted you need to check if you have a working internet connection.
Venom Linux does not have a graphical installar. To start the installer you open a terminal, the default terminal that comes with the Destop Enviornement is fine. To start the installer run the command `sudo venom-installer` alternatively you can become root by typing `su -` at the terminal prompt, when prompted for a password type in *root* and then run the command `venom-installer`.

**Note: on newer ISO images it is not necessary to open a terminal. There should be an install icon (Venom logo) on the desktop. Double clicking this icon will conveniently launch the installer in a new terminal window.**

### Installing Venom Linux

When the installer starts you are greeted by a curses menu, the following section will detail each screen of the installer.
![Installer Menu](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_21_56_16.png)

#### Keyboard
Select the keymap for your keyboard, for example us for US QWERTY keyboard:
![Set Keyboard](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/06%20-%20Set%20Keyboard.png) 

#### Partitioning
When Partition Disk is selected from the Installer Menu you are greeted with a handy tip in regards to partitioning your disk for BIOS and EFI Systems. For BIOS systems MBR partition table is recommended (dos label type). 
For EFI paritions a GPT GPT partition table is required. 
Also a FAT32 partition with at least 100 MB - 200 MB is a safe choice.
This partition should be set as type EFI.
![Partition Tips](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/08%20-%20Partition%20Tips.png)

This guide will walk you through setting up partitions for both BIOS as well as for UEFI systems.

Select either cfdisk or fdisk to partition your disk. cfdisk is a bit more user-friendly compared to fdisk.
![Run Cfdisk](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/09%20-%20Run%20cfdisk.png)

Select the disk you want to partition for your Venom Linux install
![Choose Disk](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/10%20-%20Choose%20Disk.png)

Select a Partition Label type with regards to your system as was hinted in the Partition Tip earlier.

##### For BIOS systems 

Select dos label type
![Select Label](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/11%20-%20Select%20Label%20Type.png)

Create your partitions as you see fit.
In this example we are creating a root partiton, a home partition and a SWAP partition.
![Change Partition Type](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_00_33.png)

![Partitions](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_01_17.png)

##### For UEFI systems

Select GPT label type
![GPT Label](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_13_06_2020_20_02_40.png)

Create your partitions as you see fit but remember to create a dedicated partition of at least 100 MB for EFI.
![GPT Partitions](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_13_06_2020_20_03_44.png)

Change the partition type of the 100 ~ 200 MB partition to EFI System.
![EFI System](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_13_06_2020_20_03_58.png)

##### For both UEFI as well as BIOS**

Create a SWAP partition; to create a SWAP partition in cfdisk you need to alter the partition type
![Select Partition Type SWAP](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/14%20-%20Select%20Partition%20TypVee%20for%20swap.png)

![GPT Partitions Overview](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_13_06_2020_20_05_06.png)

**Don't forget to write your changes to disk before you quit cfdisk.**

![Write](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_02_23.png)

If you have set-up your partitions for UEFI system (GPT partition table and 100 ~ 200 MB EFI partition) the Venom Installer will detect this and will prompt you to choose the EFI partition.
If you have set up your partitions for a BIOS system (MBR) then the installer will obviously skip this step.
![EFI Partition](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_13_06_2020_20_05_30.png)

When you have written the changes to disk it's time to choose the partition you want Venom to live in.
![Choose Disk](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_02_53.png)

Format the partition.
![Format](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_03_11.png)

Select the filesystem of this partition:
![Select Filesystem](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_03_30.png)

The Venom Installer will detect your SWAP partition if you gave it the correct type during partitioning.
![SWAP Found](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_04_03.png)

Select the SWAP partitions:
![Choose SWAP Partition](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_04_16.png)

The installer will ask if you would like to setup another partition.
In our example we created a */home* partition, this is the time and place to set it up.
![Setup Another Partition](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_05_04.png)

Choose the partition you would like to use.
![Choose Partition](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_05_26.png)

Type /honme
![Mount Point](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_06_09.png)

Select the file system for this partition,
![File System Select](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_06_18.png)

We are presented with the option to setup yet another partition. In this case we will choose "No" as we didn't created any other partition besides /home. If you created a dedicated partition for e.g. /var this would be the place to set that up.
![Setup Another Partition](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_06_44.png)

**Note: If you select "Yes" and there is no other partition to setup the installer will skip and move forward to the next step**

After done setting up partitions we get a small summery of the partitons we just setup.
The root partition is not included in this small overview because root is basically needed to have Venom installed.
![Partition Overview](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_06_57.png)

#### Set Timezone
After this is done you can choose Set Timezone from the Venom Linux Installer menu.
Select your timezone accordingly.
![Set Timezone](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/21%20-%20Select%20Timezone.png)

#### Hostname
Set Hostname and type the hostname for your machine.
![Host Name](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/23%20-%20Enter%20Hostname.png)

#### Set locale
![Set Locale](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_08_12.png)

For example "en_US" choose yours accordingly.
![Locale](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_08_46.png)

Select your time.
![Select Time](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_08_58.png)

**Set-Up a User Account**
Set User Account by entering a login name and a password, you will be prompted to retype the password.
![Set User Account](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/24%20-%20Set%20User%20Account.png)

![Login Name](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/25%20-%20Enter%20Login%20Name.png)

![User Password](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/26%20-%20Enter%20User%20Password.png)

![Confirm User Password](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/27%20-%20Confirm%20User%20Password.png)

#### Set Password for Root
Set Root Password is similar to setting up the user with the difference being that no login name is needed.
![Root Password](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/29%20-%20Enter%20Root%20Password.png)

![Confirm Root Password](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/30%20-%20Confirm%20Root%20Password.png)

#### Set-Up Grub
Next up is setting up grub; 
![Bootloader](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/31%20-%20Bootloader.png)

Unless you really know what you are doing it is highly recommended to install the grub bootloader.
So select yes in this section.
![Install Grub](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/32%20-%20Install%20Bootloader.png)

The installer will ask where you want to install the bootloader.
Select the device your Venom Linux installer will live in; for example it's /dev/sda (notice that there is no number after sda, which is correct).
![Choose Disk](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/33%20-%20Choose%20Disk%20for%20Bootloader.png)

#### View Settings
Last but not least you will get a chance to review your selected settings before you let the installer run.
It's important to pay attention here and check if everything has been setup correctly.
Note that if you are **not** installing on an EFI system the EFI section will be marked SKIP.
Obviously if you are installing on an EFI system this will present a value; e.g. /dev/sda1.
![View Settings](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/34%20-%20View%20Saved%20Settings.png)

![View Settings EFI](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_13_06_2020_20_08_51.png)

![Saved Settings](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/VirtualBox_Test%20Machine_10_06_2020_22_11_46.png)

#### Install Venom
After you have verified that the settings you have saved are correct you can let the installer do it's work;
![install](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/36%20-%20Install.png)

The installer will ask if you really want to continue with the installation
![Confirm Install](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/37%20-%20Continue%20with%20Installation.png)

Once Yes is selected the installer will start installing Venom Linux on your system with the settings as you have selected and reviewed.
![installation Progress](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/38%20-%20Installation%20in%20Process.png)

You will get a notification when the installation is complete.
The installer will ask for a reboot, just hit enter to select OK.
![Installer Done](https://github.com/TenOfEleven/venomlinux-installation-guide/blob/master/39%20-%20installation%20Done.png)

You will be dropped back to a commandline prompt; if you are root a simple `reboot` command will do, if not run `sudo reboot` to reboot your system. Congrats! You have succesfully installed Venom Linux.

Enjoy!
