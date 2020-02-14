#!/bin/bash
# Xmrig Deployment for CentOS 7
# Author: Snow
# Github: @penguin806

# Abort if any command failed (return non-zero value)
# if [[ $? -ne 0 ]]; then exit 1; fi
set -e

install_dependency() {
	sudo  yum install -y epel-release git make cmake gcc gcc-c++ libstdc++-static libuv-static hwloc-devel openssl-devel
	sudo yum -y install cpulimit screen msr-tools
}

_mod_source_code() {
	donateHeader='xmrig/src/donate.h'
	echo '#ifndef __DONATE_H__' > $donateHeader
	echo '#define __DONATE_H__' >> $donateHeader
	echo 'constexpr const int kDefaultDonateLevel = 0;' >> $donateHeader
	echo 'constexpr const int kMinimumDonateLevel = 0;' >> $donateHeader
	echo '#endif' >> $donateHeader
}

download_and_compile() {
	git clone https://github.com/xmrig/xmrig.git xmrig
	_mod_source_code
	mkdir xmrig/build
	cd xmrig/build
	# Basic build
	cmake ..
	make -j$(nproc)
}

mod_system_config() {

	cp '/etc/sysctl.conf' '/etc/sysctl.conf'`date '+%Y%m%d'`'.bak'
	sed -i '/vm.nr_hugepages/d' '/etc/sysctl.conf'

	hugepagesConfFile='/etc/sysctl.d/60-hugepages.conf'
	if [ -e $hugepagesConfFile ]
	then
		cp $hugepagesConfFile $hugepagesConfFile`date '+%Y%m%d'`'.bak'
	fi
	echo 'vm.nr_hugepages=128' > $hugepagesConfFile
	sudo sysctl --system
	
	
	memlockConfFile='/etc/security/limits.d/60-memlock.conf'
	if [ -e $memlockConfFile ]
	then
		cp $memlockConfFile $memlockConfFile`date '+%Y%m%d'`'.bak'
	fi
	echo '* - memlock 262144' > $memlockConfFile
	echo 'root - memlock 262144' >> $memlockConfFile
	
	echo 'Large page support and Memlock:'
	/sbin/sysctl vm.nr_hugepages
	ulimit -l
	echo 'Relogin in the session to take effect!'
}


workDir=/snow/xmr`date '+%Y%m%d'`
mkdir -p $workDir
cd $workDir

install_dependency
download_and_compile
# mod_system_config

mkdir $workDir/target
cp $workDir/xmrig/build/xmrig $workDir/target/
cd $workDir/target

# Start mining
poolAddress='pool.supportxmr.com:443'
walletAddress='43JZiGudGLDGV2fL674raDc5RpLzPJQ6RFtfVCM1uWFNTDsLpJ3Ebf26Dw6m7CM8FfDZ7TmGQoJ8HCucFk9UZnTZGPFvwfg'
workerName="`hostname`-`date '+%Y%m%d'`"
$workDir/target/xmrig --url=$poolAddress --user=$walletAddress --pass=$workerName --keepalive --tls

