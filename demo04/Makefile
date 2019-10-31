demo.prg: main.asm
	64tass -q -C -a -B -i $< -o $@

run: demo.prg
	x64 -autostartprgmode 1 -autostart-warp +truedrive +cart $<

clean:
	$(RM) demo.prg

.PHONY: run clean
