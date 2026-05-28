# claude-code-solo-builder — propagation targets
# The repo is the source of truth; ~/.claude is a copy. Keep them in sync.

.PHONY: install check help

help:
	@echo "make install   Sync this repo into ~/.claude (run after every git pull)"
	@echo "make check     Read-only drift report (repo vs ~/.claude)"

install:
	@./install.sh

check:
	@d=$$(./install.sh --check 2>/dev/null); \
	if [ "$$d" -gt 0 ]; then \
		echo "DRIFT: $$d file(s) differ — run 'make install'"; \
		./install.sh --check >/dev/null; exit 1; \
	else \
		echo "in sync ✓"; \
	fi
