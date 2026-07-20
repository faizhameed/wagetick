# Convenience targets for WageTick (Apple Silicon macOS)
.PHONY: install uninstall build open clean

install:
	./install.sh

uninstall:
	./uninstall.sh

build:
	WAGETICK_NO_LAUNCH=1 ./install.sh

open:
	open -a WageTick

clean:
	rm -rf build build-release
