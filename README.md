# docker2lxc

`docker2lxc` is a shell function that converts a Docker image into a tarball (`template.tar.gz`) that can be used as an LXC template. A more descriptive name for this tool could be `docker2rootfs`, as its primary function is to export the root filesystem of a Docker image.

## Features

- Exports the root filesystem of a Docker image as a tarball.
- Creates a base template for use in LXC containers.

**Note:** This tool only handles the filesystem export. It does not configure the container. Users must manually handle the following tasks:

- Configuring the entry point for the LXC container.
- Adding necessary configuration files to the root filesystem.
- Mounting additional volumes.
- Setting up CPU, memory, and other resource limits.
- Configuring networking.

---

## Installation

To install `docker2lxc`, append the contents of `entry.sh` to your shell's run-command file (e.g., `.bashrc`, `.zshrc`, etc.):

```bash
cat entry.sh >> ~/.bashrc # for bash
```

```bash
cat entry.sh >> ~/.zshrc # for zsh
```

... or source the file to import the function when needed:
```bash
source entry.sh
```

**Note:** Ensure that you are in the same directory as the cloned repository when executing the commands above.

## Usage

### Running Locally

To use the function locally, provide the name of the Docker image (as you would with `docker pull` or `docker run`) and optionally specify the tarball's filename. By default, the output tarball is named `template.tar.gz`:

```bash
docker2lxc <image> [<output-filename.tar.gz>]
```

Example:
```bash

docker2lxc ubuntu:20.04 my-template.tar.gz
```

### Running Over SSH

You can also run `docker2lxc` on a remote machine via SSH. This is useful when:

- Docker is not installed on your local machine.
- Your local machine lacks the necessary processing power or storage.
- You need the template for a different platform or architecture than your local system.
  
To run the function over SSH:
```bash
ssh <remote-host> "$(declare -f docker2lxc); docker2lxc <image>" > <output-filename.tar.gz>
```

Example:
```bash
ssh user@remote-server "$(declare -f docker2lxc); docker2lxc ubuntu:20.04" > ubuntu-template.tar.gz
```