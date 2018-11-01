
.PHONY: install uninstall fmt test

install:
	@./install.sh

uninstall:
	@./uninstall.sh

fmt:
	@shfmt -l -w -i 2 .

test:
	@./tests.sh
