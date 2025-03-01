
install:
	@echo Creating a symbolic link - needs sudo permissions
	sudo ln -s "${PWD}/docker2lxc" /usr/local/bin

update:
	@echo Fetching latest changes from GitHub
	git pull

.PHONY: install update