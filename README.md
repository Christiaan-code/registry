# Docker Registry Setup Guide

A secure, production-ready Docker registry setup with authentication, designed to work with Cloudflare Tunnel.

## 📋 Prerequisites

- Docker and Docker Compose installed
- Basic understanding of Docker
- (Optional) Cloudflare account for tunnel setup

## 🚀 Quick Start

### Step 1: Run the Setup Script

The easiest way to get started is to run the automated setup script:

```bash
chmod +x setup.sh
./setup.sh
```

This script will:
- Create necessary directories
- Prompt you for a username and password
- Generate authentication files
- Optionally start the registry

### Step 2: Verify Registry is Running

```bash
docker-compose ps
```

You should see the `docker-registry` container running.

### Step 3: Test the Registry

Login to your registry:
```bash
docker login localhost:5000
```

Pull, tag, and push a test image:
```bash
# Pull an image from Docker Hub
docker pull ubuntu

# Tag it for your registry
docker tag ubuntu localhost:5000/ubuntu

# Push it to your registry
docker push localhost:5000/ubuntu

# Pull it back
docker pull localhost:5000/ubuntu
```

## 📁 Project Structure

```
registry/
├── docker-compose.yml      # Docker Compose configuration
├── setup.sh               # Automated setup script
├── config/
│   └── config.yml        # Registry configuration
├── auth/                 # Authentication files (generated)
│   └── htpasswd         # User credentials
├── data/                 # Registry data storage (generated)
└── logs/                 # Log files (generated)
```

## 🔧 Manual Setup

If you prefer to set up manually:

### 1. Create Directories

```bash
mkdir -p auth data config logs
```

### 2. Generate Authentication File

Create a user (replace `admin` and `password` with your credentials):

```bash
docker run --rm --entrypoint htpasswd httpd:2 -Bbn admin password > auth/htpasswd
```

To add more users:

```bash
docker run --rm --entrypoint htpasswd httpd:2 -Bbn newuser newpassword >> auth/htpasswd
```

### 3. Start the Registry

```bash
docker-compose up -d
```

### 4. Check Logs

```bash
docker-compose logs -f
```

## 🌐 Cloudflare Tunnel Setup

To make your registry accessible via Cloudflare Tunnel:

### 1. Install Cloudflare Tunnel (cloudflared)

```bash
# macOS
brew install cloudflare/cloudflare/cloudflared

# Linux
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
```

### 2. Authenticate with Cloudflare

```bash
cloudflared tunnel login
```

### 3. Create a Tunnel

```bash
cloudflared tunnel create docker-registry
```

### 4. Configure the Tunnel

Create `cloudflared-config.yml`:

```yaml
tunnel: <your-tunnel-id>
credentials-file: /path/to/credentials.json

ingress:
  - hostname: registry.yourdomain.com
    service: http://localhost:5000
  - service: http_status:404
```

### 5. Route DNS

```bash
cloudflared tunnel route dns docker-registry registry.yourdomain.com
```

### 6. Run the Tunnel

```bash
cloudflared tunnel run docker-registry
```

Or run as a service:

```bash
cloudflared service install
```

### 7. Update Docker Login

Now you can login from anywhere:

```bash
docker login registry.yourdomain.com
```

## 🔐 Security Features

This setup includes:

- ✅ **Authentication**: htpasswd-based authentication
- ✅ **Access Control**: User-based access control
- ✅ **Secure Headers**: Security headers configured
- ✅ **Health Checks**: Built-in health monitoring
- ✅ **Delete Support**: Ability to delete images
- ✅ **Logging**: Comprehensive logging
- ✅ **TLS via Cloudflare**: Encrypted traffic through tunnel

## 📊 Management Commands

### View Running Containers

```bash
docker-compose ps
```

### View Logs

```bash
# All logs
docker-compose logs -f

# Last 100 lines
docker-compose logs --tail=100
```

### Stop Registry

```bash
docker-compose down
```

### Restart Registry

```bash
docker-compose restart
```

### Update Registry

```bash
docker-compose pull
docker-compose up -d
```

## 🗂️ Managing Images

### List Images in Registry

```bash
curl -u username:password http://localhost:5000/v2/_catalog
```

### List Tags for an Image

```bash
curl -u username:password http://localhost:5000/v2/<image-name>/tags/list
```

### Delete an Image

First, get the digest:
```bash
curl -I -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
  -u username:password \
  http://localhost:5000/v2/<image-name>/manifests/<tag>
```

Then delete:
```bash
curl -X DELETE -u username:password \
  http://localhost:5000/v2/<image-name>/manifests/<digest>
```

Run garbage collection:
```bash
docker exec docker-registry bin/registry garbage-collect /etc/docker/registry/config.yml
```

## 🏗️ Building Multi-Platform Images

To ensure your images work on both ARM64 (Apple Silicon) and AMD64 (Intel/AMD) architectures, see the **[MULTIPLATFORM-GUIDE.md](MULTIPLATFORM-GUIDE.md)** for comprehensive instructions.

### Quick Start

**Option 1: Using the Script (Recommended)**

```bash
# Copy script to your project
cp build-multiplatform.sh /path/to/your-project/
cd /path/to/your-project
chmod +x build-multiplatform.sh

# Run it
./build-multiplatform.sh
```

**Option 2: Manual Command**

```bash
# One-time setup
docker buildx create --name multiplatform-builder --use
docker buildx inspect --bootstrap

# Build and push
cd /path/to/your-project
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag registry.builtbychristiaan.com/your-image:latest \
  --push \
  .
```

### Verify Multi-Platform Support

```bash
docker manifest inspect registry.builtbychristiaan.com/your-image:latest
```

You should see manifests for both `linux/amd64` and `linux/arm64`.

📖 **See [MULTIPLATFORM-GUIDE.md](MULTIPLATFORM-GUIDE.md) for advanced options, CI/CD integration, and troubleshooting.**

## 🔄 Backup and Restore

### Backup Registry Data

```bash
# Create backup directory
mkdir -p backups

# Backup data
tar -czf backups/registry-backup-$(date +%Y%m%d-%H%M%S).tar.gz data/

# Backup auth
tar -czf backups/auth-backup-$(date +%Y%m%d-%H%M%S).tar.gz auth/
```

### Restore Registry Data

```bash
# Stop registry
docker-compose down

# Restore data
tar -xzf backups/registry-backup-YYYYMMDD-HHMMSS.tar.gz

# Restore auth
tar -xzf backups/auth-backup-YYYYMMDD-HHMMSS.tar.gz

# Start registry
docker-compose up -d
```

## 🛡️ Production Hardening

For production use, consider:

1. **Regular Backups**: Set up automated backups
2. **Monitoring**: Implement monitoring (Prometheus, Grafana)
3. **Image Scanning**: Add vulnerability scanning (Clair, Trivy)
4. **Rate Limiting**: Configure rate limits at Cloudflare
5. **IP Allowlisting**: Restrict access to known IPs
6. **Audit Logging**: Enable detailed audit logs
7. **Storage Limits**: Set storage quotas
8. **Automated Cleanup**: Regular garbage collection
9. **Disaster Recovery**: Document recovery procedures
10. **High Availability**: Consider clustering for critical workloads

## 🐛 Troubleshooting

### Registry Won't Start

Check logs:
```bash
docker-compose logs
```

Common issues:
- Port 5000 already in use
- Permission issues with volumes
- Missing auth file

### Can't Login

- Verify credentials in `auth/htpasswd`
- Check registry is running: `docker-compose ps`
- Verify you're using the correct URL

### Can't Push Images

- Ensure you're logged in: `docker login localhost:5000`
- Check disk space: `df -h`
- Verify permissions on `data/` directory

### Health Check Failing

```bash
# Manual health check
curl http://localhost:5000/v2/
```

Should return: `{}`

## 📚 Additional Resources

- [Docker Registry Documentation](https://docs.docker.com/registry/)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Docker Registry API](https://docs.docker.com/registry/spec/api/)

## 📝 Notes

- The registry data is stored in `./data` directory
- Authentication files are in `./auth` directory
- Both directories are excluded from git (see `.gitignore`)
- Default port is 5000 (can be changed in `docker-compose.yml`)
- Registry uses HTTP by default (TLS provided by Cloudflare Tunnel)

## 🆘 Support

If you encounter issues:
1. Check the logs: `docker-compose logs`
2. Verify Docker is running: `docker ps`
3. Check disk space: `df -h`
4. Review configuration files
5. Consult Docker Registry documentation
