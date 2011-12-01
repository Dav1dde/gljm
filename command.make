ifdef SystemRoot
    OS              = "Windows"
    STATIC_LIB_EXT  = ".lib"
    DYNAMIC_LIB_EXT = ".dll"
    FixPath         = $(subst /,\,$1)
    message         = @(echo $1)
else
    ifeq ($(shell uname), Linux)
        OS              = "Linux"
        STATIC_LIB_EXT  = ".a"
        DYNAMIC_LIB_EXT = ".so"
        FixPath         = $1
        message         = @(echo \033[31m $1 \033[0;0m1)
    else ifeq ($(shell uname), Solaris)
        STATIC_LIB_EXT  = ".a"
        DYNAMIC_LIB_EXT = ".so"
        OS              = "Solaris"
        FixPath         = $1
        message         = @(echo \033[31m $1 \033[0;0m1)
    else ifeq ($(shell uname),Darwin)
        STATIC_LIB_EXT  = ".a"
        DYNAMIC_LIB_EXT = ".so"
        OS              = "Darwin"
        FixPath         = $1
        message         = @(echo \033[31m $1 \033[0;0m1)
    endif
endif

# Define command for copy, remove and create file/dir
ifeq ("$(OS)","Windows")
    RM    = del /Q
    CP    = copy /Y
    MKDIR = mkdir
else ifeq ("$(OS)","Linux")
    CP    = cp -fr
    MKDIR = mkdir -p
else ifeq ("$(OS)","Darwin")
    CP    = cp -fr
    MKDIR = mkdir -p
endif

# If compiler is not define try to find it
ifndef DC
    ifneq ($(strip $(shell which dmd 2>/dev/null)),)
        DC=dmd
    else ifneq ($(strip $(shell which ldc 2>/dev/null)),)
        DC=ldc
    else ifneq ($(strip $(shell which ldc2 2>/dev/null)),)
        DC=ldc2
    else
        DC=gdc
    endif
endif

# Define flag for gdc other
ifeq ("$(DC)","gdc")
    DFLAGS    = -O2 -fdeprecated
    LINKERFLAG= -Xlinker 
    OUTPUT    = -o $@
else
    DFLAGS    = -O -d
    LINKERFLAG= -L
    OUTPUT    = -of$@
endif

#define a suufix lib who inform is build with which compiler
ifeq ("$(DC)","gdc")
    COMPILER=gdc
else ifeq ("$(DC)","gdmd")
    COMPILER=gdc
else ifeq ("$(DC)","ldc")
    COMPILER=ldc
else ifeq ("$(DC)","ldc2")
    COMPILER=ldc
else ifeq ("$(DC)","ldmd")
    COMPILER=ldc
else ifeq ("$(DC)","dmd")
    COMPILER=dmd
else ifeq ("$(DC)","dmd2")
    COMPILER=dmd
endif

# Define relocation model for ldc or other
ifneq (,$(findstring ldc,$(DC)))
    FPIC = -relocation-model=pic
else
    FPIC = -fPIC
endif

# Add -ldl flag for linux
ifeq ("$(OS)","Linux")
    LDFLAGS += $(LINKERFLAG)-ldl
endif

# If model are not gieven take the same as current system
ARCH = $(shell arch || uname -m)
ifndef MODEL
    ifeq ("$(ARCH)", "x86_64")
        MODEL = 64
    else
        MODEL = 32
    endif
endif

ifeq ($(MODEL), 64)
    DFLAGS  += -m64
    LDFLAGS += -m64
else
    DFLAGS  += -m32
    LDFLAGS += -m32
endif

# Define var PREFIX, LIBDIR and INCLUDEDIR
ifndef PREFIX
    ifeq ("$(OS)",Windows) 
        LIBDIR = $(PROGRAMFILES)
    else ifeq ("$(OS)", Linux)
        LIBDIR = /usr/local
    else ifeq ("$(OS)", Darwin)
        LIBDIR = /usr/local
    endif
endif
ifndef LIBDIR
    ifeq ("$(OS)",Windows) 
        LIBDIR = $(PREFIX)\$(PROJECT_NAME)\lib
    else ifeq ("$(OS)", Linux)
        LIBDIR = $(PREFIX)/usr/local/lib
    else ifeq ("$(OS)", Darwin)
        LIBDIR = $(PREFIX)/usr/local/lib
    endif
endif
ifndef INCLUDEDIR
    ifeq ("$(OS)",Windows) 
        LIBDIR = $(PROGRAMFILES)\$(PROJECT_NAME)\import
    else ifeq ("$(OS)", Linux)
        LIBDIR = $(PREFIX)/include/d/$(PROJECT_NAME)
    else ifeq ("$(OS)", Darwin)
        LIBDIR = $(PREFIX)/include/d/$(PROJECT_NAME)
    endif
endif

ifndef CC
    CC = gcc
endif

export CC
export OS
export STATIC_LIB_EXT
export DYNAMIC_LIB_EXT
export COMPILER
export FixPath
export DC
export DFLAGS
export LDFLAGS
export MODEL
export FPIC
export LINKERFLAG
export OUTPUT
export PREFIX
export LIBDIR
export INCLUDEDIR
export message
export CP
export MKDIR
export MAKE        = make
export AR          = ar
export ARFLAGS     = rcs
export RANLIB      = ranlib
export ARCH