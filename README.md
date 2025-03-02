# docker2lxc

`docker2lxc` is a shell script that allows you to export a Docker image as a root-filesystem tarball, which can be used as an LXC template in Proxmox.

> [!WARNING]
> **Conceptual Experiment** - This tool exists primarily to test a "novel" CLI interaction pattern. The current implementation is fragile and must eventually change. I hence invite curious developers to:
>
> - Explore the `stdout-forward-detector` and `noninteractive-export` branches in this repository.
> - Contribute ideas about the usage pattern allowing a cli tool such as this one to change its behavior based on whether it is being called or substituted/piped.
>
> The end goal is to figure out if this pattern is a good idea, if it can be implemented reliably, and eventually create a cloud-shell-script template that Platform and DevOps engineers can adapt for their own cloud cli tools.

## Demo

![terminal recording showing cli usage](./.github/assets/recording.gif)

> Note that on a Proxmox VE system, LXC templates are usually stored in the directory `/var/lib/vz/template/cache`.

## Installation

```bash
mkdir -p ~/repos && cd ~/repos
git clone https://github.com/diraneyya/docker2lxc.git
sudo make install
```

If you do not have `sudo` or if you are logged in as root, just run `make install`.

## Usage

Always invoke the tool from the machine on which you need the LXC template.

Depending on whether the machine on which the LXC template is needed has Docker installed or not, you will want to use the tool in one of two ways, as explained below.

### Usage 1: Docker is available on the machine on which the template is needed

In this case, use:
```bash
docker2lxc "$image:$tag" $tarball
```

In the same way you would use:
```bash
docker pull "$image:$tag"
```

#### Usage 1: Example

```bash
docker2lxc timescale/timescaledb-ha:pg17 pgvector-pgai-template
```

This will result in saving the template as `pgvector-pgai-template` in the same directory. Note that ending the ending `.tar.gz` is optional, and will be added anyway if omitted.

#### Usage 1: Troubleshoot

To troubleshoot incomplete invocations assign `1` or `true` to an ENV variable called `DEBUG` prior to calling:
```bash
DEBUG=1 docker2lxc "$image:$tag" $tarball
```

#### Usage 1: Cleanup

To remove all the Docker images downloaded by `docker2lxc` locally as part of this usage scenario, use this command:

```bash
docker image rm --force $(docker image ls -q --filter 'reference=*:docker2lxc')
```

### Usage 2: Docker is not available on the machine on which the template is needed

In this case, start by setting up an SSH access to another machine which has Docker and enough storage space available, then use:

```bash
ssh $hostwithdocker "$(docker2lxc $image:$tag)" > $tarball.tar.gz
```

> [!NOTE]
> In this usage scenario, the `docker2lxc` command is transferred and invoked on the remote (i.e. `$hostwithdocker`) using SSH, with the tarball's content being redirected and saved to a file on the machine you are working from (note that this machine, can also be a remote server, such as PVE, or the _Proxmox Virtualization Environment_)

> [!TIP]
> This usage scenario is also useful when the machine on which the LXC template needs to be stored does not have the resources (such as the storage space) for the download and the conversion of a large Docker image.

#### Usage 2: Example

```bash
ssh hostwithdocker "$(docker2lxc timescale/timescaledb-ha:pg17)" > pgvector-pgai-template.tar.gz
```

This will result in saving the template as `pgvector-pgai-template.tar.gz` in the current directory. Note that in this case, you must add `.tar.gz` at the end of the template filename.

#### Usage 2: Troubleshoot

To troubleshoot incomplete invocations assign `1` or `true` to an ENV variable called `DEBUG` prior to calling.

Note that in this case, this will take the following form:
```bash
ssh $hostwithdocker "$(DEBUG=1 docker2lxc $image:$tag)" > $tarball.tar.gz
```

#### Usage 2: Cleanup

To remove all the Docker images downloaded by `docker2lxc` on the remote as part of this usage scenario, use the following command:

```bash
ssh hostwithdocker "$(docker image rm --force $(docker image ls -q --filter 'reference=*:docker2lxc')"
```

## Questions?

If you are intrigued by this work, check out the experimental branches, which will help you understand my thought process.

For any feedback, questions, or engagements, please email me at <info@orwa.tech>.
