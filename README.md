# docker2lxc

`docker2lxc` is a shell script that allows you to export a Docker image as a root-filesystem tarball, which can be used as an LXC template in Proxmox.

> [!WARNING]
> **Conceptual Experiment** - This tool exists primarily to test a "novel" CLI interaction pattern. The current implementation is fragile and will eventually need to be changed. So I invite curious developers to:
>
> - Explore the `stdout-forward-detector` and `noninteractive-export` branches in this repository.
> - Contribute ideas about the usage pattern that allows a CLI tool like this to change its behavior depending on whether it is being "sourced" or "substituted"/piped.
>
> The end goal is to figure out if this pattern is a good idea, if it can be reliably implemented, and ultimately create a cloud-shell-script template that platform and DevOps engineers can adapt for their own cloud CLI tools.

## Demo

![Terminal recording showing CLI usage](./.github/assets/recording.gif)

> Note that on a Proxmox VE system, LXC templates are typically stored in the `/var/lib/vz/template/cache` directory.

## Installation

```bash
mkdir -p ~/repos && cd ~/repos
git clone https://github.com/diraneyya/docker2lxc.git
sudo make install
```

If you do not have `sudo` or if you are logged in as root, just run `make install`.

## Usage

Always run the tool from the machine where you need the LXC template.

Depending on whether or not Docker is installed on the machine where you need the LXC template, you will want to use the tool in one of two ways, as explained below.

### Use 1: Docker is available on the machine where the template is needed

In this case, use:

```bash
docker2lxc "$image:$tag" $tarball
```

In the same way you would use:

```bash
docker pull "$image:$tag"
```

#### Use 1: Example

```bash
docker2lxc timescale/timescaledb-ha:pg17 pgvector-pgai-template
```

This will cause the template to be saved as `pgvector-pgai-template.tar.gz` in the same directory. Note that ending the last argument with `.tar.gz` is optional, and will be added to the name of the tarball archive anyway.

#### Use 1: Debugging

To debug an incomplete call to the tool, set the environment variable named `DEBUG` to `1` or `true` before calling `docker2lxc`:

```bash
DEBUG=1 docker2lxc "$image:$tag" $tarball
```

#### Use 1: Cleanup

To remove all the Docker images downloaded locally by `docker2lxc` as part of this usage scenario, use the following command:

```bash
docker image rm --force $(docker image ls -q --filter 'reference=*/?*:docker2lxc')
```

Note that this will only remove images that were pulled by `docker2lxc`.

### Use 2: Docker is not available on the machine where the template is needed

In this case, first set up an SSH access to another machine that has Docker (i.e. `$hostwithdocker`) and enough disk space, then use

```bash
ssh $hostwithdocker "$(docker2lxc $image:$tag)" > $tarball.tar.gz
```

> [!NOTE]
> In this usage scenario, the `docker2lxc' command is teleported and invoked via SSH on the remote host, with the contents of the tarball being redirected and saved to a file on the machine you are working from (which can also be an SSH-accessible remote server, such as the _Proxmox Virtualization Environment_ or PVE).

> [!TIP]
> This usage scenario is also useful if the machine on which the LXC template is to be placed does not have the resources (such as disk space) to download and convert a large Docker image.

#### Use 2: Example

```bash
ssh hostwithdocker "$(docker2lxc timescale/timescaledb-ha:pg17)" > pgvector-pgai-template.tar.gz
```

This will save the template as `pgvector-pgai-template.tar.gz` in the current directory. Note that in this case you have to add `.tar.gz` to the end of the template filename, since it is only created as a result of output forwarding in the shell.

#### Use 2: Debugging

To troubleshoot an incomplete call to the tool, set the environment variable named `DEBUG` to `1` or `true` before "substituting" the `docker2lxc` command.

This will look something like:

```bash
ssh $hostwithdocker "$(DEBUG=1 docker2lxc $image:$tag)" > $tarball.tar.gz
```

#### Use 2: Cleanup

To remove all the Docker images downloaded by `docker2lxc` on the remote, as part of this usage scenario, use the following command:

```bash
ssh hostwithdocker 'docker image rm --force $(docker image ls -q --filter "reference=*/?*:docker2lxc")'
```

Note that this will only remove images on the remote machine that were pulled by `docker2lxc`.

## Questions?

If you are interested in this work, check out the experimental branches, which will help you understand my thought process.

For feedback, questions, or to get involved, please mail me at <info@orwa.tech>.
