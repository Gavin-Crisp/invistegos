ifneq ($(KERNELRELEASE),)
# KBuild
obj-m := invistegos.o
invistegos-y := interface.o implementation.o

else
# Makefile

default:
	$(MAKE) -f $$KERNELDIR/Makefile M=$$PWD

endif
