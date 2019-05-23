THIS_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ONIE := $(abspath $(THIS_DIR)/../..)

target:
	$(MAKE) -j18 -C $(ONIE)/build-config MACHINEROOT=$(ONIE)/machine/bigswitch MACHINE=$(TARGET) recovery-iso
