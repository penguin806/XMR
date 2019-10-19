#!/bin/bash
# Shadowsocks-Multi-User Backend Deployment for CentOS 7
# Author: Snow
# Github: @penguin806

# Abort if any command failed (return non-zero value)
# if [[ $? -ne 0 ]]; then exit 1; fi
set -e

workDir='/snow'
mkdir $workDir
cd $workDir

# Install Dependency
yum install -y wget git screen
yum -y groupinstall "Development Tools"
yum -y install python-setuptools
easy_install pip
# 20191020 Solve error: Command "python setup.py egg_info" failed with error code 1
# Solution: https://blog.csdn.net/xysoul/article/details/79195657
python -m pip install --upgrade --force pip
pip install setuptools==33.1.1

# Download libsodium
wget https://github.com/jedisct1/libsodium/archive/1.0.18-RELEASE.tar.gz -O libsodium-1.0.18.tar.gz
tar xvf libsodium-1.0.18.tar.gz && cd libsodium-1.0.18-RELEASE
./configure && make -j2 && make install
echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
ldconfig
cd $workDir

# Download ShadowsocksR (Python Ver)
git clone git://github.com/penguin806/shadowsocks-manyuser.git
cd shadowsocks-manyuser/
cp apiconfig.py userapiconfig.py
cp config.json user-config.json
pip install -r requirements.txt

# Mod Config File
sed -i "s/MU_SUFFIX = 'zhaoj.in'/MU_SUFFIX = 'microsoft.com'/" userapiconfig.py
sed -i "s/API_INTERFACE = 'modwebapi'/API_INTERFACE = 'glzjinmod'/" userapiconfig.py
sed -i "s/MYSQL_HOST = '127.0.0.1'/MYSQL_HOST = ' '/" userapiconfig.py
sed -i "s/MYSQL_USER = 'ss'/MYSQL_USER = 'sspanel'/" userapiconfig.py
sed -i "s/MYSQL_PASS = 'ss'/MYSQL_PASS = ' '/" userapiconfig.py
sed -i "s/MYSQL_DB = 'shadowsocks'/MYSQL_DB = 'sspanel'/" userapiconfig.py
