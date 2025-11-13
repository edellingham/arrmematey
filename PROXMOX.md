# 🚀 Proxmox LXC Deployment

Deploy Arrmematey to Proxmox LXC container with a single command!

## 🎯 Single-Line Deployment

**Run this on your Proxmox host:**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/deploy.sh)"
```

That's it! The script will:
- Download from GitHub automatically
- Launch interactive deployment
- Configure storage passthrough
- Create optimal LXC container
- Install Docker and Arrmematey

## 🏴‍☠️ Deployment Features

### 🗄️ **Interactive Storage Selection**
- Auto-detects common storage locations
- Interactive drive selection interface
- Custom path support
- Proper permissions and shared mount flags

### 🚀 **Container Configuration**
- Template selection (Ubuntu/Debian)
- Resource allocation (CPU, RAM, storage)
- Network bridge configuration
- Nested virtualization enabled

### 🔧 **Automated Setup**
- Docker installation and configuration
- User account creation with proper permissions
- Arrmematey auto-deployment
- Storage mounts configured and working

## 📁 Storage Passthrough Options

### 🎬 **Media Storage**
Options detected automatically:
- `/mnt/media` - Common media mount
- `/mnt/tv`, `/mnt/movies`, `/mnt/music` - Separate media types
- `/home/user/Media` - User's media library
- `/data` - General storage drive

### 📥 **Download Storage**
- `/mnt/downloads` - Download staging area
- `/home/user/Downloads` - User's downloads
- `/temp` - Temporary downloads

### 💾 **Config Backup**
- `/home/user/arrmematey-config` - User config backup
- `/mnt/config/arrmematey` - System config backup
- Custom paths supported

## 🔧 Container Resources

### **Default Configuration**
- **Container ID**: 200
- **Hostname**: arrmematey
- **CPU Cores**: 4
- **Memory**: 4GB RAM, 2GB swap
- **Disk**: 32GB
- **Network**: vmbr0 (customizable)

### **Storage Mounts**
Generated as:
```bash
--mp0 /mnt/media:/home/ed/Media,shared=1 \
--mp1 /mnt/downloads:/home/ed/Downloads,shared=1 \
--mp2 /mnt/arrmematey-config:/home/ed/Config,shared=1
```

## 🛠️ Advanced Features

### **Nested Virtualization**
- Enabled for Docker container support
- Proper security context
- Performance optimized

### **Network Configuration**
- Bridge networking with firewall
- Port forwarding ready
- Static IP optional

### **Security Features**
- Unprivileged container for better isolation
- Proper UID/GID mapping
- Storage access with permissions

## 🎯 Usage Examples

### **Interactive Deployment**
```bash
# Run on Proxmox host - will guide through all options
bash -c "$(curl -fsSL https://raw.githubusercontent.com/edellingham/arrmematey/main/deploy.sh)"
```

### **What You'll Be Asked**
1. **Storage Selection** - Choose media/downloads/config locations
2. **Container ID** - Choose LXC container number
3. **Resources** - CPU, RAM, disk size
4. **Template** - Select Ubuntu/Debian CT template
5. **Network** - Bridge and IP configuration

### **After Deployment**
1. **Access Arrmematey**: `http://[container-ip]:8080`
2. **Configure VPN**: Add Mullvad account ID
3. **Set Up Media**: Configure Sonarr/Radarr/Lidarr
4. **Enjoy**: Your pirate crew is ready for treasure hunting!

## 🔍 Troubleshooting

### **Common Issues**

#### **Template Not Found**
```bash
# Download Ubuntu/Debian template in Proxmox web UI
# Storage > Content > Templates > Download
# Then re-run deployment script
```

#### **Storage Mount Issues**
```bash
# Ensure host paths exist
sudo mkdir -p /mnt/media
sudo chmod 755 /mnt/media

# Check permissions
ls -la /mnt/media
```

#### **Container Won't Start**
```bash
# Check container status
pct status 200

# View container logs
pct log 200
```

#### **Docker Installation Fails**
```bash
# Manually install inside container
pct exec 200 -- bash -c "apt-get update && apt-get install -y docker.io"
```

### **Container Management**
```bash
# Start container
pct start 200

# Stop container  
pct stop 200

# Access container shell
pct exec 200 -- bash

# View container info
pct config 200
```

## 🏴‍☠️ Proxmox Ready!

With this Proxmox deployment, your Arrmematey pirate crew can be deployed to any Proxmox host with:

- ✅ **One-Command Setup** - Just run the curl command
- ✅ **Interactive Configuration** - Choose your storage and resources
- ✅ **Optimized Performance** - Docker ready, storage mounted, network configured
- ✅ **Secure Deployment** - Proper permissions and isolation
- ✅ **Fully Automated** - From container creation to Arrmematey running

**🚀 Deploy your pirate crew to Proxmox with a single command!**

---

**🏴‍☠️ Arr... Me Matey! Your pirate crew is ready for Proxmox treasure hunting!**