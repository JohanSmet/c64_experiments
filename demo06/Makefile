PRG_FILE = demo.prg

SOURCES = $(wildcard *.s)
DEPS= $(wildcard *.inc) 
OBJECTS = $(patsubst %.s,%.o,$(SOURCES))

%.o: %.s $(DEPS)
	ca65 -t c64 $< -o $@

all: $(OBJECTS)
	cl65 -o $(PRG_FILE) -t c64 -C c64-asm.cfg -u __EXEHDR__ $^

clean:
	$(RM) *.o $(PRG_FILE)

.PHONY: run clean debug
