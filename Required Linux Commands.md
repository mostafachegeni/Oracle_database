=========================================================================
-------------------------------------------------------------------------
=========================================================================
- Use "tmux" or "screen" to run commands like unzip in background:
 (If macine is disconnected, then the process continues.)

- install package:
```
[ ]$ yum localinstall -y   tmux-2.4-2.gf.el7.x86_64
```
- open a new tmux terminal:
```
[ ]$ tmux
```
- attach to an opened tmux terminal:
```
[ ]$ tmux a
```
- exit from a tmux terminal:

(1)  
```
[ ]$ exit
```
(2)  
```
[ ]$ ctrl + d
```

=========================================================================
-------------------------------------------------------------------------
=========================================================================
- List Sizes of "Directories":
```
[oracle@Cloud12c ~]$ du -hs /u01/app/oracle/*
2.5M    /u01/app/oracle/admin
1020M   /u01/app/oracle/agent12c
480K    /u01/app/oracle/cfgtoollogs
4.0K    /u01/app/oracle/checkpoints
111M    /u01/app/oracle/diag
2.6G    /u01/app/oracle/gc_inst
13G     /u01/app/oracle/oms12cr5
18G     /u01/app/oracle/oradata
4.2G    /u01/app/oracle/product
639M    /u01/app/oracle/swlib
```

=========================================================================
-------------------------------------------------------------------------
=========================================================================
- Check Resource Utilization:
```
[ ]$ top

[ ]$ iostat

[ ]$ iostat -x 1
```
=========================================================================
-------------------------------------------------------------------------
=========================================================================
- Add new user: 	
(	-g: primary group, 
	-G: secondary groups
)
```
[ ]$ useradd -g users -G wheel,developers  username
```

- Add user to a group:
```
[ ]$ usermod -a -G group1,group2 username
```
=========================================================================
-------------------------------------------------------------------------
=========================================================================
- vi commands in Solaris 11:

h -> move cursor left \
j -> move cursor down \
k -> move cursor up \
l -> move cursor right \
o -> add new line below current line \
i -> insert characetr to the left of cursor \
x -> delete the character at the cursor \

=========================================================================
-------------------------------------------------------------------------
=========================================================================
- Using ACL to Give Read/Write Access to a specific User on Directory:
```
[ggmonitor@shdgtest ~]$ less /ogg1/ggserr.log
/ogg1/ggserr.log: Permission denied
```

- Check the default ACL settings for the directory:
```
[root@shdgtest ~]# getfacl /ogg1/ggserr.log       		  			
getfacl: Removing leading '/' from absolute path names
# file: ogg1/ggserr.log
# owner: oracle
# group: oinstall
user::rw-
group::r--
other::---


[root@shdgtest ~]# setfacl -m user:ggmonitor:r /ogg1/ggserr.log


[root@shdgtest ~]# getfacl /ogg1/ggserr.log
getfacl: Removing leading '/' from absolute path names
# file: ogg1/ggserr.log
# owner: oracle
# group: oinstall
user::rw-
user:ggmonitor:r--
group::r--
mask::r--
other::---
```
=========================================================================
-------------------------------------------------------------------------
=========================================================================
- Change SSH Configuration:
```
[ ]$ vi /etc/ssh/sshd_config
#Port 22
```

=========================================================================
-------------------------------------------------------------------------
=========================================================================
- NFS Configuration:

1. Open Ports: 22


2. NFS Server:
```
[root@shrac2 ~]# vi /etc/exports
/SHARE  192.168.105.0/24(rw,sync,no_root_squash)
/SHARE  192.168.116.5/32(rw,sync,no_root_squash)
/SHARE  192.168.115.2/32(rw,sync,no_root_squash)
/SHARE  192.168.116.6/32(rw,sync,no_root_squash)

[root@shrac2 ~]# service nfs reload
```

3. NFS Client:
```
[root@shnewtest ~]# yum install nfs-utils

[root@shnewtest ~]# mkdir /SHARE

[root@shnewtest ~]# mount -t nfs 192.168.105.7:/SHARE   /SHARE
```
=========================================================================
-------------------------------------------------------------------------
=========================================================================
- List of top memory consuming process:
```
// (list top consumers with the respect to "memory" and "processing power", "total CPU usage", "swap usage" etc.)
[root@shnewtest ~]# top
top - 16:36:34 up 408 days,  3:21, 11 users,  load average: 18.13, 20.33, 27.48
Tasks: 991 total,  19 running, 972 sleeping,   0 stopped,   0 zombie
%Cpu(s): 29.8 us,  2.6 sy,  0.0 ni, 67.4 id,  0.0 wa,  0.0 hi,  0.1 si,  0.0 st
KiB Mem : 13190056+total,   467456 free,  2393476 used, 12903963+buff/cache
KiB Swap: 67108860 total, 65684668 free,  1424192 used. 12474081+avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
34285 etladmi+  20   0  200268   8908   1728 R 100.0  0.0  29:40.96 python3.6
34286 etladmi+  20   0  200268   8912   1728 R 100.0  0.0  29:42.27 python3.6
34288 etladmi+  20   0  200268   8912   1728 R 100.0  0.0  29:36.15 python3.6
```


- Display Information about Processes:
```
// List of Processes currently running on the OS.
// ("process ID", "parent process ID", "program" which is being executed, "time" at which the process got executed etc.)
[root@shnewtest ~]# ps -eaf
UID        PID  PPID  C STIME TTY          TIME CMD
root         2     0  0  2019 ?        00:31:07 [kthreadd]
root         4     2  0  2019 ?        00:00:00 [kworker/0:0H]
root         6     2  0  2019 ?        04:33:31 [ksoftirqd/0]
```
- Kill a process:
```
// (Find "process ID" and "parent process ID" using the "PS command".
[root@shnewtest ~]# kill -F 900

=========================================================================
-------------------------------------------------------------------------
=========================================================================
// Format a partition:
[root@hostname ~]# mkfs.xfs -f /dev/sdc2
```

- Mount a partition "Temporarily":
```
[root@hostname ~]# mkdir -p /my_new_dir
[root@hostname ~]# mount /dev/sdc2 /my_new_dir
```
- Mount a partition "Permanently":
```
[root@hostname ~]# lsblk 
[root@hostname ~]# blkid
/dev/vdc2: UUID="bd1f54ba-c3ff-4748-aaf1-8f4c7f38f263" TYPE="xfs"

[root@hostname ~]# vi /etc/fstab
UUID=bd1f54ba-c3ff-4748-aaf1-8f4c7f38f263  /my_new_dir  xfs  defaults  0 0
```

=========================================================================
-------------------------------------------------------------------------
=========================================================================
- List of Open Files (Find deleted files that are open by some process):
```
// (when you "rm /u01/.../star_tbs.dbf"  
//		 but "df -h" shows disk is full.)
[root@moschdb19c ~]# yum install -y lsof

[root@moschdb19c ~]# lsof | grep -i delete
ora_dbw0_  351  oracle  267uW  REG  252.2  10737582 2857108  /u01/app/oracle/product/12c/dbhome_1/dbs/star_tbs.dbf (deleted)
ora_ckpt_  357  oracle  267u   REG  252.2  10737582 2857108  /u01/app/oracle/product/12c/dbhome_1/dbs/star_tbs.dbf (deleted)
```
=========================================================================
-------------------------------------------------------------------------
=========================================================================
- grep:
```
[oracle(shdb2)@shrac2 ~]$ ll / | grep --color -in tmp
24:drwxrwxrwt.   26 root   root      4096 Mar 16 13:16 tmp

- i 		ignore case
- n 		line number
-- color 	color matching patterns
```
=========================================================================
-------------------------------------------------------------------------
=========================================================================
- Find a file:
```
[root@moschdb ~]# find / -iname  *tnsname*.ora
/u01/app/12.2.0/grid/network/admin/samples/tnsnames.ora
/u01/app/oracle/product/12.2.0/dbhome_1/network/admin/samples/tnsnames.ora
/u01/app/oracle/product/12.2.0/dbhome_1/network/admin/tnsnames.ora

- i 		ignore case
- name 		search by name of files
```
=========================================================================
-------------------------------------------------------------------------
=========================================================================
- Less a file:
```
[root@ol7 ~]# less temp.txt

- Home 		Begining of the file
- End 		End of the file
- /<word> 	Serach for <word>		->	n: Next match, 
										N: Previous match
- Shift+F 	Waiting for new data	->	Ctrl+C: Exit
- q 		Quit
```
=========================================================================
-------------------------------------------------------------------------
=========================================================================
- Edit a file:
```
[root@moschdb ~]# vi temp.txt

- i			Insert new words
- :w		Save
- :wq		Save and Quit
- :q!		Quit without Saving
- :q		Quit
- Esc		Cancel
```
=========================================================================
-------------------------------------------------------------------------
=========================================================================
- Print a file:
```
[root@moschdb ~]# cat temp.txt
```
=========================================================================
-------------------------------------------------------------------------
=========================================================================
- Check hard disk partitions and disk space:
```
//----------------------
[root@ol7 ~]# cat /proc/partitions
[root@stand ~]# blkid
/dev/sdb1: LABEL="DATA1" TYPE="oracleasm"
/dev/sda1: UUID="f2f52701-ab6c-44b7-89dc-efca426130b5" TYPE="xfs"
/dev/sda2: UUID="d287d9a4-e80b-4a01-bb15-e2098e2e3f05" TYPE="xfs"
/dev/sda3: UUID="4f685c68-fd63-4ac4-8081-e2518aa86dfa" TYPE="xfs"
/dev/sda5: UUID="fa240762-0b5a-4214-af77-5d929fb59d99" TYPE="swap"
/dev/sr0:  UUID="2017-08-04-17-33-47-00" LABEL="OL-Server" TYPE="iso9660" PTTYPE="dos"
/dev/sdd1: LABEL="FRA1" TYPE="oracleasm"
------------------------
[root@dataguard2 ~]# df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda6       152G   60G   85G  42% /
tmpfs            48G  274M   47G   1% /dev/shm
/dev/sda2       976M   80M  829M   9% /boot
/dev/sda1       200M  268K  200M   1% /boot/efi
/dev/sda4        30G   33M   30G   1% /tmp
/dev/sda5        30G  787M   30G   3% /var
//----------------------
[root@prim ~]# lsblk -f
NAME   FSTYPE    LABEL       UUID                                 MOUNTPOINT
sda                          
├─sda1 xfs                   d40f3154-f6e5-4c4f-8e8d-040e89f9ceb8 /boot
├─sda2 swap                  c117ec3f-888c-488c-ae98-3e55a5b3bf69 [SWAP]
└─sda3 xfs                   9de8b291-3c4e-45e7-a3e1-4ef3f495621d /
sdb                          
└─sdb1 oracleasm DATA1       
sdc                          
└─sdc1 oracleasm FRA1        
sdd                          
├─sdd1 oracleasm             
└─sdd2                       
sr0    iso9660   OL-Server      								  /mnt

[root@prim ~]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   99G  0 disk
├─sda1   8:1    0  512M  0 part /boot
├─sda2   8:2    0   16G  0 part [SWAP]
└─sda3   8:3    0 82.5G  0 part /
sdb      8:16   0  100G  0 disk
└─sdb1   8:17   0  100G  0 part
sdc      8:32   0   30G  0 disk
└─sdc1   8:33   0   30G  0 part
sdd      8:48   0   20G  0 disk
├─sdd1   8:49   0   10G  0 part
└─sdd2   8:50   0    5G  0 part
sr0     11:0    1  4.6G  0 rom  /mnt

//----------------------
// add new partition:
[root@ol7 ~]# fdisk -l
[root@ol7 ~]# fdisk /dev/sdc
Command (m for help): m
Command (m for help): p
Command (m for help): n
Partition type:
   p   primary (0 primary, 0 extended, 4 free)
   e   extended
Select (default p):
Using default response p
Partition number (1-4, default 1):
First sector (2048-62914559, default 2048):
Using default value 2048
Last sector, +sectors or +size{K,M,G} (2048-62914559, default 62914559):
Using default value 62914559
Partition 1 of type Linux and of size 30 GiB is set

Command (m for help): w
The partition table has been altered!
Calling ioctl() to re-read partition table.
Syncing disks.
```

- Format the partition:
```
[root@hostname ~]# mkfs.xfs -f /dev/sdc2
```
- Mount the partition:
```
[root@hostname ~]# mkdir -p /my_new_dir
[root@hostname ~]# mount /dev/sdc2 /my_new_dir
```
- Find UUID:
```
[root@hostname ~]# blkid
```
- Add UUID to fstab:
```
[root@hostname ~]# vim /etc/fstab
UUID=5e5c0dc2-21ee-4047-a9c6-0d483a69fea9     /ARCHIVELOG     xfs    defaults  0 0


/*
https://access.redhat.com/solutions/1137403
https://access.redhat.com/solutions/57542

WARNING: Re-reading the partition table failed with error 16: Device or resource busy.
The kernel still uses the old table. The new table will be used at
the next reboot or after you run partprobe(8) or kpartx(8)
Syncing disks.
-------------------
[root@hostname ~]# fdisk -l /dev/sdc
[root@hostname ~]# fdisk /dev/sdc
...
[root@hostname ~]# partprobe 
*/

//----------------------
[root@ol7 ~]# parted -l

[root@dataguard2 ~]# parted /dev/sda
GNU Parted 2.1
Using /dev/sda
Welcome to GNU Parted! Type 'help' to view a list of commands.

(parted) print
Model: VMware Virtual disk (scsi)
Disk /dev/sda: 106GB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags:
Number  Start   End     Size    Type     File system     Flags
 1      1049kB  538MB   537MB   primary  xfs             boot
 2      538MB   17.7GB  17.2GB  primary  linux-swap(v1)
 3      17.7GB  106GB   88.6GB  primary  xfs


(parted) print devices
/dev/sda (106GB)
/dev/sdb (107GB)
/dev/sdc (32.2GB)
/dev/sdd (21.5GB)
/dev/sr0 (4939MB)


(parted) q
```
=========================================================================
-------------------------------------------------------------------------
=========================================================================
