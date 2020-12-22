#!/bin/sh
set -x

#  Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

MEM=4096
DISK="x86-64-arista-kvm-r0.disk"
DISK_SIZE=2G

if [ ! -f "$DISK" ]; then
    echo "Creating disk image..."
    qemu-img create -f qcow2 "$DISK" "$DISK_SIZE"
    mode=cdrom
else
    mode=disk
fi

# Path to ONIE installer .iso image
CDROM="../../build/images/onie-recovery-x86_64-arista_kvm-r0.iso"

# VM will listen on telnet port $KVM_PORT
KVM_PORT=9000

# VNC display to use
VNC_PORT=0

# set mode=net to boot from network adapters
# mode=net

# set firmware=uefi to boot with UEFI firmware, otherwise the system
# will boot into legacy mode.
#firmware=uefi

on_exit()
{
    rm -f $kvm_log
}

kvm_log=$(mktemp)
trap on_exit EXIT

boot=c
if [ "$mode" = "cdrom" ] ; then
    boot="order=cd,once=d"
    cdrom="-cdrom $CDROM"
elif [ "$mode" = "net" ] ; then
    boot="order=cd,once=n,menu=on"
fi

if [ "$firmware" = "uefi" ] ; then
    [ -r "$OVMF" ] || {
        echo "ERROR:  Cannot find the OVMF firmware for UEFI: $OVMF"
        echo "Please make sure to install the OVMF.fd in the expected directory"
        exit 1
    }
    bios="-bios $OVMF"
fi

sudo -E /usr/bin/kvm -m $MEM \
    -name "onie" \
    $bios \
    -boot $boot $cdrom \
    -device e1000,netdev=net0 -netdev tap,id=net0 \
    -drive file=$DISK,media=disk,if=virtio,index=0 \
    -serial telnet:localhost:$KVM_PORT,server > $kvm_log 2>&1 &

kvm_pid=$!

sleep 1.0

[ -d "/proc/$kvm_pid" ] || {
        echo "ERROR: kvm died."
        cat $kvm_log
        exit 1
}

telnet localhost $KVM_PORT

echo "to kill kvm:  sudo kill $kvm_pid"

exit 0
