demo.prg: *.asm
	64tass -q -C -a -B -i $< -o $@

run: demo.prg
	x64 -autostartprgmode 1 -autostart-warp +truedrive +cart $<

debug: demo.prg
	c64debugger -prg $<

clean:
	$(RM) demo.prg

.PHONY: run clean
