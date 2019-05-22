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

workDir=`pwd`/snow`date '+%Y%m%d'`
mkdir $workDir
cd $workDir

install_dependency
download_and_compile
