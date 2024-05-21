LUA_VERSIONS := 5.1 5.2 5.3 5.4
LUA_DIR := /usr/share/lua
SRC_DIR := src
FILES := $(wildcard $(SRC_DIR)/*) LICENSE README.md CHANGELOG.md Makefile test.sh tests examples

.PHONY: all install uninstall test help

all: install

install:
		@for version in $(LUA_VERSIONS); do \
				dest=$(LUA_DIR)/$$version/LuaXen; \
				mkdir -p $$dest; \
				$(INSTALL) -m 644 $(FILES) $$dest; \
		done

uninstall:
		@for version in $(LUA_VERSIONS); do \
				dest=$(LUA_DIR)/$$version/LuaXen; \
				if [ -d "$$dest" ]; then \
						$(RM) -r $$dest; \
				fi \
		done

test:
		@./test.sh

help:
		@echo "Available commands:"
		@echo " make all       - Install the project"
		@echo " make install   - Install the project"
		@echo " make uninstall - Uninstall the project"
		@echo " make test      - Run tests"
		@echo " make help      - Show this help"