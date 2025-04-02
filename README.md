# helics-dockerfiles

## GT CPS VIP VIRTUAL MACHINE DOCKERFILE

### Collected installations:
- Ubuntu 22.04
- ROS 2 Jazzy
- HELICS 3.5.1
- GridLAB-D with HELICS integration
- Gazebo Harmonic
- NAV2

### BUILD DOCKER IMAGE
```docker build -t helics-docker .```

### RUN DOCKER IMAGE WITH PORT MAPPING
```docker run -p 6080:80 helics-docker```

## Commands to try if Docker gives errors (probably due to space/cache issues)

```
docker image prune
docker builder prune
docker container prune
```

You can also manually remove Docker images, containers, and builders in the Desktop app

### To check Docker resources
```docker system df```

### Updating GHCR registry after changes
```
docker tag ros2-jazzy-gz-harmonic-nav2 ghcr.io/cps-vip/ros2-jazzy-gz-harmonic-nav2:latest
docker push ghcr.io/cps-vip/ros2-jazzy-gz-harmonic-nav2:latest
```
