# Docker Container & Image Management:

<div style="display:flex;align-items:center;gap:24px;">
  <img width="200" height="200" alt="AlpiNet Logo" src="https://github.com/user-attachments/assets/06fb7efb-e70e-46f6-8fee-fae7fd577431" />
  <span style="font-size:2rem;font-weight:300;color:#888;">+</span>
  <img width="200" height="200" alt="GNS3 Logo" src="https://www.gns3.com/assets/custom/gns3/images/logo-colour.png" />
</div>


**Using AlpiNet as a practical reference.** AlpiNet is a lightweight, Alpine Linux-based Docker image purpose-built for network testing and simulation in GNS3. This document walks through the full Docker workflow: writing a Dockerfile, building, tagging, managing images and containers, pushing/pulling from registries, and inspecting what's running. AlpiNet's own `Dockerfile` serves as the hands-on example throughout.

```
      .o.       oooo              o8o  ooooo      ooo               .   
     .888.      `888              `"'  `888b.     `8'             .o8   
    .8"888.      888  oo.ooooo.  oooo   8 `88b.    8   .ooooo.  .o888oo 
   .8' `888.     888   888' `88b `888   8   `88b.  8  d88' `88b   888   
  .88ooo8888.    888   888   888  888   8     `88b.8  888ooo888   888   
 .8'     `888.   888   888   888  888   8       `888  888    .o   888 . 
o88o     o8888o o888o  888bod8P' o888o o8o        `8  `Y8bod8P'   "888" 
                       888                                              
                      o888o  Made with ❤️ for the GNS3 community                                   
                                                                 _ @nazDridoy       
```

---

## 1. What Is a Docker Image?

A Docker image is a read-only template that packages an application and all its dependencies. It's built in layers: each instruction in a `Dockerfile` adds a new layer on top of the previous one. When you run an image, Docker creates a writable container layer on top of those read-only image layers.

```
┌─────────────────────────────────┐  ← Container Layer (writable, ephemeral)
├─────────────────────────────────┤  ← ENTRYPOINT + scripts layer
├─────────────────────────────────┤  ← Shell config + MOTD layer
├─────────────────────────────────┤  ← APK packages layer
├─────────────────────────────────┤  ← alpine:3.23 base (FROM)
└─────────────────────────────────┘
```

Key properties:
- **Immutable**: Image layers never change after they're built.
- **Portable**: The same image runs identically on any Docker host.
- **Layered**: Layers are cached and shared across images to save disk space.

---

## 2. The Dockerfile: Building an Image from Scratch

A `Dockerfile` is a plain-text recipe. Docker reads it top-to-bottom, executing each instruction in its own intermediate container, then committing the result as a layer.

### AlpiNet's Dockerfile: Annotated

```dockerfile
# AlpiNet - Lightweight Alpine-based networking toolbox for GNS3
FROM alpine:3.23
```

**`FROM`** sets the base image. Every Dockerfile must start with one. AlpiNet uses `alpine:3.23`; Alpine Linux is intentionally minimal (~5 MB), which keeps the final image small. The tag `3.23` pins the exact version so builds are reproducible.

```dockerfile
LABEL maintainer="nazDridoy <nazdridoy399@gmail.com>"
LABEL description="Lightweight Alpine-based networking toolbox for GNS3"
LABEL version="1.4.0-alp3.23"
```

**`LABEL`** adds arbitrary key-value metadata to the image. Labels don't affect behavior; they're visible via `docker inspect` and useful for automation and documentation.

```dockerfile
RUN apk --no-cache add \
    iproute2 \
    iputils \
    bind-tools \
    tcpdump \
    nmap \
    curl \
    ...
```

**`RUN`** executes a shell command during the build. Each `RUN` creates one layer. Here, all packages are installed in a **single** `RUN` using `\` line continuations. This is a best practice: it avoids creating multiple layers for related operations and keeps the history clean.

The `--no-cache` flag tells `apk` not to write the package index to disk. This removes the need for a separate `RUN rm -rf /var/cache/apk/*` step and keeps the layer leaner.

```dockerfile
RUN sed -i 's|/bin/ash|/bin/bash|g' /etc/passwd
```

Alpine's default shell is `ash`. This `RUN` replaces it with `bash` for all users, giving more familiar shell behavior (history, completion, arrays).

```dockerfile
RUN echo 'PS1="..."' >> /root/.bashrc && \
    echo 'alias ll="ls -lah"' >> /root/.bashrc
```

Bash configuration is written directly into `.bashrc`. Chaining with `&&` keeps everything in one layer.

```dockerfile
RUN echo '#!/bin/bash' > /etc/profile.d/motd.sh && \
    ...
    chmod +x /etc/profile.d/motd.sh
```

Files placed in `/etc/profile.d/` are sourced on every interactive login. This creates a welcome banner (the ASCII art "AlpiNet" logo) shown when a user opens a shell.

```dockerfile
RUN echo '#!/bin/bash' > /usr/local/bin/alpinet-tools && \
    ...
    chmod +x /usr/local/bin/alpinet-tools
```

A custom helper command `alpinet-tools` is installed into `/usr/local/bin/`, making it globally available. It prints a categorized list of all installed utilities.

```dockerfile
WORKDIR /root
```

**`WORKDIR`** sets the current directory for subsequent instructions (`RUN`, `COPY`, `CMD`, `ENTRYPOINT`) and becomes the default directory when a container starts. It's created automatically if it doesn't exist.

```dockerfile
RUN printf '#!/bin/sh\n...' > /etc/alpinet-init.sh && chmod +x /etc/alpinet-init.sh
```

The init script handles three things:
1. If running as PID 1, it re-execs through `dumb-init`, a lightweight init process that properly forwards signals and reaps zombie processes.
2. Checks for and runs a user-defined `/root/init.sh` if present (custom startup hook).
3. Starts an interactive bash login shell, or executes a passed command.

```dockerfile
VOLUME ["/root"]
```

**`VOLUME`** declares `/root` as a mount point. In GNS3, this means the home directory persists across container restarts; scripts, captures, and configurations survive even when the container is recreated.

```dockerfile
ENTRYPOINT ["/etc/alpinet-init.sh"]
```

**`ENTRYPOINT`** defines the process that runs when the container starts. Using the exec form (`["..."]` instead of a string) avoids starting a shell wrapper, so signals reach the process directly. `CMD` arguments (or anything passed after `docker run <image>`) become arguments to this entrypoint.

### Dockerfile Instruction Summary

| Instruction | Purpose |
|-------------|---------|
| `FROM` | Set base image |
| `LABEL` | Add metadata |
| `RUN` | Execute commands during build |
| `WORKDIR` | Set working directory |
| `COPY` / `ADD` | Copy files into the image |
| `ENV` | Set environment variables |
| `EXPOSE` | Document which ports the app uses |
| `VOLUME` | Declare persistent mount points |
| `ENTRYPOINT` | Define the main process |
| `CMD` | Default arguments to ENTRYPOINT |

---

## 3. Building the Image

```bash
# Basic build: tags the image as nazdridoy/alpinet:latest
docker build -t nazdridoy/alpinet:latest .

# Build with an explicit version tag
docker build -t nazdridoy/alpinet:1.4.0-alp3.23 .

# Force a fresh build, ignoring the layer cache
docker build --no-cache -t nazdridoy/alpinet:latest .
```

The `.` at the end is the **build context**: the directory Docker sends to the daemon. Everything in that directory can be referenced by `COPY` and `ADD` instructions. A `.dockerignore` file (analogous to `.gitignore`) trims what gets sent, keeping the context small.

### What Happens During a Build

1. Docker reads the `Dockerfile` top-to-bottom.
2. For each instruction, it checks the **layer cache**. If an identical instruction was run before on the same parent, it reuses that cached layer (fast).
3. If no cache hit, it spins up a temporary container, runs the instruction, and commits the result as a new layer.
4. The final image ID is the hash of the topmost layer.

```
Step 1/12 : FROM alpine:3.23
 ---> a606584aa9aa
Step 2/12 : LABEL maintainer="nazDridoy ..."
 ---> Using cache           ← cache hit
 ---> d3e7f9c12a41
Step 3/12 : RUN apk --no-cache add ...
 ---> Running in 3b8e2f1d9c0a
...
Successfully built 8f3a21bde90c
Successfully tagged nazdridoy/alpinet:latest
```

---

## 4. Image Tagging

A Docker image tag is `repository/name:version`. Tags are just labels pointing to an image ID; you can have many tags pointing to the same image.

```bash
# Tag an existing image with an additional version label
docker tag nazdridoy/alpinet:latest nazdridoy/alpinet:1.4.0-alp3.23

# Tag for a different registry
docker tag nazdridoy/alpinet:latest ghcr.io/nazdridoy/alpinet:latest
```

Tagging strategy for AlpiNet:
- `latest`: always points to the most recent stable build.
- `1.4.0-alp3.23`: encodes the app version (`1.4.0`) and the Alpine base version (`alp3.23`). This makes it clear what Alpine version the tools are compiled against.

> [!NOTE]
> `latest` is just a convention; Docker doesn't treat it specially. In production, always pin a specific version tag for reproducible deployments.

---

## 5. Image Management

### Listing Images

```bash
# List all local images
docker images

# Equivalent command
docker image ls

# Show all images including intermediates
docker images -a

# Filter by name
docker images nazdridoy/alpinet
```

Sample output:
```
REPOSITORY            TAG               IMAGE ID       CREATED        SIZE
nazdridoy/alpinet     latest            8f3a21bde90c   2 hours ago    84MB
nazdridoy/alpinet     1.4.0-alp3.23     8f3a21bde90c   2 hours ago    84MB
alpine                3.23              a606584aa9aa   3 weeks ago    8.83MB
```

Note that both `latest` and `1.4.0-alp3.23` share the same `IMAGE ID`: they are the same image with two tags.

### Removing Images

```bash
# Remove by name:tag
docker rmi nazdridoy/alpinet:latest

# Remove by image ID (removes all tags pointing to it)
docker rmi 8f3a21bde90c

# Remove all dangling (untagged) images
docker image prune

# Remove all unused images (not referenced by any container)
docker image prune -a
```

### Saving and Loading Images (Offline Transfer)

```bash
# Export image to a tar archive
docker save nazdridoy/alpinet:latest -o alpinet-latest.tar

# Load image from a tar archive on another machine
docker load -i alpinet-latest.tar
```

This is useful for air-gapped environments or transferring images to a GNS3 server without internet access.

---

## 6. Pulling and Pushing Images

### Pulling from Docker Hub

```bash
# Pull the latest tag
docker pull nazdridoy/alpinet:latest

# Pull a specific version
docker pull nazdridoy/alpinet:1.4.0-alp3.23
```

Docker checks if a newer version of the tag exists remotely. If the image is already local and up-to-date, nothing is downloaded.

### Pushing to Docker Hub

```bash
# Authenticate first
docker login

# Push the latest tag
docker push nazdridoy/alpinet:latest

# Push a specific version tag
docker push nazdridoy/alpinet:1.4.0-alp3.23
```

When pushing, Docker only uploads layers that aren't already on the registry. Shared base layers (like `alpine:3.23`) were likely already uploaded by other images, so only the AlpiNet-specific layers are transferred.

### Working with Other Registries

```bash
# Tag for GitHub Container Registry
docker tag nazdridoy/alpinet:latest ghcr.io/nazdridoy/alpinet:latest

# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u nazdridoy --password-stdin

# Push
docker push ghcr.io/nazdridoy/alpinet:latest
```

---

## 7. Container Management

A **container** is a running instance of an image. The image provides the filesystem; the container adds a writable layer on top and runs a process.

### Starting Containers

```bash
# Run interactively, remove on exit
docker run -it --rm nazdridoy/alpinet:latest

# Run with a named persistent container
docker run -it --name alpinet-lab nazdridoy/alpinet:latest

# Run with persistent /root volume
docker run -it --rm -v alpinet-data:/root nazdridoy/alpinet:latest

# Run with host networking (for advanced packet capture)
docker run -it --rm --net=host --privileged nazdridoy/alpinet:latest

# Run a one-shot command without interactive shell
docker run --rm nazdridoy/alpinet:latest ping -c 4 8.8.8.8
```

Key flags:
| Flag | Effect |
|------|--------|
| `-i` | Keep STDIN open |
| `-t` | Allocate a pseudo-TTY |
| `-it` | Combined: interactive terminal |
| `--rm` | Auto-remove container on exit |
| `--name` | Assign a name instead of a random one |
| `-v` | Mount a volume |
| `--net=host` | Share the host's network stack |
| `--privileged` | Give full device access (needed for `iptables`, etc.) |

### Listing Containers

```bash
# Running containers only
docker ps

# All containers (including stopped)
docker ps -a

# Just container IDs
docker ps -q
```

### Stopping and Starting

```bash
# Gracefully stop (sends SIGTERM, waits, then SIGKILL)
docker stop alpinet-lab

# Force kill immediately
docker kill alpinet-lab

# Start a stopped container
docker start -i alpinet-lab
```

### Attaching to a Running Container

```bash
# Open an additional shell in a running container
docker exec -it alpinet-lab bash

# Run a single command in a running container
docker exec alpinet-lab ip addr show
```

`docker exec` runs a new process inside an already-running container. It does not restart the container.

### Removing Containers

```bash
# Remove a stopped container
docker rm alpinet-lab

# Force remove a running container
docker rm -f alpinet-lab

# Remove all stopped containers
docker container prune
```

### Viewing Container Logs

```bash
# Print all stdout/stderr
docker logs alpinet-lab

# Follow logs in real time
docker logs -f alpinet-lab

# Last 50 lines
docker logs --tail 50 alpinet-lab
```

---

## 8. Inspecting Images and Containers

### `docker inspect`: Full Metadata

`docker inspect` returns a JSON document with every detail about an image or container.

```bash
# Inspect an image
docker inspect nazdridoy/alpinet:latest

# Inspect a running container
docker inspect alpinet-lab

# Extract a specific field with --format
docker inspect --format='{{.Config.Entrypoint}}' nazdridoy/alpinet:latest
# Output: [/etc/alpinet-init.sh]

docker inspect --format='{{.HostConfig.NetworkMode}}' alpinet-lab
# Output: default
```

Useful fields to inspect:
| Field | What It Shows |
|-------|--------------|
| `.Config.Cmd` | Default command |
| `.Config.Entrypoint` | Entrypoint script |
| `.Config.Env` | Environment variables |
| `.Config.ExposedPorts` | Declared ports |
| `.Config.Volumes` | Declared volumes |
| `.Config.Labels` | Image labels |
| `.Mounts` | Active volume mounts |
| `.NetworkSettings` | IP, gateway, ports |
| `.State.Status` | running / exited / paused |

### `docker image inspect`: Image Layers

```bash
# View layers that make up the image
docker image inspect nazdridoy/alpinet:latest --format='{{json .RootFS.Layers}}' | jq .
```

### `docker history`: Layer Timeline

```bash
docker history nazdridoy/alpinet:latest
```

Output:
```
IMAGE          CREATED       CREATED BY                                      SIZE
8f3a21bde90c   2 hours ago   /bin/sh -c printf '#!/bin/sh\n...'             1.35kB
<missing>      2 hours ago   /bin/sh -c echo '#!/bin/bash' > /usr/local/b…  2.1kB
<missing>      2 hours ago   /bin/sh -c echo '#!/bin/bash' > /etc/profile…  1.2kB
<missing>      2 hours ago   /bin/sh -c sed -i 's|/bin/ash|/bin/bash|g'…   46B
<missing>      2 hours ago   /bin/sh -c apk --no-cache add iproute2 …      76.3MB
<missing>      3 weeks ago   /bin/sh -c #(nop)  CMD ["/bin/sh"]             0B
<missing>      3 weeks ago   /bin/sh -c #(nop) ADD file:...                 8.83MB
```

Each row is one layer. The `SIZE` column shows how much each `RUN`, `COPY`, or `ADD` contributed to the final image size. `<missing>` for base layers is normal; those IDs are tracked on the registry, not locally.

### `docker stats`: Live Resource Usage

```bash
# Stream live CPU, memory, network I/O for all containers
docker stats

# Single container, no stream
docker stats --no-stream alpinet-lab
```

### `docker system info`: Engine-Level Info

```bash
docker system info
```

Reports the Docker engine version, OS, total containers, total images, storage driver, and resource limits. Good for verifying the environment before a lab session.

```bash
# Disk usage summary
docker system df

# Verbose disk usage per object
docker system df -v
```

---

## 9. How AlpiNet Works Internally

### Boot Sequence

When GNS3 starts an AlpiNet node, it runs roughly:

```
docker run -it --net=... -v /path/to/project/nodes/alpinet:/root nazdridoy/alpinet:latest
```

The `ENTRYPOINT` is `/etc/alpinet-init.sh`, which:

1. **Detects PID 1** and re-execs through `dumb-init`. This ensures `bash` isn't PID 1. `dumb-init` acts as a true init process that forwards signals and prevents zombie processes from accumulating.
2. **Sources `/root/init.sh`** if the user created one: a startup hook for custom IP configuration, route setup, or service starts.
3. **Starts `bash -i -l`** (interactive login shell). The `-l` flag causes bash to source `/etc/profile`, which includes `/etc/profile.d/motd.sh`, printing the welcome banner.

### Persistence via Volumes

AlpiNet declares `VOLUME ["/root"]`. In GNS3, each node gets its own persistent directory on the host mapped to `/root` inside the container. This means:
- Installed scripts survive node stops and restarts.
- Packet captures saved to `/root` persist between sessions.
- A user's `/root/init.sh` is re-executed automatically on each start.
- Manually installed tools (`apk add python3`) persist because APK writes to the container layer, but since `/root` is the working area, user data is safe.

### Network Interfaces

GNS3 creates `veth` (virtual ethernet) pairs and attaches them to the container's network namespace. AlpiNet sees them as standard `eth0`, `eth1`, etc. interfaces, exactly like a physical PC. `iproute2` (`ip addr`, `ip route`) and `net-tools` (`ifconfig`, `route`) are both available for configuration.

### Why Alpine?

| Factor | Alpine Linux | Ubuntu/Debian |
|--------|-------------|---------------|
| Base size | ~5 MB | ~70–100 MB |
| Package manager | `apk` (fast, dependency-light) | `apt` |
| Default shell | `ash` (switched to `bash` in AlpiNet) | `bash` |
| Libc | `musl` | `glibc` |
| Final image size | ~84 MB with full toolkit | ~200–300 MB |

Alpine's `musl` libc is smaller and faster to start, making it ideal for containers that spin up frequently in a simulation environment.

### Installed Tool Categories

| Category | Tools |
|----------|-------|
| Interface & routing | `ip`, `ifconfig`, `route`, `arp`, `ethtool` |
| Connectivity testing | `ping`, `arping`, `traceroute`, `mtr` |
| Traffic analysis | `tcpdump`, `nmap` |
| Performance | `iperf`, `iperf3` |
| HTTP/Web | `curl`, `wget`, `lynx` |
| TCP/UDP | `nc` (netcat-openbsd), `socat`, `telnet` |
| DNS | `dig`, `host`, `nslookup` |
| Firewall | `iptables`, `ip6tables`, `nft` |
| File transfer | `lftp`, `tftp`, `ssh`, `scp`, `sftp`, `rsync` |
| Bridging/VLAN | `brctl`, `vconfig` |
| JSON/text | `jq`, `grep`, `sed`, `awk` |
| System | `htop`, `ps`, `free`, `tmux`, `screen` |
| Editors | `vi`, `nano` |

---

## 10. Quick Reference Cheat Sheet

### Build & Tag

```bash
docker build -t nazdridoy/alpinet:latest .
docker build -t nazdridoy/alpinet:1.4.0-alp3.23 .
docker build --no-cache -t nazdridoy/alpinet:latest .
docker tag nazdridoy/alpinet:latest nazdridoy/alpinet:1.4.0-alp3.23
```

### Image Management

```bash
docker images                          # list images
docker image ls nazdridoy/alpinet      # filter by name
docker rmi nazdridoy/alpinet:latest    # remove image
docker image prune -a                  # remove unused images
docker save image:tag -o file.tar      # export to file
docker load -i file.tar                # import from file
```

### Pull & Push

```bash
docker login
docker pull nazdridoy/alpinet:latest
docker push nazdridoy/alpinet:latest
docker push nazdridoy/alpinet:1.4.0-alp3.23
```

### Container Lifecycle

```bash
docker run -it --rm nazdridoy/alpinet:latest          # run & auto-remove
docker run -it --name lab1 nazdridoy/alpinet:latest   # named container
docker ps -a                                           # list all containers
docker stop lab1                                       # graceful stop
docker start -i lab1                                   # restart
docker exec -it lab1 bash                             # attach shell
docker rm lab1                                         # remove
docker container prune                                 # remove all stopped
```

### Inspect & Info

```bash
docker inspect nazdridoy/alpinet:latest                      # full metadata
docker history nazdridoy/alpinet:latest                      # layer history
docker logs -f lab1                                           # live logs
docker stats --no-stream lab1                                 # resource usage
docker system info                                            # engine info
docker system df                                              # disk usage
docker inspect --format='{{.NetworkSettings.IPAddress}}' lab1 # extract IP
```

---

## 11. Extending AlpiNet

### Build a Custom Image on Top

```dockerfile
FROM nazdridoy/alpinet:latest

# Add Python and networking libraries
RUN apk add --no-cache python3 py3-pip && \
    pip3 install scapy netaddr requests --break-system-packages
```

```bash
docker build -t myalpinet:custom .
```

### Mount Custom Scripts

```bash
# Mount a local scripts directory into /root/scripts
docker run -it --rm -v $(pwd)/scripts:/root/scripts nazdridoy/alpinet:latest
```

### Auto-run on Node Start (GNS3 init hook)

Create `/root/init.sh` inside the container (or in the GNS3 project volume):

```bash
#!/bin/bash
ip addr add 192.168.1.10/24 dev eth0
ip route add default via 192.168.1.1
echo "AlpiNet initialized" > /root/startup.log
```

AlpiNet's entrypoint will detect and execute this file automatically on every start.

---

> [!NOTE]
> Python is not included by default to keep the image at ~84 MB. Install it manually if needed; since `/root` is persistent, the installation survives restarts.

> [!IMPORTANT]
> Firewall tools (`iptables`, `nftables`) require the container to run with `--privileged` or specific `--cap-add` flags to access the host's netfilter subsystem.

> [!TIP]
> Run `alpinet-tools` after opening a shell to see the full categorized list of available utilities.
