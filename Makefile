build: build.centos8

build.centos8:
	podman build --tag samba-centos8 -f ./Dockerfile.centos8
