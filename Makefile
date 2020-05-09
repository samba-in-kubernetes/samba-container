build: build.centos8

build.centos8:
	podman build --tag centos8:samba -f ./Dockerfile.centos8
