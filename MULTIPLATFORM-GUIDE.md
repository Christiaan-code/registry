# Multi-Platform Docker Build Guide

## 🎯 Quick Reference

### Method 1: Using the Script (Easiest)

```bash
# Copy script to your project
cp /path/to/registry/build-multiplatform.sh .
chmod +x build-multiplatform.sh

# Run it
./build-multiplatform.sh
```

The script will prompt you for:
- Image name
- Registry URL (defaults to registry.builtbychristiaan.com)
- Tag (defaults to latest)
- Additional tags (optional)

### Method 2: Manual Command

```bash
# One-time setup (only need to do this once)
docker buildx create --name multiplatform-builder --driver docker-container --use
docker buildx inspect --bootstrap

# Build and push
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag registry.builtbychristiaan.com/your-image:latest \
  --push \
  .
```

### Method 3: Docker Compose with Buildx

If you use docker-compose, add this to your build service:

```yaml
services:
  your-service:
    build:
      context: .
      platforms:
        - linux/amd64
        - linux/arm64
```

Then build with:
```bash
docker buildx bake --push
```

## 📋 Step-by-Step for Each Container

### For whatsapp-automation

```bash
cd /path/to/whatsapp-automation
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag registry.builtbychristiaan.com/whatsapp-automation:latest \
  --push \
  .
```

### For Any Other Container

```bash
cd /path/to/your-project

# Login to your registry first
docker login registry.builtbychristiaan.com

# Build and push
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag registry.builtbychristiaan.com/your-image:latest \
  --tag registry.builtbychristiaan.com/your-image:v1.0.0 \
  --push \
  .
```

## 🔧 Advanced Options

### Custom Dockerfile Location

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --file ./docker/Dockerfile \
  --tag registry.builtbychristiaan.com/your-image:latest \
  --push \
  .
```

### Build Arguments

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg NODE_VERSION=20 \
  --build-arg ENV=production \
  --tag registry.builtbychristiaan.com/your-image:latest \
  --push \
  .
```

### Multiple Tags

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag registry.builtbychristiaan.com/your-image:latest \
  --tag registry.builtbychristiaan.com/your-image:v1.0.0 \
  --tag registry.builtbychristiaan.com/your-image:stable \
  --push \
  .
```

### Build Without Push (Local Testing)

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag registry.builtbychristiaan.com/your-image:latest \
  --load \
  .
```

Note: `--load` only works with a single platform. For multi-platform local testing, use `--output type=docker`.

## 🔍 Verification

### Check What Platforms Are Available

```bash
docker manifest inspect registry.builtbychristiaan.com/your-image:latest
```

Look for the `platform` field in each manifest entry. You should see:
- `"architecture": "amd64"` 
- `"architecture": "arm64"`

### Pull and Test

```bash
# Pull (will automatically select correct platform)
docker pull registry.builtbychristiaan.com/your-image:latest

# Or force a specific platform
docker pull --platform linux/amd64 registry.builtbychristiaan.com/your-image:latest
docker pull --platform linux/arm64 registry.builtbychristiaan.com/your-image:latest
```

## 🚀 Automating Builds

### GitHub Actions Example

Create `.github/workflows/build-multiplatform.yml`:

```yaml
name: Build Multi-Platform Image

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to Registry
        uses: docker/login-action@v3
        with:
          registry: registry.builtbychristiaan.com
          username: ${{ secrets.REGISTRY_USERNAME }}
          password: ${{ secrets.REGISTRY_PASSWORD }}
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            registry.builtbychristiaan.com/${{ github.repository }}:latest
            registry.builtbychristiaan.com/${{ github.repository }}:${{ github.sha }}
```

### GitLab CI Example

Create `.gitlab-ci.yml`:

```yaml
build-multiplatform:
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $REGISTRY_USERNAME -p $REGISTRY_PASSWORD registry.builtbychristiaan.com
    - docker buildx create --use
  script:
    - |
      docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --tag registry.builtbychristiaan.com/$CI_PROJECT_NAME:latest \
        --tag registry.builtbychristiaan.com/$CI_PROJECT_NAME:$CI_COMMIT_SHORT_SHA \
        --push \
        .
```

## 🛠️ Troubleshooting

### Error: "multiple platforms feature is currently not supported"

You need to use buildx:
```bash
docker buildx create --name multiplatform-builder --use
```

### Error: "failed to solve: failed to read dockerfile"

Make sure you're in the directory with your Dockerfile, or specify the path:
```bash
docker buildx build --file ./path/to/Dockerfile ...
```

### Build is Very Slow

Multi-platform builds are slower because they build for multiple architectures. Consider:
- Using build cache: `--cache-from` and `--cache-to`
- Building only the platforms you need
- Using a faster builder instance

### Error: "no builder instance selected"

```bash
docker buildx use multiplatform-builder
```

Or create a new one:
```bash
docker buildx create --name multiplatform-builder --use
```

## 📊 Best Practices

1. **Always build for both amd64 and arm64** - Covers most use cases
2. **Use semantic versioning** - Tag with specific versions, not just `latest`
3. **Test on both platforms** - Pull and run on different architectures
4. **Cache layers** - Use `--cache-from` and `--cache-to` for faster builds
5. **Keep images small** - Use multi-stage builds and minimal base images
6. **Automate builds** - Use CI/CD to build on every commit/tag

## 🔗 Additional Resources

- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [Multi-platform Images](https://docs.docker.com/build/building/multi-platform/)
- [Build Cache](https://docs.docker.com/build/cache/)

## 💡 Pro Tips

### Faster Rebuilds with Cache

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --cache-from type=registry,ref=registry.builtbychristiaan.com/your-image:buildcache \
  --cache-to type=registry,ref=registry.builtbychristiaan.com/your-image:buildcache,mode=max \
  --tag registry.builtbychristiaan.com/your-image:latest \
  --push \
  .
```

### Build for More Platforms

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --tag registry.builtbychristiaan.com/your-image:latest \
  --push \
  .
```

### Inspect Builder Capabilities

```bash
docker buildx inspect multiplatform-builder
```

### Remove Old Builders

```bash
docker buildx rm multiplatform-builder
```
