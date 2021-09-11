# Install Oracle Database 19c3 with ASM on RHEL 7.6 (with 2 OS users: oracle & grid)

[stevecao.wordpress.com](https://stevecao.wordpress.com/2019/08/08/step-by-step-guide-on-installing-rac-19c-on-rhel7-6-part-1/) \
[access.redhat.com](https://access.redhat.com/documentation/en-us/reference_architectures/2017/html-single/deploying_oracle_database_12c_release_2_on_red_hat_enterprise_linux_7/index) \
[www.uxora.com](https://www.uxora.com/oracle/dba/41-install-oracle-grid-infrastructure-12cr2-for-rac) \
[www.uxora.com](https://www.uxora.com/oracle/dba/47-install-oracle-grid-infrastructure-12cr2-standalone) \
[www.oracle-wiki.net](http://www.oracle-wiki.net/startdocshowtoinstalloracle12clinuxasm#Known-Issues)

-------------------------------------------------------------------------------------
- Grid: \
    Oracle base: 		/u01/app/19.3 \
    Software location:	/u01/app/19.3/grid 

- Database: \
    Oracle base:		/u01/app/oracle \
    Software Location:	/u01/app/oracle/product/19.3/dbhome_1 

- File System: \
* --- /u01 --- /app \
	*	              | 
	*	              --- /oraInventory 
	*	              | 
	*	              --- /19.3 ---/grid
	*	              |
	*	              --- /oracle 
		*                       |
		*                     --- /dba --- /scripts
		*                       |
		*                       --- /sql
		*                       |
		*                       --- /diag
		*                       |
		*                       --- /product ---/19.3 ---/dbhome_1
		*                       |
		*                       --- /admin --- /SID 
			*                                        |
			*                                        --- /adump
			*                                        |
			*                                        --- /pfile
====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Set New Hostname:

1. Configure Hostname:
```
[root@oramain ~]# hostname moschdb19c.mosch.co
//--oratest2.shahkar.co

[root@oramain ~]# su -
Last login: Mon Feb 24 15:39:51 +0330 2020 from 192.168.72.112 on pts/0

[root@moschdb ~]# nmtui-hostname
-- set to "moschdb19c.mosch.co" -> press "OK"
-----------------------------------------
[root@moschdb ~]# vi /etc/hosts
127.0.0.1           localhost   localhost.localdomain localhost4 localhost4.localdomain4
::1                 localhost   localhost.localdomain localhost6 localhost6.localdomain6
192.168.96.157      moschdb19c  moschdb19c.mosch.co
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
875d08087bf4adb7bd42a1a629109bcba983e37a  /dev/sr0

[root@moschdb19c ~]# sha256sum LINUX.X64_193000_db_home.zip
ba8329c757133da313ed3b6d7f86c5ac42cd9970a28bf2e6233f3235233aa8d8
[root@moschdb19c ~]# sha256sum LINUX.X64_193000_grid_home.zip
d668002664d9399cf61eb03c0d1e3687121fc890b1ddd50b35dcbe13c5307d2e
```
-----------------------------------------
5. 
```
[root@moschdb ~]# mv /etc/yum.repos.d/public-yum-ol7.repo /etc/yum.repos.d/public-yum-ol7-old

[root@moschdb ~]# vi /etc/yum.repos.d/public-yum-ol7.repo
[moschdb_local_repo]
name=Oracle Linux 7.6 Local Repository
baseurl=file:///mnt/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY
gpgcheck=1
enabled=1
```
-----------------------------------------
6.
```
[root@moschdb ~]# yum clean all

[root@moschdb ~]# yum repolist all
Loaded plugins: ulninfo
moschdb_local_repo                                       | 3.6 kB     00:00
(1/2): moschdb_local_repo/group_gz                         | 144 kB   00:00
(2/2): moschdb_local_repo/primary_db                       | 5.0 MB   00:00
repo id                  repo name                                status
moschdb_local_repo       Oracle Linux 7.6 Local Repository        enabled: 5,134
repolist: 5,134
```
-----------------------------------------
7. Disable Transparent HugePages:
```
[root@moschdb ~]# cat /sys/kernel/mm/transparent_hugepage/enabled 
[always] madvise never  

-- JUST Add "numa=off transparent_hugepage=never" in GRUB_CMDLINE_LINUX
[root@moschdb ~]# vi /etc/default/grub
...
GRUB_CMDLINE_LINUX="... numa=off transparent_hugepage=never"
...

-- Regenerate the grub.cfg file and verify
[root@moschdb ~]# grub2-mkconfig -o /boot/grub2/grub.cfg
[root@moschdb ~]# grubby --info /boot/vmlinuz-3.10.0-957.el7.x86_64

[root@moschdb ~]# systemctl stop tuned.service
[root@moschdb ~]# systemctl disable tuned.service

[root@moschdb ~]# cat /sys/kernel/mm/transparent_hugepage/enabled 
always madvise [never]
```
8. Modify kernel parameters:
```
[root@moschdb ~]# vi /etc/sysctl.conf
kernel.sem = 250 32000 100 128
kernel.panic_on_oops = 1
kernel.shmmni = 4096
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
fs.file-max = 6815744
fs.aio-max-nr = 1048576
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
net.ipv4.ip_local_port_range = 9000 65500
#net.ipv4.ipfrag_high_thresh=16777216
#net.ipv4.ipfrag_low_thresh=15728640
#net.ipv4.ipfrag_time=60
#Allocate memory to HugePages large enough for the SGAs.
#vm.nr_hugepages = 1024 	#1G hugepages.
#vm.min_free_kbytes = 1024
```
9. Reload kernel parameters:
```
[root@oratest2 bin]# sysctl -p
```
====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Add Users "oracle" and "grid":

1. 
```
[root@moschdb ~]# groupadd -g 54321 oinstall
[root@moschdb ~]# groupadd -g 54322 dba
[root@moschdb ~]# groupadd -g 54323 oper

[root@moschdb ~]# groupadd -g 54324 backupdba
[root@moschdb ~]# groupadd -g 54325 dgdba
[root@moschdb ~]# groupadd -g 54326 kmdba

[root@moschdb ~]# groupadd -g 54327 asmdba
[root@moschdb ~]# groupadd -g 54328 asmoper
[root@moschdb ~]# groupadd -g 54329 asmadmin

[root@moschdb ~]# groupadd -g 54330 racdba

[root@moschdb ~]# useradd -g oinstall -G "dba,oper,asmdba,racdba,kmdba,dgdba,backupdba" -d /home/oracle -u 54321 oracle
[root@moschdb ~]# useradd -g oinstall -G "asmadmin,asmdba,asmoper,racdba,dba" -d /home/grid  -u 54329 grid

[root@moschdb ~]# id oracle
uid=54321(oracle) gid=54321(oinstall) groups=54321(oinstall),54322(dba),
54323(oper),54324(backupdba),54325(dgdba),54326(kmdba),54330(racdba),54327(asmdba)

[root@moschdb ~]# id grid
uid=54422(grid) gid=54321(oinstall) groups=54321(oinstall),54322(dba),
54330(racdba),54327(asmdba),54328(asmoper),54329(asmadmin)

[root@moschdb ~]# passwd oracle
[root@moschdb ~]# passwd grid
```
-----------------------------------------
3. Modify shell limits for users:
```
[root@moschdb ~]# vi /etc/security/limits.d/oracle_19c.conf
oracle   soft   nofile    1024
grid   soft   nofile    1024

oracle   hard   nofile    65536
grid   hard   nofile    65536

oracle   soft   nproc    16384
grid   soft   nproc    16384

oracle   hard   nproc    16384
grid   hard   nproc    16384

oracle   soft   stack    10240
grid   soft   stack    10240

oracle   hard   stack    32768
grid   hard   stack    32768

oracle   hard   memlock    134217728
grid   hard   memlock    134217728

oracle   soft   memlock    134217728
grid   soft   memlock    134217728

[root@oratest2 ~]# yum install -y yum-utils
[root@oratest2 ~]# vi /etc/yum/pluginconf.d/subscription-manager.conf
[main]
enabled=0

[root@oratest2 ~]# yum-config-manager --enable rhel-7-server-optional-rpms
Loaded plugins: product-id

[root@oratest2 ~]# yum localinstall -y compat-libstdc++-33-3.2.3-72.el7.x86_64.rpm
[root@oratest2 ~]# yum install zip unzip -y
```
4. Install Printed Packages:
```
[root@moschdb ~]# rpm -q --qf '%{NAME}-%{VERSION}-%{RELEASE} (%{ARCH})\n'  \
binutils compat-libcap1 compat-libstdc++-33 gcc gcc-c++ glibc glibc-devel ksh libgcc \
libstdc++ libstdc++-devel libaio libaio-devel libXext libXtst libX11 libXau \
libxcb libXi make sysstat libXmu libXt libXv libXxf86dga libdmx libXxf86misc \
libXxf86vm xorg-x11-utils xorg-x11-xauth nfs-utils smartmontools | grep "not installed" | awk '{print "yum install -y ",$2}'
```
5. 
```
[root@moschdb ~]# vi /etc/sysconfig/network
NOZEROCONF=yes
```
6. Verify interconnect network is reachable through ping and latency is below 1ms
```
[root@moschdb ~]# ping 192.85.85.8
```
====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Configure Oracle Linux for X11 Forwarding:

1. Open Xming on Client(Windows):
-----------------------------------------
2. Login to Server(Linux) as "oracle".
-----------------------------------------
3. download package "xorg-x11-xauth-1.0.9-1.el7.x86_64.rpm".
-----------------------------------------
4. install package:
```
[   ]$ yum localinstall xorg-x11-xauth-1.0.9-1.el7.x86_64.rpm
```
-----------------------------------------
3. start X11 forwarding:
```
//[   ]$ xhost +
```
-----------------------------------------
4. Verify Connection:
```
//[   ]$ echo $DISPLAY
//[   ]$ xlcock
//[   ]$ firefox
```
====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Install Grid Infrastructure:

1. Ensure the Oracle Linux version is 6 or higher:
```
[root@moschdb ~]# cat /etc/*release*
*/
```
-----------------------------------------
2. Ensure the Oracle Linux Kernel version is 2.6.18 or higher.
```
[root@moschdb ~]# uname -r
3.10.0-957.el7.x86_64

[root@moschdb ~]# cat /sys/block/${ASM_DISK}/queue/scheduler
[root@moschdb ~]# cat /sys/block/sdb/queue/scheduler
noop [deadline] cfq
```
-----------------------------------------
- Check 4GB Physical memory or more:
```
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
[root@moschdb ~]# mkdir -p /u01/app/19.3/grid
[root@moschdb ~]# chown -R grid:oinstall /u01
[root@moschdb ~]# chmod -R 775 /u01/

[root@moschdb ~]# mkdir -p /tmp
[root@moschdb ~]# chmod 1777 /tmp
```
-----------------------------------------
6. Unzip quietly:
```
[root@moschdb ~]# cd /u01/app/19.3/grid
[root@moschdb grid]# unzip -q /root/LINUX.X64_193000_grid_home.zip

[root@moschdb grid]# export ORACLE_HOME=/u01/app/19.3/grid
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
[root@moschdb grid]# cd /u01/app/19.3/grid/bin
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
```
-----------------------------------------
8.
```
[root@moschdb ~]# chown -R grid:oinstall /u01

[root@moschdb ~]# yum localinstall /u01/app/19.3/grid/cv/rpm/cvuqdisk-1.0.10-1.rpm
Complete!
```
-----------------------------------------
9. Login as "grid":
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

[grid@moschdb ~]$ cd /u01/app/19.3/grid

[grid@moschdb grid]$ ./runcluvfy.sh stage -pre hacfg -fixupnoexec

[grid@moschdb grid]$ ./gridSetup.sh


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
Oracle base: "/u01/app/19.3"
Software location: "/u01/app/19.3/grid"

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
```
[root@moschdb ~]# cat /etc/oraInst.loc
inventory_loc=/u01/app/oraInventory
inst_group=oinstall

[root@moschdb ~]# mkdir -p /u01/app/oracle
[root@moschdb ~]# chown oracle:oinstall /u01/app/oracle
```
-----------------------------------------
2. Unzip quietly:
```
[root@moschdb ~]# mkdir -p /u01/app/oracle/product/19.3/dbhome_1
[root@moschdb ~]# chown -R oracle:oinstall /u01/app/oracle/product/19.3/dbhome_1
[root@moschdb ~]# cd /u01/app/oracle/product/19.3/dbhome_1

[root@moschdb database]# unzip -q /root/LINUX.X64_193000_db_home.zip
[root@moschdb database]# chown -R oracle:oinstall /u01/app/oracle/product/19.3/dbhome_1
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
4. Login as "oracle":
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

[oracle@moschdb ~]$ cd /u01/app/oracle/product/19.3/dbhome_1

[oracle@moschdb ~]$ ./runInstaller
```
-----------------------------------------
5. 
```
[Wizard: Configuration Option]:
select "Setup Software Only"

[Wizard: Database Installation Options]:
"Single instance database installation"

[Wizard: Database Edition]:
"Enterprise Edition (7.5GB)"

[Wizard: Installation Location]:
Oracle base: "/u01/app/oracle"
Software location: "/u01/app/oracle/product/19.3/dbhome_1"

[Wizard: Operating System Groups]:
Database Administrator (OSDBA) group: "dba"
Database Operator (OSOPER) group (Optional): "oper"
Database Backup and Recovery (OSBACKUPDBA) group: "backupdba"
Data Guard administrative (OSDGDBA) group: "dgdba"
Encryption Key Management administrative (OSKMDBA) gorup: "kmdba"
Real Application Cluster administrative (OSRACDBA) group: "racdba"

[Wizard: Root script execution]:
Automatically run configuration scripts: "Checked" -> "Use root user credential"
```
====================================================================================
------------------------------------------------------------------------------------
====================================================================================
- Create ASM Diskgroups:

1. Login as "root":

2. 
```
[root@moschdb grid]# export ORACLE_HOME=/u01/app/19.3/grid
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
[root@moschdb grid]# cd /u01/app/19.3/grid/bin
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
KERNEL=="sdc1", SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="oracleasm", OWNER="grid", GROUP="asmadmin", MODE="0660"


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
3. Login as "grid":

4.
```
[grid@moschdb ~]$ /u01/app/19.3/grid/bin/asmca
```
5. select the "Disk Groups" and click "Create".

6. Create a new diskgroup for "fast recovery".

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
[oracle@moschdb ~]$ /u01/app/oracle/product/19.3/dbhome_1/bin/dbca
```
2.
```
[Wizard: Database Operation]:
Select "Create Database"
```
3.
```
[Wizard: Creation Mode]:
Select "Advanced Configuration"
```
4. [Wizard: Database Storage]: \
Database Type: "Oracle Single Instance database" \
Select "General Purpose or Transaction Processing"

5. [Wizard: Database Identification]: \
Global database name: "orcl" \
Oracle system identiifer (SID): "moschdb" \
Create as Container database: "NOT Checked"

6. [Wizard: Storage Option]: \
Select "Use following for the database storage attributes" \
Database files storage type: "Automatic Storage Management (ASM)" \
Database files location: "+DATA/{DB_UNIQUE_NAME}" \
Use Oracle-Managed Files (OMF): "Checked"

7. [Wizard: Fast Recovery Option]: \
Specify Fast Recovery Area: "NOT Checked" \
Enable archivung: "NOT Checked"

8. [Wizard: Network Configuration]: \
Select "LISTENER" \
Create a new listener: "NOT Checked"

9. [Wizard: Data Vault Option]: \
Configure Oracle Database Vault: "NOT Checked" \
Configure Oracle Label Security: "NOT Checked"

10. [Wizard: Configuration Options]:
- Memory:
	*	Enable Automatic Memory Managemnet: "NOT Checked"
	*	Allocate memory: "75%" (SGA target=4473 MB, 
							PGA aggregate target=1491 MB, 
							Target database memory=5964 MB)
- Sizing:
	*	Process: "320"
- Character sets:
	*	"Use Unicode (AL32UTF8)"
- Connection mode:
	*	Select "Dedicated server mode"
- Sample schemas:
	*	Add sample schemas to the database: "Checked / NOT Checked"

11. [Wizard: Management Options]: \
Configure Enterprise Manager (EM) database express: "NOT Checked" \
Register with Enterprise Manager (EM) Cloud Control: "NOT Checked"

12. [Wizard: User Credentials]: \
Select "Use the same administrative password for all accounts" = SYS123sys

13. [Wizard: Creation Option]: \
Create database: "Checked" \
Save as a database template: "NOT Checked" \
Generate database creation scripts: "NOT Checked"

14. Installation was Successful: \

	Global Database Name:			orcl \
	System identifier(SID):			moschdb \
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
export ORACLE_HOSTNAME=oratest2.shahkar.co
export ORACLE_SID=shdbtest
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/19.3/dbhome_1
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
export ORACLE_HOSTNAME=oratest2.shahkar.co
export ORACLE_SID=+ASM
export ORACLE_BASE=/u01/app/19.3
export ORACLE_HOME=$ORACLE_BASE/grid
#export TNS_ADMIN=$ORACLE_HOME/network/admin
export PATH=$ORACLE_HOME/bin:$PATH
export PATH=/usr/sbin:$PATH

# Alias
#alias asmcmd='rlwrap asmcmd'
#alias sqlplus='rlwrap sqlplus'
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
