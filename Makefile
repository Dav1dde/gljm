export PROJECT_NAME = gljm
# include some command
include command.make

SOURCES            = src/libdjson/json.d gljm/vbo.d gljm/mesh.d gljm/util.d gljm/parser/obj.d gljm/parser/json.d gljm/parser/ply.d gljm/parser/util.d
OBJECTS            = $(patsubst %.d,$(BUILD_PATH)/%.o,    $(SOURCES))
PICOBJECTS         = $(patsubst %.d,$(BUILD_PATH)/%.pic.o,$(SOURCES))
HEADERS            = $(patsubst %.d,$(IMPORT_PATH)/%.di,  $(SOURCES))
DOCUMENTATIONS     = $(patsubst %.d,$(DOC_PATH)/%.html,   $(SOURCES))
define make-lib
    $(AR) rcs $@ $^
    $(RANLIB) $@
endef

all: $(LIBNAME_GLJM) header doc

shared-libs: $(SONAME_GLJM)

header : $(HEADERS)

doc: $(DOCUMENTATIONS)

# For build lib need create object files and after run make-lib
$(LIBNAME_GLJM): $(OBJECTS)
	$(make-lib)

# create object files
$(BUILD_PATH)/%.o : %.d
	$(DC) $(DFLAGS) $(DFLAGS_LINK) $(DFLAGS_IMPORT) -c $< $(OUTPUT)$@

# Generate Header files
$(IMPORT_PATH)/%.di : %.d
	$(DC) $(DFLAGS) $(DFLAGS_LINK) $(DFLAGS_IMPORT) -c -o- $< -Hf$@

# Generate Documentation
$(DOC_PATH)/%.html : %.d
	$(DC) $(DFLAGS) $(DFLAGS_LINK) $(DFLAGS_IMPORT) -c -o- $< -Df$@

# For build shared lib need create shared object files
$(SONAME_GLJM): $(PICOBJECTS)
	$(CC) -shared $^ -o $@

# create shared object files
$(BUILD_PATH)/%.pic.o : %.d
	$(DC) $(DFLAGS) $(DFLAGS_LINK) $(FPIC) $(DFLAGS_IMPORT) -c $< $(OUTPUT) $@ 

.PHONY: clean

clean:
	$(RM) $(OBJECTS)
	$(RM) $(PICOBJECTS)
	$(RM) $(LIBNAME_GLJM)
	$(RM) $(HEADERS)
	$(RM) $(DOCUMENTATIONS)