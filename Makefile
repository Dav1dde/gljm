# thanks to "bioinfornatics" from the #D channel on freenode for making this Makefile

# include some command
export PROJECT_NAME = gljm
include command.make
DLIB_PATH          = ./lib
IMPORT_DEST        = ./include
BUILD_PATH         = ./build
DFLAGS_IMPORT      = -I"src" -I"gljm"
DFLAGS_LINK        = $(LDFLAGS) $(LINKERFLAG)-lDerelictGL $(LINKERFLAG)-lDerelictUtil

LIBNAME_GLJM       = lib$(PROJECT_NAME)$(STATIC_LIB_EXT)
SONAME_GLJM        = lib$(PROJECT_NAME)$(DYNAMIC_LIB_EXT)

SOURCES            = src/libdjson/json.d gljm/vbo.d gljm/mesh.d gljm/util.d gljm/parser/obj.d gljm/parser/json.d gljm/parser/ply.d gljm/parser/util.d
OBJECTS            = $(patsubst %.d,%.o,$(SOURCES))
PICOBJECTS_GTKD    = $(patsubst %.o,%.pic.o,$(OBJECTS))

define make-lib
    $(AR) rcs $@ $^
    $(RANLIB) $@
endef

all: $(LIBNAME_GLJM)

shared-libs: $(SONAME_GLJM)

$(LIBNAME_GLJM): $(OBJECTS)
	$(make-lib)

$(SONAME_GLJM): $(PICOBJECTS)
	$(CC) -shared $^ $(OUTPUT) $@

%.o : %.d
	$(DC) $(DFLAGS_LINK) $(DFLAGS_IMPORT) -d -c $< $(OUTPUT)

%.pic.o : %.d
	$(DC) $(DFLAGS_LINK) $(FPIC) $(DFLAGS_IMPORT) -d -c $< $(OUTPUT)

