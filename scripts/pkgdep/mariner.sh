#!/usr/bin/env bash


is_repo() { sudo tdnf repolist --all | grep -q "^$1"; }


if [[ $ID == centos || $ID == rhel || $ID == rocky || $ID == mariner ]]; then
	repos=() enable=("epel" "elrepo" "elrepo-testing") add=()
	if ((${#add[@]} > 0)); then
		for _repo in "${add[@]}"; do
			sudo tdnf-config-manager --add-repo "$_repo"
		done
	fi

	if ((${#repos[@]} > 0)); then
		sudo tdnf install -y "${repos[@]}" sudo tdnf-utils
		sudo tdnf-config-manager --enable "${enable[@]}"
	fi
fi
sudo tdnf install -y build-essential
sudo tdnf install -y CUnit-devel libaio-devel openssl-devel \
	libuuid-devel libiscsi-devel ncurses-devel json-c-devel libcmocka-devel \
	clang clang-devel python3-pip
sudo tdnf install -y meson
# Minimal install
# workaround for arm: ninja fails with dep on skbuild python module
if [ "$(uname -m)" = "aarch64" ]; then
	pip3 install scikit-build
	sudo tdnf install -y cmake
	mkdir -p /tmp/bin/
	ln -s /usr/bin/cmake /tmp/bin/cmake > /dev/null 2>&1 || true
	export PATH=/tmp/bin:$PATH
fi

sudo tdnf install -y python python3-devel
#Create hard link to use in SPDK as python
if [[ ! -e /usr/bin/python && -e /etc/alternatives/python3 ]]; then
	ln -s /etc/alternatives/python3 /usr/bin/python
fi
# pip3, which is shipped with centos8 and rocky8, is currently providing faulty ninja binary
# which segfaults at each run. To workaround it, upgrade pip itself and then use it for each
# package - new pip will provide ninja at the same version but with the actually working
# binary.
#pip3 install --upgrade pip
#pip3() { /usr/local/bin/pip "$@"; }
pip3 install ninja
pip3 install meson
pip3 install pyelftools
pip3 install ijson
pip3 install python-magic
if ! [[ $ID == centos && $VERSION_ID == 7 ]]; then
	# Problem with modules compilation on Centos7
	pip3 install grpcio
	pip3 install grpcio-tools
fi
pip3 install pyyaml

# Additional dependencies for SPDK CLI 
sudo tdnf install -y python3-pexpect
# Additional dependencies for ISA-L used in compression
sudo tdnf install -y help2man
# Additional dependencies for DPDK
if ![ "$(uname -m)" = "aarch64" ]; then
	sudo tdnf install -y nasm
fi
sudo tdnf install -y libnuma-devel
# Additional dependencies for USDT
sudo tdnf install -y systemtap-sdt-devel
if [[ $INSTALL_DEV_TOOLS == "true" ]]; then
	# Tools for developers
	devtool_pkgs=(git sg3_utils pciutils bash-completion ruby-devel)
	devtool_pkgs+=( gcovr python3-pycodestyle)
	sudo tdnf install -y "${devtool_pkgs[@]}"
fi
if [[ $INSTALL_PMEM == "true" ]]; then
	# Additional dependencies for building pmem based backends
	sudo tdnf install -y libpmemobj-devel || true
fi
if [[ $INSTALL_FUSE == "true" ]]; then
	# Additional dependencies for FUSE and NVMe-CUSE
	sudo tdnf install -y fuse3-devel
fi
if [[ $INSTALL_RBD == "true" ]]; then
	# Additional dependencies for RBD bdev in NVMe over Fabrics
	sudo tdnf install -y librados-devel librbd-devel
fi
if [[ $INSTALL_RDMA == "true" ]]; then
	# Additional dependencies for RDMA transport in NVMe over Fabrics
	sudo tdnf install -y libibverbs librdmacm
fi
if [[ $INSTALL_DOCS == "true" ]]; then
	# Additional dependencies for building docs
	sudo tdnf install -y mscgen || echo "Warning: couldn't install mscgen via sudo tdnf. Please install mscgen manually."
	sudo tdnf install -y doxygen graphviz
fi
if [[ $INSTALL_DAOS == "true" ]]; then
	if [[ ($ID == centos || $ID == rocky) && $VERSION_ID =~ ^[78].* ]]; then
		sudo tdnf install -y daos-devel
	else
		echo "Skipping installation of DAOS bdev dependencies. Supported only under centos, rocky (variants 7-8)."
	fi
fi
# Additional dependencies for Avahi
if [[ $INSTALL_AVAHI == "true" ]]; then
	# Additional dependencies for Avahi
	sudo tdnf install -y avahi-devel
fi
