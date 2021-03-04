#!/bin/sh

g() {
    echo ">" samba-tool group "$@"
    samba-tool group "$@"
}

u() {
    echo ">" samba-tool user "$@"
    samba-tool user "$@"
}

PW=1115Rose.

# groups
g add supervisors
g add employees
g add characters
g add bulk

# users
u create johnm "$PW" --surname=Mulligan --given-name=John
u create ckent "$PW" --surname=Kent --given-name=Clark
u create bwayne "$PW" --surname=Wayne --given-name=Bruce
u create pparker "$PW" --surname=Parker --given-name=Peter
u create bbanner "$PW" --surname=Banner --given-name=Bruce
u create tomas.gould "$PW" --surname=Gould --given-name=Tomas

# add to groups
g addmembers supervisors johnm

g addmembers employees johnm,ckent,bwayne,pparker,bbanner

g addmembers characters ckent,bwayne,pparker,bbanner,tomas.gould

#bulk
for i in $(seq 0 42); do
    u create "user${i}" "$PW" --surname=Hue-Sir --given-name="George${i}"
    g addmembers bulk "user${i}"
done

