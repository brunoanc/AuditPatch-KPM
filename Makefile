# Makefile for Kernel Patch Module (KPM) build system

ifeq ($(OS), Windows_NT)
    PLATFORM := windows-x86_64
else
    PLATFORM := linux-x86_64
endif

ifndef TARGET_COMPILE
	NDK_PATH := $(shell echo $(NDK_PATH))
 	export TARGET_COMPILE=$(NDK_PATH)/toolchains/llvm/prebuilt/$(PLATFORM)/bin/
endif

ifndef KP_DIR
    KP_DIR = ./KernelPatch
endif

CC = $(TARGET_COMPILE)aarch64-linux-android31-clang
LD = $(TARGET_COMPILE)ld.lld
AS = $(TARGET_COMPILE)llvm-as
OBJCOPY = $(TARGET_COMPILE)llvm-objcopy
STRIP := $(TARGET_COMPILE)llvm-strip

INCLUDE_DIRS := . include patch/include linux/include linux/arch/arm64/include linux/tools/arch/arm64/include

INCLUDE_FLAGS := $(foreach dir,$(INCLUDE_DIRS),-I$(KP_DIR)/kernel/$(dir))

CFLAGS = -I$(AP_INCLUDE_PATH) $(INCLUDE_FLAGS) -Wall -Ofast -fno-PIC -fno-asynchronous-unwind-tables -fno-stack-protector -fno-unwind-tables -fno-semantic-interposition -U_FORTIFY_SOURCE -fno-common -fvisibility=hidden

LDFLAGS  += -s

objs := kpm_audit_patch.o

all: kpm_audit_patch.kpm

kpm_audit_patch.kpm: ${objs}
	${CC}  $(LDFLAGS) -Tkpm_audit_patch.lds -r -o $@ $^
	${STRIP} -g --strip-unneeded --strip-debug --remove-section=.comment --remove-section=.note.GNU-stack $@

%.o: %.c
	${CC} $(CFLAGS) $(INCLUDE_FLAGS) -c -O2 -o $@ $<


.PHONY: clean
ifeq ($(OS), Windows_NT)
clean:
	del /Q *.o *.kpm
else
clean:
	rm -rf *.o *.kpm
endif
