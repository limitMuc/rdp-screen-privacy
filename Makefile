.PHONY: check shellcheck install uninstall

check:
	./tests/syntax.sh

shellcheck:
	shellcheck src/rdp-screen-privacy install.sh uninstall.sh scripts/*.sh tests/*.sh

install:
	sudo ./install.sh

uninstall:
	sudo ./uninstall.sh
