# Install Oracle Database 12cR2 with ASM on Oracle linux 7.4 (with 2 OS users: oracle and grid)
## References:
[access.redhat.com](https://access.redhat.com/documentation/en-us/reference_architectures/2017/html-single/deploying_oracle_database_12c_release_2_on_red_hat_enterprise_linux_7/index) \
[www.uxora.com](https://www.uxora.com/oracle/dba/41-install-oracle-grid-infrastructure-12cr2-for-rac) \
[www.uxora.com](https://www.uxora.com/oracle/dba/47-install-oracle-grid-infrastructure-12cr2-standalone) \
[www.oracle-wiki.net](http://www.oracle-wiki.net/startdocshowtoinstalloracle12clinuxasm#Known-Issues)
-------------------------------------------------------------------------------------
## System Configuration:
- Oracle Linux 7.4 (Kernel Version: 4.1.12-94.3.9.el7uek.x86_64)
- Oracle Database 12c Release 2 Grid Infrastructure for Linux x86-64 (Version: 12.2.0.1.0) [linuxx64_12201_grid_home.zip]
- Oracle Database 12c Release 2 for Linux x86-64 (Version: 12.2.0.1.0) [linuxx64_12201_database.zip]
-------------------------------------------------------------------------------------
- Grid:
    Oracle base: 		/u01/app/12.2.0
    Software location:	/u01/app/12.2.0/grid 
- Database:
    Oracle base:		/u01/app/oracle
    Software Location:	/u01/app/oracle/product/12.2.0/dbhome_1 \
====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Set New Hostname:

1. Configure Hostname:
```
[root@oramain ~]# hostname moschdb.mosch.co

[root@oramain ~]# su -
Last login: Mon Feb 24 15:39:51 +0330 2020 from 192.168.72.112 on pts/0

[root@moschdb ~]# nmtui-hostname
-- set to "moschdb.mosch.co" -> press "OK"

[root@moschdb ~]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

[root@moschdb ~]# vi /etc/hosts
127.0.0.1           localhost   localhost.localdomain localhost4 localhost4.localdomain4
::1                 localhost   localhost.localdomain localhost6 localhost6.localdomain6
192.168.96.113      moschdb     moschdb.mosch.co
```
====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Local Yum Repositorey:

1. Find "OracleLinux.iso" (sr0):
```
[root@moschdb ~]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   99G  0 disk
├─sda1   8:1    0  512M  0 part /boot
├─sda2   8:2    0   16G  0 part [SWAP]
└─sda3   8:3    0 82.5G  0 part /
sdb      8:16   0  100G  0 disk
sr0     11:0    1  4.6G  0 rom
```
-----------------------------------------
2. Make New Directory "mnt", Mount "/dev/sr0":
```
[root@moschdb ~]# mkdir -p /mnt

[root@moschdb ~]# mount /dev/sr0 /mnt
mount: /dev/sr0 is write-protected, mounting read-only

[root@moschdb ~]# df -h /mnt
Filesystem      Size  Used Avail Use% Mounted on
/dev/sr0        4.6G  4.6G     0 100% /mnt
```
-----------------------------------------
3. Create an entry in "/etc/fstab" so that the system always mounts the DVD image after a reboot:
```
[root@moschdb ~]# cat /etc/fstab
UUID=9de8b291-3c4e-45e7-a3e1-4ef3f495621d /       xfs     defaults   0 0
UUID=d40f3154-f6e5-4c4f-8e8d-040e89f9ceb8 /boot   xfs     defaults   0 0
UUID=c117ec3f-888c-488c-ae98-3e55a5b3bf69 swap    swap    defaults   0 0

[root@moschdb ~]# vi /etc/fstab
UUID=9de8b291-3c4e-45e7-a3e1-4ef3f495621d /       xfs     defaults   0 0
UUID=d40f3154-f6e5-4c4f-8e8d-040e89f9ceb8 /boot   xfs     defaults   0 0
UUID=c117ec3f-888c-488c-ae98-3e55a5b3bf69 swap    swap    defaults   0 0
/dev/sr0                                  /mnt    iso9660 defaults   0 0
```
-----------------------------------------
4. Check Correctness of "Hash" value (Compare with "OracleLinux-R7-U4-Server-x86_64-dvd.iso.sha1sum"):
```
[root@moschdb ~]# sha1sum /dev/sr0
a855783f4cd8bdd17b785591a21746eda7abf476  /dev/sr0

[root@moschdb ~]# cksum linuxx64_12_2_0_1_database.zip
4170261901 3453696911 linuxx64_12_2_0_1_database.zip
[root@moschdb ~]# cksum linuxx64_12_2_0_1_grid_home.zip
1523222538 2994687209 linuxx64_12_2_0_1_grid_home.zip

[root@moschdb ~]# mv /etc/yum.repos.d/public-yum-ol7.repo /etc/yum.repos.d/public-yum-ol7-old

[root@moschdb ~]# vi /etc/yum.repos.d/public-yum-ol7.repo
[moschdb_local_repo]
name=Oracle Linux 7.4 Local Repository
baseurl=file:///mnt/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY
gpgcheck=1
enabled=1

[root@moschdb ~]# yum clean all

[root@moschdb ~]# yum repolist all
Loaded plugins: ulninfo
moschdb_4_local_repo                                                                                                                                                                       | 3.6 kB  00:00:00
(1/2): moschdb_4_local_repo/group_gz                                                                                                                                                       | 136 kB  00:00:00
(2/2): moschdb_4_local_repo/primary_db                                                                                                                                                     | 4.7 MB  00:00:00
repo id                                                                                repo name                                                                                                status
moschdb_4_local_repo                                                                       Oracle Linux 7.4 Local Repository                                                                        enabled: 4,970
repolist: 4,970
 
[root@moschdb ~]# yum info oracle-database-server-12cR2-preinstall
Loaded plugins: ulninfo
Available Packages
Name        : oracle-database-server-12cR2-preinstall
Arch        : x86_64
Version     : 1.0
Release     : 3.el7
Size        : 19 k
Repo        : moschdb_4_local_repo
Summary     : Sets the system for Oracle Database single instance and Real Application Cluster install for Oracle Linux 7
License     : GPLv2
Description : The Oracle Preinstallation RPM package installs software packages and sets system parameters required for Oracle Database single instance and Oracle Real Application Clusters installations for
            : Oracle Linux Release 7 Files affected: /etc/sysctl.conf, /boot/grub/menu.lst OR /boot/grub2/grub.cfg
            : Files added: /etc/security/limits.d/oracle-database-server-12cR2-preinstall.conf

[root@moschdb ~]# yum install oracle-database-server-12cR2-preinstall
warning: /mnt/Packages/bind-libs-9.9.4-50.el7.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID ec551f03: NOKEY
Public key for bind-libs-9.9.4-50.el7.x86_64.rpm is not installed
Complete!
```
====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Add User "grid":

1.
```
[root@moschdb ~]# groupadd -g 54327 asmdba
[root@moschdb ~]# groupadd -g 54328 asmoper
[root@moschdb ~]# groupadd -g 54329 asmadmin
[root@moschdb ~]# useradd -u 54322 -g oinstall -G dba,asmadmin,asmdba,asmoper,racdba grid
[root@moschdb ~]# usermod -a -G  asmdba oracle

[root@moschdb ~]# id oracle
uid=54321(oracle) gid=54321(oinstall) groups=54321(oinstall),54322(dba),
54323(oper),54324(backupdba),54325(dgdba),54326(kmdba),54330(racdba),54327(asmdba)

[root@moschdb ~]# id grid
uid=54422(grid) gid=54321(oinstall) groups=54321(oinstall),54322(dba),
54330(racdba),54327(asmdba),54328(asmoper),54329(asmadmin)

[root@moschdb ~]# passwd oracle
[root@moschdb ~]# passwd grid


[root@moschdb ~]# vi /etc/security/limits.d/oracle-database-server-12cR2-preinstall.conf
# oracle-database-server-12cR2-preinstall setting for nofile soft limit is 1024
oracle   soft   nofile    1024
grid   soft   nofile    1024
# oracle-database-server-12cR2-preinstall setting for nofile hard limit is 65536
oracle   hard   nofile    65536
grid   hard   nofile    65536
# oracle-database-server-12cR2-preinstall setting for nproc soft limit is 16384
# refer orabug15971421 for more info.
oracle   soft   nproc    16384
grid   soft   nproc    16384
# oracle-database-server-12cR2-preinstall setting for nproc hard limit is 16384
oracle   hard   nproc    16384
grid   hard   nproc    16384
# oracle-database-server-12cR2-preinstall setting for stack soft limit is 10240KB
oracle   soft   stack    10240
grid   soft   stack    10240
# oracle-database-server-12cR2-preinstall setting for stack hard limit is 32768KB
oracle   hard   stack    32768
grid   hard   stack    32768
# oracle-database-server-12cR2-preinstall setting for memlock hard limit is maximum of 128GB on x86_64 or 3GB on x86 OR 90 % of RAM
oracle   hard   memlock    134217728
grid   hard   memlock    134217728
# oracle-database-server-12cR2-preinstall setting for memlock soft limit is maximum of 128GB on x86_64 or 3GB on x86 OR 90% of RAM
oracle   soft   memlock    134217728
grid   soft   memlock    134217728
```
====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Install Grid Infrastructure:

1. Ensure the Oracle Linux version is 6 or higher.
```
[root@moschdb ~]# cat /etc/*release*

```
-----------------------------------------
2. Ensure the Oracle Linux Kernel version is 2.6.18 or higher.
```
[root@moschdb ~]# uname -r

[root@moschdb ~]# cat /sys/block/${ASM_DISK}/queue/scheduler
[root@moschdb ~]# cat /sys/block/sdb/queue/scheduler
noop [deadline] cfq
 
//Check 4GB Physical memory or more:
[root@moschdb ~]# grep MemTotal /proc/meminfo
MemTotal:        8173848 kB

//Swap space equals to RAM (up to 16GB):
[root@moschdb ~]# grep SwapTotal /proc/meminfo
SwapTotal:      16777212 kB

//determine the available RAM and swap space:
[root@moschdb ~]# free
              total        used        free      shared  buff/cache   available
Mem:        8173848      127304     7751100        8756      295444     7819872
Swap:      16777212           0    16777212

//determine the amount of free disk space on the system:
[root@moschdb ~]# df -h
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        3.9G     0  3.9G   0% /dev
tmpfs           3.9G     0  3.9G   0% /dev/shm
tmpfs           3.9G  8.6M  3.9G   1% /run
tmpfs           3.9G     0  3.9G   0% /sys/fs/cgroup
/dev/sda3        83G  7.2G   76G   9% /
/dev/sr0        4.6G  4.6G     0 100% /mnt
/dev/sda1       509M  141M  369M  28% /boot
tmpfs           799M     0  799M   0% /run/user/0

//2GB disk space for temporary directory (or more):
[root@moschdb ~]# df -h /tmp
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda3        83G  7.2G   76G   9% /
-----------------------------------------
[root@moschdb ~]# mkdir -p /u01/app/12.2.0/grid
[root@moschdb ~]# chown -R grid:oinstall /u01
[root@moschdb ~]# chmod -R 775 /u01/

[root@moschdb ~]# mkdir -p /tmp
[root@moschdb ~]# chmod 1777 /tmp
```
-----------------------------------------

6. Unzip quietly:
```
[root@moschdb ~]# cd /u01/app/12.2.0/grid
[root@moschdb grid]# unzip -q /root/linuxx64_12_2_0_1_grid_home.zip

[root@moschdb grid]# export ORACLE_HOME=/u01/app/12.2.0/grid
[root@moschdb grid]# export ORACLE_BASE=/tmp

[root@moschdb grid]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   99G  0 disk
├─sda1   8:1    0  512M  0 part /boot
├─sda2   8:2    0   16G  0 part [SWAP]
└─sda3   8:3    0 82.5G  0 part /
sdb      8:16   0  100G  0 disk
sr0     11:0    1  4.6G  0 rom  /mnt

--------
//Hint:
// Use fdisk to partition disks.
[root@moschdb grid]# fdisk /dev/sdb
Command (m for help): m
Command (m for help): p
Command (m for help): n
	e	extended
	p	primary partition (1-4)
select (default p):
Partition number (1-4, default 1):
First sector (2048-209715199, default 2048):
Using default value 2048
Last sector, +sectors or +size{K,M,G} (2048-209715199, default 209715199):
Using default value 209715199
Partition 1 of type Linux and of size 100 GiB is set

Command (m for help): w


// Give Lable to each partition using "asmcmd afd_label".
[root@moschdb grid]# cd /u01/app/12.2.0/grid/bin
[root@moschdb bin]# ./asmcmd afd_label DATA1 /dev/sdb1 --init
[root@moschdb bin]# ./asmcmd afd_lslbl '/dev/sd*'
------------------------
Label Duplicate  Path
========================
DATA1            /dev/sdb1


[root@moschdb bin]# ls -alrt /dev/oracleafd/disks/
total 4
drwxr-xr-x. 3 root root 60 Mar 10 15:13 ..
-rwxrwx---. 1 root root 23 Mar 10 15:13 DATA1
drwxrwx---. 2 root root 60 Mar 10 15:13 .

//create a udev rule to change the disks owner to grid:asmadmin:
// Check asm disk with udevadm info
[root@moschdb bin]# udevadm info /dev/sdb1 | grep oracleasm
E: ID_FS_TYPE=oracleasm
 
// Create asm udev rule to change disk owner
[root@moschdb bin]# cat > /etc/udev/rules.d/99-oracleasm.rules <<EOF
KERNEL=="sdb*", SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="oracleasm", OWNER="grid", GROUP="asmadmin", MODE="0660"
EOF

// Reload udev rules
[root@moschdb bin]# udevadm control --reload-rules && udevadm trigger

// Check if rule is applied
[root@moschdb bin]# ls -l /dev/sd*
brw-rw---- 1 root disk 		8,  0 Aug 18 08:55 /dev/sda
brw-rw---- 1 root disk 		8,  1 Aug 18 08:55 /dev/sda1
brw-rw---- 1 root disk 		8,  2 Aug 18 08:55 /dev/sda2
brw-rw---- 1 root disk 		8,  3 Aug 18 08:55 /dev/sda3
brw-rw---- 1 root disk 		8, 16 Aug 18 08:55 /dev/sdb
brw-rw---- 1 grid asmadmin 	8, 17 Aug 18 08:55 /dev/sdb1

[root@moschdb bin]# unset ORACLE_BASE

[root@moschdb ~]# chown -R grid:oinstall /u01

[root@moschdb ~]# yum localinstall /u01/app/12.2.0/grid/cv/rpm/cvuqdisk-1.0.10-1.rpm
Complete!
```
-----------------------------------------
9. Login as "grid".
```
[oracle@moschdb ~]$ vi .bash_profile
umask 022
export TMP=/tmp
export TMPDIR=/tmp

[oracle@moschdb ~]$ . ./.bash_profile

[grid@moschdb ~]$ umask
0022
[grid@moschdb ~]$ env | more

[grid@moschdb ~]$ ulimit -Sn
1024
[grid@moschdb ~]$ ulimit -Hn
65536
[grid@moschdb ~]$ ulimit -Su
16384
[grid@moschdb ~]$ ulimit -Hu
16384
[grid@moschdb ~]$ ulimit -Ss
10240
[grid@moschdb ~]$ ulimit -Hs
32768

[grid@moschdb ~]$ cd /u01/app/12.2.0/grid

[grid@moschdb grid]$ ./runcluvfy.sh stage -pre hacfg -fixupnoexec

[grid@moschdb grid]$ ./gridSetup.sh
```
-----------------------------------------
10. 
```
[Wizard: configuration option]: 
"configure oracle grid infrastructure for a standalone server (Oracle Restart)"

[Wizard: create ASM Disk Group]:
Disk group name: "DATA" 	[As shahkar]
Redundancy: "External" 		[As shahkar] (https://docs.oracle.com/en/database/oracle/oracle-database/12.2/ostmg/mirroring-diskgroup-redundancy.html#GUID-76B31808-7017-4299-8CC2-EDD9FFEC4B37)
Allocation Unit Size: "4MB"	[As shahkar]
select Disks: Disk Path "/dev/sdb1"
Configure Oracle ASM Filter Driver: "Checked"

[Wizard: ASM Password]:
Select "Use same passwords for these accounts" = SYS123sys

[Wizard: Management Options]:
Register with ENterprise Manager (EM) Cloud Control: "NOT Checked"

[Wizard: Operating System Groups]:
Oracle ASM Administrator (OSASM) Group: "asmadmin"
Oracle ASM DBA (OSDBA for ASM) Group: "asmdba"
Oracle ASM Operator (OSOPER for ASM) Group (Optional): "asmoper"
click "Next"

[Wizard: Installation Location]:
Oracle base: "/u01/app/12.2.0"
Software location: "/u01/app/12.2.0/grid"

[Wizard: Create Inventory]:
Inventory Directory: "/u01/app/oraInventory"

[Wizard: Root script execution]:
Automatically run configuration scripts: "Checked" -> "Use root user credential"

[Wizard: Install Product]:
click "Install"
press "YES"
```
====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Install Database Software:

0. Note:Do not put the oraInventory directory under the Oracle base directory for a new installation:
[root@moschdb ~]# cat /etc/oraInst.loc
inventory_loc=/u01/app/oraInventory
inst_group=oinstall
-----------------------------------------
1.
```
[root@moschdb ~]# mkdir -p /u01/app/oracle
[root@moschdb ~]# chown oracle:oinstall /u01/app/oracle
```
-----------------------------------------
2. Unzip quietly:
```
[root@moschdb ~]# mkdir -p /u01/app/software/database
[root@moschdb ~]# chown -R oracle:oinstall /u01/app/software/database
[root@moschdb ~]# cd /u01/app/software/database

[root@moschdb database]# unzip -q /root/linuxx64_12_2_0_1_database.zip
[root@moschdb database]# chown -R oracle:oinstall /u01/app/software/database
```
-----------------------------------------
3. Disable Firewall and Selinux:
```
[root@moschdb dbhome_1]# systemctl stop firewalld
[root@moschdb dbhome_1]# systemctl disable firewalld

[root@moschdb dbhome_1]# cat /etc/sysconfig/selinux
SELINUX=enforcing
SELINUXTYPE=targeted

[root@moschdb dbhome_1]# vi /etc/sysconfig/selinux
SELINUX=disabled
SELINUXTYPE=targeted

--------
//Hint:
[root@db1 database]# getenforce
Enforcing
[root@db1 database]# setenforce 0
[root@db1 database]# getenforce
Permissive

In this case, there is no need to reboot.
--------

[root@moschdb dbhome_1]# reboot
```
-----------------------------------------
4. 
-- Login as "oracle":
```
[oracle@moschdb ~]$ vi .bash_profile
umask 022
export TMP=/tmp
export TMPDIR=/tmp

[oracle@moschdb ~]$ . ./.bash_profile

[oracle@moschdb ~]$ umask
0022
[oracle@moschdb ~]$ env | more

[oracle@moschdb ~]$ ulimit -Sn
1024
[oracle@moschdb ~]$ ulimit -Hn
65536
[oracle@moschdb ~]$ ulimit -Su
16384
[oracle@moschdb ~]$ ulimit -Hu
16384
[oracle@moschdb ~]$ ulimit -Ss
10240
[oracle@moschdb ~]$ ulimit -Hs
32768

[oracle@moschdb ~]$ cd /u01/app/software/database/database

[oracle@moschdb ~]$ ./runInstaller
```
-----------------------------------------
5. 
[Wizard: Configure Security Updates]:
Email: "Empty"
I wish to receive security updates ia My Oracle Support: "NOT Checked"
click "Next"
press "YES"

[Wizard: Installation Option]:
//"Create and configure a database"
"Install database software only"

[Wizard: System Class]:
//"Server class"

[Wizard: Database Installation Options]:
"Single instance database installation"


[Wizard: Install Type]:
//"Advanced install"

[Wizard: Database Edition]:
"Enterprise Edition (7.5GB)"

[Wizard: Installation Location]:
Oracle base: "/u01/app/oracle"
Software location: "/u01/app/oracle/product/12.2.0/dbhome_1"

[Wizard: Configuration Type]:
//"General Purpose / Transaction Processing"

[Wizard: Database Identifiers]:
/*Global database name: "orcl"
Oracle system identiifer (SID): "moschdb"
Create as Container database: "NOT Checked"
*/

[Wizard: Configuration Options]:
/*	- Memory:
		Enable Automatic Memory Managemnet: "NOT Checked"
		Allocate memory: "75%" (SGA target=4473 MB, 
								PGA aggregate target=1491 MB, 
								Target database memory=5964 MB)
	- Character sets:
		"Use Unicode (AL32UTF8)"
	- Sample schemas:
		Install sample schemas in the database: "Checked / NOT Checked"
*/

[Wizard: Database Storage]:
//"Oracle Automatic Storage Management"

[Wizard: Management Options]:
//Register with Enterprise Manager (EM) Cloud Control: "NOT Checked"

[Wizard: Recovery Options]:
//Enable Recovery: "Checked" -> "Oracle Automatic Storage Management"

[Wizard: ASM Disk Group]:
//select "DATA"

[Wizard: Schema Passwords]:
//"Use the same password for all accounts" = SYS123sys

[Wizard: Operating System Groups]:
Database Administrator (OSDBA) group: "dba"
Database Operator (OSOPER) group (Optional): "oper"
Database Backup and Recovery (OSBACKUPDBA) group: "backupdba"
Data Guard administrative (OSDGDBA) group: "dgdba"
Encryption Key Management administrative (OSKMDBA) gorup: "kmdba"
Real Application Cluster administrative (OSRACDBA) group: "racdba"

-----------------------------------------
6. Login as "root" and run the script:
```
[root@moschdb ~]# /u01/app/oracle/product/12.2.0/dbhome_1/root.sh

	- Press "Enter"
	- Do you want to setup Oracle Trace File Analyzer (TFA) now ? yes|[no] : yes
```
====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Create ASM Diskgroups:

1. Login as "root":

2. 
```
[root@moschdb grid]# export ORACLE_HOME=/u01/app/12.2.0/grid
[root@moschdb grid]# export ORACLE_BASE=/tmp

[root@moschdb grid]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   99G  0 disk
├─sda1   8:1    0  512M  0 part /boot
├─sda2   8:2    0   16G  0 part [SWAP]
└─sda3   8:3    0 82.5G  0 part /
sdb      8:16   0  100G  0 disk
└─sdb1   8:17   0  100G  0 part
sdc      8:32   0   30G  0 disk
sr0     11:0    1  4.6G  0 rom  /mnt

// Use fdisk to partition disks.

[root@moschdb grid]# fdisk /dev/sdc
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



// Give Lable to each partition using "asmcmd afd_label".
[root@moschdb grid]# cd /u01/app/12.2.0/grid/bin
[root@moschdb bin]# ./asmcmd afd_label FRA1 /dev/sdc1
[root@moschdb bin]# ./asmcmd afd_lslbl '/dev/sd*'
----------------------------
Label Duplicate  Path       
============================
DATA1             /dev/sdb1 
FRA1              /dev/sdc1 


[root@moschdb bin]# ls -alrt /dev/oracleafd/disks/
total 8
drwxrwxr-x 3 grid asmadmin 80 Apr  7 19:14 ..
-rwxrwx--- 1 grid oinstall 10 Apr  7 19:14 DATA1
-rwxrwx--- 1 grid oinstall 10 Apr  8 14:33 FRA1
drwxrwx--- 2 grid asmadmin 80 Apr  8 14:33 .

//create a udev rule to change the disks owner to grid:asmadmin:
// Check asm disk with udevadm info
[root@moschdb bin]# udevadm info /dev/sdc1 | grep oracleasm
E: ID_FS_TYPE=oracleasm
 
// Create asm udev rule to change disk owner
[root@moschdb bin]# vi /etc/udev/rules.d/99-oracleasm.rules
KERNEL=="sdc*", SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="oracleasm", OWNER="grid", GROUP="asmadmin", MODE="0660"


// Reload udev rules
[root@moschdb bin]# udevadm control --reload-rules && udevadm trigger

// Check if rule is applied
[root@moschdb bin]# ls -l /dev/sd*
brw-rw---- 1 root disk     8,  0 Apr  8 14:37 /dev/sda
brw-rw---- 1 root disk     8,  1 Apr  8 14:37 /dev/sda1
brw-rw---- 1 root disk     8,  2 Apr  8 14:37 /dev/sda2
brw-rw---- 1 root disk     8,  3 Apr  8 14:37 /dev/sda3
brw-rw---- 1 root disk     8, 16 Apr  8 14:37 /dev/sdb
brw-rw---- 1 grid asmadmin 8, 17 Apr  8 14:40 /dev/sdb1
brw-rw---- 1 root disk     8, 32 Apr  8 14:37 /dev/sdc
brw-rw---- 1 grid asmadmin 8, 33 Apr  8 14:40 /dev/sdc1

[root@moschdb bin]# unset ORACLE_BASE
```
------------------------------------------------
3. 
Login as "grid":
```
[grid@moschdb ~]$ /u01/app/12.2.0/grid/bin/asmca
```
4. 
select the "Disk Groups" and click "Create".

Create a new diskgroup for "fast recovery".
Disk Group Name: "FRA"
Redundancy: "External (None)"
Allocation Unit Size (MB): "4"
Select "Show Eligible"
Select "AFD: FRA1"
Press "OK"

====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Create Pluggable Databases:

1. Login as "oracle":
```
[oracle@moschdb ~]$ /u01/app/oracle/product/12.2.0/dbhome_1/bin/dbca
```
2. [Wizard: Database Operation]:
Select "Create Database"

3. [Wizard: Creation Mode]:
Select "Advanced Configuration"

4. [Wizard: Database Storage]:
Database Type: "Oracle Single Instance database"
Select "General Purpose or Transaction Processing"

5. [Wizard: Database Identification]:
Global database name: "orcl"
Oracle system identiifer (SID): "moschdb"
Create as Container database: "NOT Checked"

6. [Wizard: Storage Option]:
Select "Use following for the database storage attributes"
Database files storage type: "Automatic Storage Management (ASM)"
Database files location: "+DATA/{DB_UNIQUE_NAME}"
Use Oracle-Managed Files (OMF): "Checked"

7. [Wizard: Fast Recovery Option]:
Specify Fast Recovery Area: "NOT Checked"
Enable archivung: "NOT Checked"

8. [Wizard: Network Configuration]:
Select "LISTENER"
Create a new listener: "NOT Checked"

9. [Wizard: Data Vault Option]:
Configure Oracle Database Vault: "NOT Checked"
Configure Oracle Label Security: "NOT Checked"

10. [Wizard: Configuration Options]:
- Memory:
	Enable Automatic Memory Managemnet: "NOT Checked"
	Allocate memory: "75%" (SGA target=4473 MB, 
							PGA aggregate target=1491 MB, 
							Target database memory=5964 MB)
- Sizing:
	Process: "320"
- Character sets:
	"Use Unicode (AL32UTF8)"
- Connection mode:
	Select "Dedicated server mode"
- Sample schemas:
	Add sample schemas to the database: "Checked / NOT Checked"

11. [Wizard: Management Options]:
Configure Enterprise Manager (EM) database express: "NOT Checked"
Register with Enterprise Manager (EM) Cloud Control: "NOT Checked"

12. [Wizard: User Credentials]:
Select "Use the same administrative password for all accounts" = SYS123sys

13. [Wizard: Creation Option]:
Create database: "Checked"
Save as a database template: "NOT Checked"
Generate database creation scripts: "NOT Checked"

-----------------------------------------
14. Installation was Successful:

	Global Database Name:			orcl
	System identifier(SID):			moschdb
	Server Parameter File Name:		+DATA/ORCL/PARAMETERFILE/spfile.266.1034706457

====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Bash Profile Configuration:

1. Login as "oracle":
```
[oracle@moschdb ~]$ vi .bash_profile
# .bash_profile
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs
PATH=$PATH:$HOME/.local/bin:$HOME/bin
export PATH

umask 022
export TMP=/tmp
export TMPDIR=/tmp
export TZ=Asia/Tehran
#export TZ=GMT
export ORACLE_HOSTNAME=moschdb.mosch.co
export ORACLE_UNQNAME=moschdb
export DB_UNIQUE_NAME=moschdb
export ORACLE_SID=moschdb
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/12.2.0/dbhome_1

#export TNS_ADMIN=$GRID_HOME/network/admin
export PATH=$ORACLE_HOME/bin:$PATH
export PATH=/usr/sbin:$PATH

# Alias
#alias asmcmd='rlwrap asmcmd'
#alias sqlplus='rlwrap sqlplus'
#alias rman='rlwrap rman'
alias alert='tail $ORACLE_BASE/diag/rdbms/$ORACLE_UNQNAME/$ORACLE_SID/trace/alert_$ORACLE_SID.log'
alias sqlp='sqlplus "/ as sysdba"'
```
-----------------------------------------
2. Activate the changes in the current shell:
```
[oracle@moschdb ~]$ source .bash_profile
```
-----------------------------------------
3. Login as "grid":
```
[grid@moschdb ~]$ vi .bash_profile
# .bash_profile
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs
PATH=$PATH:$HOME/.local/bin:$HOME/bin
export PATH

umask 022
export TMP=/tmp
export TMPDIR=/tmp
export TZ=Asia/Tehran
#export TZ=GMT
export ORACLE_HOSTNAME=moschdb.mosch.co
#export ORACLE_UNQNAME=moschdb
#export DB_UNIQUE_NAME=moschdb
export ORACLE_SID=+ASM
export ORACLE_BASE=/u01/app/12.2.0
export ORACLE_HOME=$ORACLE_BASE/grid
#export TNS_ADMIN=$ORACLE_HOME/network/admin
export PATH=$ORACLE_HOME/bin:$PATH
export PATH=/usr/sbin:$PATH

# Alias
#alias asmcmd='rlwrap asmcmd'
#alias sqlplus='rlwrap sqlplus'
#alias rman='rlwrap rman'
alias sqlp='sqlplus "/ as sysdba"'
```
-----------------------------------------
4. Activate the changes in the current shell:
```
[grid@moschdb ~]$ source .bash_profile
```
====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Set Format of SQL:
```
SQL> alter session set nls_calendar=gregorian;
SQL> alter session set nls_date_format='DD-MON-YY HH24:MI:SS';

```
====================================================================================
------------------------------------------------------------------------------------
====================================================================================

