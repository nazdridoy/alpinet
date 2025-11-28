# AlpiNet

**AlpiNet** is a lightweight, Alpine-based Docker image designed specifically for use as a virtual PC in GNS3. It comes pre-installed with a comprehensive suite of networking utilities and tools, making it perfect for network testing, troubleshooting, and education.

## Features

- 🐧 **Lightweight**: Based on Alpine Linux for minimal footprint
- 🛠️ **Comprehensive Toolset**: Pre-installed with essential networking utilities
- 🔧 **GNS3 Ready**: Optimized for use as a GNS3 appliance
- 💾 **Persistent Storage**: `/root` directory persists across container restarts
- 🚀 **Easy to Use**: Simple setup and deployment

## Included Tools

### Network Utilities
- **IP Tools**: `iproute2`, `iputils` (includes `arping`), `net-tools`
- **Network Testing**: `ping`, `traceroute`, `mtr`
- **Traffic Analysis**: `tcpdump`, `nmap`, `nmap-scripts`
- **Performance Testing**: `iperf`, `iperf3`
- **Network Utilities**: `curl`, `wget`, `netcat`, `socat`
- **Advanced**: `bridge-utils`, `vlan`, `ethtool`

### Firewall Tools
- **iptables**: Traditional Linux firewall (IPv4)
- **ip6tables**: IPv6 firewall
- **nftables**: Modern Linux firewall framework

### File Transfer Clients
- **lftp**: Advanced FTP/FTPS/HTTP client
- **tftp**: TFTP client for network device configuration
- **smbclient**: SMB/CIFS client for Windows file sharing

### DNS Tools
- `host`, `nslookup`, `dig` (bind-tools)

### System Utilities
- **Editors**: `vim`, `nano`
- **Terminal**: `bash`, `tmux`, `screen`
- **Monitoring**: `htop`, `procps`
- **Version Control**: `git`
- **File Tools**: `rsync`, `tar`, `gzip`, `bzip2`, `xz`
- **Utilities**: `jq`, `tree`, `less`, `grep`, `sed`, `awk`

### Python Environment
- `python3` with `pip`
- `scapy` - Powerful packet manipulation tool
- `netaddr` - Network address manipulation
- `ipython` - Enhanced interactive Python shell
- `requests` - HTTP library

## Quick Start

### Building the Docker Image

```bash
# Clone the repository
git clone https://github.com/nazdridoy/alpinet.git
cd alpinet

# Build the Docker image
docker build -t nazdridoy/alpinet:latest .

# Or build with a specific version tag
docker build -t nazdridoy/alpinet:1.0.0 .
```

### Pulling from Docker Hub

```bash
# Pull the latest version
docker pull nazdridoy/alpinet:latest

# Or pull a specific version
docker pull nazdridoy/alpinet:1.0.0
```

### Running Locally

```bash
# Run interactively
docker run -it --rm nazdridoy/alpinet:latest

# Run with persistent storage
docker run -it --rm -v alpinet-data:/root nazdridoy/alpinet:latest

# Run with network host mode (for advanced testing)
docker run -it --rm --net=host --privileged nazdridoy/alpinet:latest
```

### Using in GNS3

#### Option 1: Import the Appliance File

1. Download the `alpinet.gns3a` file from this repository
2. In GNS3, go to **File** → **Import appliance**
3. Select the `alpinet.gns3a` file
4. Follow the import wizard
5. GNS3 will automatically pull the Docker image

#### Option 2: Manual Setup

1. Build or pull the Docker image:
   ```bash
   docker pull nazdridoy/alpinet:latest
   # or
   docker build -t nazdridoy/alpinet:latest .
   ```

2. In GNS3, go to **Edit** → **Preferences** → **Docker containers**
3. Click **New** and follow the wizard:
   - Select the `nazdridoy/alpinet:latest` image
   - Set adapters to 1 (or more as needed)
   - Configure console type (typically `telnet`)

4. The AlpiNet appliance will now appear in your GNS3 device list

## Usage

### First Run

When you start AlpiNet, you'll see a welcome banner:

```
      .o.       oooo              o8o  ooooo      ooo               .   
     .888.      `888              `"'  `888b.     `8'             .o8   
    .8"888.      888  oo.ooooo.  oooo   8 `88b.    8   .ooooo.  .o888oo 
   .8' `888.     888   888' `88b `888   8   `88b.  8  d88' `88b   888   
  .88ooo8888.    888   888   888  888   8     `88b.8  888ooo888   888   
 .8'     `888.   888   888   888  888   8       `888  888    .o   888 . 
o88o     o8888o o888o  888bod8P' o888o o8o        `8  `Y8bod8P'   "888" 
                       888                                              
                      o888o                                             
                                                                        .

  AlpiNet - Lightweight Alpine-based Networking Toolbox for GNS3
  Type "alpinet-tools" for available utilities
```

### Viewing Available Tools

Run the helper command to see all available utilities:

```bash
alpinet-tools
```

### Common Use Cases

#### Network Connectivity Testing

```bash
# Check interface configuration
ip addr show
ip route show

# Test connectivity
ping -c 4 8.8.8.8
traceroute google.com
mtr -c 10 1.1.1.1
```

#### Traffic Analysis

```bash
# Capture packets
tcpdump -i eth0 -n

# Port scanning
nmap -sV 192.168.1.1

# Custom packet crafting with Scapy
python3
>>> from scapy.all import *
>>> sr1(IP(dst="8.8.8.8")/ICMP())
```

#### Performance Testing

```bash
# Server mode
iperf3 -s

# Client mode
iperf3 -c <server-ip>
```

#### HTTP Testing

```bash
# Simple GET request
curl -v https://example.com

# Download file
wget https://example.com/file.txt

# JSON parsing
curl -s https://api.example.com/data | jq '.'
```

#### Firewall Testing

```bash
# iptables - List current rules
iptables -L -n -v
ip6tables -L -n -v

# iptables - Block incoming traffic from an IP
iptables -A INPUT -s 192.168.1.100 -j DROP

# iptables - Allow specific port
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# nftables - List rules
nft list ruleset

# nftables - Create a simple firewall
nft add table inet filter
nft add chain inet filter input { type filter hook input priority 0 \; }
nft add rule inet filter input ct state established,related accept
nft add rule inet filter input tcp dport 22 accept
```

> **Note**: Firewall rules may require `--privileged` flag when running the container to have full access to netfilter.

#### File Transfer

```bash
# FTP - Connect and transfer files
lftp ftp://ftp.example.com
lftp -u username,password ftp://192.168.1.1

# FTP - One-liner download
lftp -c "get ftp://ftp.example.com/file.txt"

# TFTP - Get file from TFTP server (common for router configs)
tftp 192.168.1.1
> get router-config.cfg
> quit

# TFTP - One-liner
tftp -g -r config.bin 192.168.1.1

# SMB - List shares
smbclient -L //server -U username

# SMB - Connect to share
smbclient //server/share -U username

# SMB - Download file
smbclient //192.168.1.1/configs -U admin -c "get startup-config.txt"
```

## Configuration

### Persistent Data

The `/root` directory is designed to be persistent. When using in GNS3, this directory maintains its contents across container restarts, allowing you to:

- Save scripts and configurations
- Store logs and packet captures
- Keep custom tool installations

### Customization

You can customize the image by:

1. **Modifying the Dockerfile**: Add or remove packages as needed
2. **Creating a custom image**: Build from this base image

```dockerfile
FROM nazdridoy/alpinet:latest
RUN apk add --no-cache your-package
```

3. **Using Docker volumes**: Mount custom scripts or configurations

```bash
docker run -it --rm -v $(pwd)/scripts:/root/scripts nazdridoy/alpinet:latest
```

## Image Optimization

The image is optimized for minimal size:

- Based on Alpine Linux (~5-10 MB base)
- Multi-layer caching for efficient builds
- APK cache cleaned after installation
- Python packages installed without cache

Expected final image size: **~250-300 MB** (with all tools)

## Development

### Project Structure

```
alpinet/
├── Dockerfile              # Main Dockerfile
├── README.md              # This file
├── PACKAGES.md            # Package justification
├── LICENSE                # MIT License
├── .gitignore            # Git ignore rules
├── .dockerignore         # Docker ignore rules
├── alpinet.gns3a          # GNS3 appliance file
└── temp-ref/             # Reference files
```

### Building

```bash
# Build with default tag
docker build -t nazdridoy/alpinet:latest .

# Build with custom tag
docker build -t nazdridoy/alpinet:1.0.0 .

# Build with no cache
docker build --no-cache -t nazdridoy/alpinet:latest .
```

### Testing

```bash
# Run tests
docker run -it --rm nazdridoy/alpinet:latest /bin/bash -c 'alpinet-tools && ip addr show'

# Verify all tools are installed
docker run -it --rm nazdridoy/alpinet:latest /bin/bash -c '
  which ping && which tcpdump && which nmap && which iperf3 && echo "All tools OK"
'
```

## Publishing to Docker Hub

```bash
# Login to Docker Hub
docker login

# Tag the image (if not already tagged)
docker tag nazdridoy/alpinet:latest nazdridoy/alpinet:1.0.0

# Push to Docker Hub
docker push nazdridoy/alpinet:latest
docker push nazdridoy/alpinet:1.0.0
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on [Alpine Linux](https://alpinelinux.org/)
- Designed for [GNS3](https://www.gns3.com/)

## Maintainer

[nazDridoy](https://github.com/nazdridoy)

## Support

- **Issues**: [GitHub Issues](https://github.com/nazdridoy/alpinet/issues)
- **Discussions**: [GitHub Discussions](https://github.com/nazdridoy/alpinet/discussions)
- **GNS3 Community**: [GNS3 Community Forum](https://gns3.com/community)

---

**Made with ❤️ for the GNS3 and networking community**
