.PHONY: check shellcheck extension-pack install uninstall

check:
	./tests/syntax.sh

shellcheck:
	shellcheck src/rdp-screen-privacy install.sh uninstall.sh scripts/*.sh tests/*.sh

extension-pack:
	gnome-extensions pack extension

install:
	sudo ./install.sh

uninstall:
	sudo ./uninstall.sh
