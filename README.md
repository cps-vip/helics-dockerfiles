# helics-dockerfiles

# GT CPS VIP VIRTUAL MACHINE

### Collected Installations:
- Ubuntu 22.04
- ROS 2 Jazzy
- HELICS 3.6.1
- GridLAB-D with HELICS integration
- Gazebo Harmonic
- NAV2

## Installation Instructions

1. Use this link ([GHCR Auth](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry)) to create a personal access token with the `write:packages`, `read:packages`, and `delete:packages` scopes.
2. Run the command ```echo <personal-access-token> | docker login ghcr.io -u <your-github-username> --password-stdin``` with your generated PAT and GitHub username.
3. Run the pull command ```docker pull ghcr.io/cps-vip/cps-vip-vm:latest```
4. Start a container with the command ```docker run -p 6080:80 cps-vip-vm:latest```



## For Testing/Dockerfile modification
BUILD DOCKER IMAGE
```docker build -t image-name .```

RUN DOCKER IMAGE WITH PORT MAPPING
```docker run -p 6080:80 image-name```

Commands to try if Docker gives errors (probably due to space/cache issues)

```
docker image prune
docker builder prune
docker container prune
```

You can also manually remove Docker images, containers, and builders in the Desktop app

To check Docker resources
```docker system df```

Updating GHCR registry after changes
```
docker tag ros2-jazzy-gz-harmonic-nav2 ghcr.io/cps-vip/ros2-jazzy-gz-harmonic-nav2:latest
docker push ghcr.io/cps-vip/ros2-jazzy-gz-harmonic-nav2:latest
```
