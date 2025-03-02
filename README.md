# docker2lxc

`docker2lxc` is a shell script that allows you to export a Docker image as a root-filesystem tarball, which can be used as an LXC template in Proxmox.

> [!WARNING]
> This cli tool is in an early alpha stage. It is provided "as is" without warranty, and as a personal project that is in development to explore its usefulness to its creators and others in the open-source community.

## Screenshot

![screenshot of the cli tool usage](./.github/assets/screenshot.png)

## Installation

```bash
mkdir -p ~/repos && cd ~/repos
git clone https://github.com/diraneyya/docker2lxc.git
sudo make install
```

If you do not have `sudo` or if you are logged in as root, just run `make install`.

## Usage

Always invoke the tool from the machine on which you need the final LXC template to be.

We have two usage scenarios, depending on whether the machine on which the LXC template is needed has Docker installed or not.

### Docker is available

In this case, use:
```bash
docker2lxc "$image:$tag" $tarball
```

In the same way you would use:
```bash
docker pull "$image:$tag"
```

#### Example

```bash
docker2lxc timescale/timescaledb-ha pgvector-pgai-template
```

This will result in saving the template as `pgvector-pgai-template` in the same directory. Note that ending the ending `.tar.gz` is optional, and will be added anyway if omitted.

### Docker is not available

In this case, start by setting up an SSH access to another machine which has Docker and enough storage space available, then use:

```bash
ssh $hostwithdocker "$(docker2lxc $image:$tag)" > $tarball
```

> [!NOTE]
> In this usage scenario, the `docker2lxc` command is transferred and invoked on the remote (i.e. `$hostwithdocker`) using SSH, with the tarball's content being redirected and saved to a file on the machine you are working from (note that this machine, can also be a remote server, such as PVE, or the _Proxmox Virtualization Environment_)

> [!TIP]
> This usage scenario is also useful when the machine on which the LXC template needs to be stored does not have the resources (such as the storage space) for the download and the conversion of a large Docker image.

## Questions?

If you are intrigued by this work, check out the experimental branches, which will help you understand my thought process.

For any feedback, questions, or engagements, please email me at <info@orwa.tech>.
