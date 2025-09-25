## Example: Converting `timescale/timescaledb-ha:pg17`

This example helps to illustrate some of the shortcomings of the conversion technique used by `docker2lxc`.

### Step 1. Use `docker2lxc` using the remote-invocation protocol

In this step, we use `docker2lxc` to get a compressed tarball from the Docker image, then unzip it.

This assumes that you do not have Docker installed locally or that the local system does not match the architecture of the Proxmox system. To remedy this, we can create a VM within Proxmox named `hostwithdocker` which we will use for the exporting of the filesystem using `docker2lxc`'s remote invocation protocol as follows:

```bash
# this does not require docker2lxc to be installed on the host 'hostwithdocker'
ssh hostwithdocker "$(docker2lxc timescale/timescaledb-ha:pg17)" > pgvector-pgai.tar.gz
gzip --decompress pgvector-pgai.tar.gz --stdout > pgvector-pgai.tar
```

### Step 2. Fix the filesystem

In this case, I am using Ubuntu 22 minimal as a compatible base for the Docker image above.

```bash
# download an official lxc ubuntu 22 minimal image, and uncompress it
xz --decompress --stdout ubuntu-jammy-lxcorg.tar.xz > ubuntu-jammy-lxcorg.tar
# rename the uncompressed ubuntu 22 image to act as a base of what to come
cp ubuntu-jammy-lxcorg.tar pgvector-pgai.fixed.tar
# layer the uncompressed docker2lxc image on top of it, overriding files
tar Af pgvector-pgai.fixed.tar pgvector-pgai.tar
```

Verfiy the resulting filesystem image:

```bash
# double check things happened in the right order
## first check the contents of the base image (1)
tar tf ubuntu-jammy-lxcorg.tar
## second check the contents of the docker2lxc overriding image (2)
tar tf pgvector-pgai.tar
## ensure the listing in the final image starts with (1) then with (2)
tar tf pgvector-pgai.fixed.tar
# compress the result, here you have your final template, this creates
# a file named "pgvector-pgai.fixed.tar.zst"
zstd pgvector-pgai.fixed.tar 
```

## Step 3. Adjustments

At startup I noticed that user 1000 was not called `postgres` leading to systemd services failing to start. It was called `ubuntu` (see the [Dockerfile](https://github.com/timescale/timescaledb-docker-ha/blob/2b5b87532cd86e313508178205c6b60d34167a38/Dockerfile#L42) here).

```bash
usermod --login postgres --home /home/postgres ubuntu
```

After this I was set to set the right environment using the specification in the [Dockerfile](https://github.com/timescale/timescaledb-docker-ha/blob/2b5b87532cd86e313508178205c6b60d34167a38/Dockerfile#L539C5-L549C13):

### Content of `/etc/environment`

```
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/usr/lib/postgresql/17/bin"
PGROOT=/home/postgres
PGDATA=/home/postgres/pgdata/data
PGLOG=/home/postgres/pg_log
PGSOCKET=/home/postgres/pgdata
BACKUPROOT=/home/postgres/pgdata/backup
PGBACKREST_CONFIG=/home/postgres/pgdata/backup/pgbackrest.conf
PGBACKREST_STANZA=poddb
PG_MAJOR=17
LC_ALL=C.UTF-8
LANG=C.UTF-8
PAGER=""
POSTGRES_PASSWORD="xxx"
OPENAI_API_KEY="xxx"
```

### Users and permissions

```
# groupmod -n postgres ubuntu
# usermod --password '' postgres
# sudo -i -u postgres
> sudo chown postgres:postgres /var/run/postgresql
> sudo systemctl restart pgqd.service
> sudo systemctl restart pgbouncer.service
> sudo systemctl restart postgresql.service
> mkdir ~/.ssh/ && curl https://github.com/diraneyya.keys > ~/.ssh/authorized_keys
```

And now I can SSH into this container as `postgres` using:
`ssh -X postgres@pgvectorhost`

## Step 4. Entrypoint script

As postgres, we need to run the following when the LXC container system starts (see the [Dockerfile](https://github.com/timescale/timescaledb-docker-ha/blob/2b5b87532cd86e313508178205c6b60d34167a38/Dockerfile#L586)):

```bash
/docker-entrypoint.sh postgres
```

This can be converted into a systemd service as shown below.

### Systemd service

Stored at `/etc/systemd/system/docker-entrypoint.service`

```
[Unit]
Description=Docker Entrypoint Script (docker2lxc)
After=pgqd.service

[Service]
Type=simple
Restart=always
RestartSec=4
User=postgres
ExecStart=/docker-entrypoint.sh postgres
PIDFile=/run/postgresql/docker-entrypoint.pid
EnvironmentFile=/etc/environment

[Install]
WantedBy=multi-user.target
```

And then enable and start the service using:
```
# systemctl daemon-reload
# systemctl enable docker-entrypoint
# systemctl start docker-entrypoint
```

## Step 5. Ensure the Image Works as Expected

This is an image that contains a PostgreSQL 17.4 server with extensions that are difficult to build from source, or have dependencies that are conflicting. TimescaleDB has already done the work of preparing this image and making these extensions work together which is why we went through the trouble of trying to use `docker2lxc` along with all the subsequent step to make an LXC image.

In the case of this specific image, the commands below can be used to test that the PostgreSQL server works and that the extensions we need are available to it:

```bash
ssh postgres@pgvector.proxmox
psql
postgres=# \l
postgres=# CREATE DATABASE jobs;
postgres=# GRANT ALL PRIVILEGES ON DATABASE jobs TO postgres;
postgres=# \connect jobs
You are now connected to database "jobs" as user "postgres".
aajobs=# CREATE EXTENSION IF NOT EXISTS vectorscale CASCADE;
NOTICE:  installing required extension "vector"
CREATE EXTENSION 🎉🥳🍾
aajobs=# CREATE EXTENSION IF NOT EXISTS ai CASCADE;
NOTICE:  installing required extension "plpython3u"
CREATE EXTENSION 🎉🥳🍾
```
