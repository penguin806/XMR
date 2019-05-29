#!/bin/bash
# Xmr-Stak Deployment for CentOS 7
# Author: Snow
# Github: @penguin806

# Abort if any command failed (return non-zero value)
# if [[ $? -ne 0 ]]; then exit 1; fi
set -e

install_dependency() {
	sudo yum -y install git
	sudo yum -y install centos-release-scl epel-release
	sudo yum -y install cmake3 devtoolset-4-gcc* hwloc-devel libmicrohttpd-devel openssl-devel make
}

_mod_source_code() {
	donateHeader='xmr-stak/xmrstak/donate-level.hpp'
	echo '#pragma once' > $donateHeader
	echo 'constexpr double fDevDonationLevel = 0.0;' >> $donateHeader
}

download_and_compile() {
	git clone https://github.com/fireice-uk/xmr-stak.git
	_mod_source_code
	mkdir xmr-stak/build
	cd xmr-stak/build
	# Build for CPU mining only
	scl enable devtoolset-4 "cmake3 .. -DCUDA_ENABLE=OFF -DOpenCL_ENABLE=OFF"
	scl enable devtoolset-4 "make install"
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

workDir=`pwd`/snow`date '+%Y%m%d'`
mkdir $workDir
cd $workDir

install_dependency
download_and_compile
mod_system_config

cd $workDir
cp -rf $workDir/xmr-stak/build/bin $workDir/target
cd $workDir/target

# Start mining
poolAddress='pool.supportxmr.com:5555'
walletAddress='43JZiGudGLDGV2fL674raDc5RpLzPJQ6RFtfVCM1uWFNTDsLpJ3Ebf26Dw6m7CM8FfDZ7TmGQoJ8HCucFk9UZnTZGPFvwfg'
workerName="`hostname`-`date '+%Y%m%d'`"
echo 'Y' | $workDir/target/xmr-stak --url $poolAddress --user $walletAddress --pass $workerName --currency monero

