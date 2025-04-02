# GT CPS VIP VIRTUAL MACHINE DOCKERFILE

# Collected installations:
# - Ubuntu 22.04
# - ROS 2 Jazzy
# - HELICS 3.5.1
# - GridLAB-D with HELICS integration
# - Gazebo Harmonic
# - NAV2

# BUILD DOCKER IMAGE
# docker build -t helics-docker .

# RUN DOCKER IMAGE WITH PORT MAPPING
# docker run -p 6080:80 helics-docker

# Commands to try if Docker gives errors (probably due to space/cache issues)

# docker image prune
# docker builder prune
# docker container prune

# You can also manually remove Docker images, containers, and builders in the Desktop app

# To check Docker resources

# docker system df

# UPDATE IMAGE TO GHCR

# docker tag ros2-jazzy-gz-harmonic-nav2 ghcr.io/cps-vip/ros2-jazzy-gz-harmonic-nav2:latest
# docker push ghcr.io/cps-vip/ros2-jazzy-gz-harmonic-nav2:latest

# Use Tiryoh's ROS2 Desktop VNC image as the base image with Jazzy
FROM tiryoh/ros2-desktop-vnc:jazzy

# Set non-interactive mode for apt-get
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=C.UTF-8

# Update packages and install system dependencies
RUN apt-get update && \
    apt-get install -y \
    locales \
    curl \
    gnupg2 \
    lsb-release \
    software-properties-common \
    libboost-dev \
    libzmq5-dev \
    git \
    cmake \
    cmake-curses-gui \
    clang-tidy \
    libxerces-c-dev \
    g++ \
    python3-pip \
    make \
    && apt-get clean

# Set locale to UTF-8
RUN locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
    export LANG=en_US.UTF-8

# Enable Ubuntu Universe repository
RUN add-apt-repository universe

# Update before installation
RUN apt update

# Add ROS 2 GPG key and repository to sources list
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Update apt repository caches and upgrade system packages
RUN apt-get update && apt-get upgrade -y

# Install ROS development tools
RUN apt-get install -y ros-dev-tools

# Install ROS 2 Jazzy Desktop version (includes GUI tools like RViz)
RUN apt-get install -y ros-jazzy-desktop

# Install HELICS from source
WORKDIR /software

RUN git clone https://github.com/GMLC-TDC/HELICS && \
    cd HELICS && \
    git checkout v3.5.1 && \
    mkdir build && cd build && \
    cmake -DHELICS_BUILD_CXX_SHARED_LIB=ON -DCMAKE_INSTALL_PREFIX=/software/HELICS -DCMAKE_CXX_STANDARD=20 ../ && \
    make -j$(nproc) && make install 

RUN export PATH=/software/HELICS/build/bin:$PATH && \
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/software/HELICS/build/lib && \
    export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:/software/HELICS/include && \
    ls /software/HELICS/build/lib

# Set environment variables - required with Jazzy image
ENV CMAKE_ARGS="-DCMAKE_CXX_STANDARD=20"

# Install node and npm - possibly needed for broken command below
RUN apt-get install -y nodejs npm

# Install Python virtual environment tools - required since Ubuntu 22.04 restricts 'pip' command
RUN apt-get install -y python3-venv
RUN python3 -m venv /software/venv

# Activate the virtual environment and install HELICS Python bindings
# TODO - resolve this command. setup.py breaks when running
RUN /software/venv/bin/pip install helics==3.6.1 helics[cli]==3.6.1
# ! Deprecated version of command
# RUN pip3 install helics==3.5.1 helics[cli]==3.5.1

# Add the virtual environment to PATH
ENV PATH="/software/venv/bin:$PATH"

# Clone and build GridLAB-D with HELICS integration
RUN git clone https://github.com/gridlab-d/gridlab-d.git

RUN echo "export PATH=~/software/HELICS/build/bin:$PATH" >> ~/.bashrc && \
    echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/software/HELICS/build/lib" >> ~/.bashrc && \
    echo "export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:/software/HELICS/include" >> ~/.bashrc && \
    echo "export PATH=/software/HELICS/bin:\$PATH" >> ~/.bashrc
    
RUN cd gridlab-d && \
    ls /software/HELICS/include/helics && \
    git submodule update --init && \
    mkdir cmake-build && cd cmake-build && \
    cmake -DCMAKE_INSTALL_PREFIX=/software/GridLAB-D -DCMAKE_BUILD_TYPE=Release -DGLD_USE_HELICS=ON -DGLD_HELICS_DIR=/software/HELICS/build -DCMAKE_CXX_FLAGS="-I/software/HELICS/include" -G "CodeBlocks - Unix Makefiles" .. && \
    cmake --build . -j8 --target install

RUN apt-get install -y python-is-python3 python3-colcon-common-extensions

# Set environment variables for ROS 2 Jazzy, HELICS, and GridLAB-D
RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc && \
    echo "export PATH=/software/GridLAB-D/bin:\$PATH" >> ~/.bashrc && \
    echo "export GLPATH=/software/GridLAB-D/share" >> ~/.bashrc

RUN /software/venv/bin/pip install --force-reinstall numpy==1.26.3 && \
    /software/venv/bin/pip install --force-reinstall PYPOWER==5.1.16

RUN cd ~ && \
    git clone https://github.com/fizzyforever101/ros2-helics.git && \
    mkdir -p ~/ros2_ws/src && \
    cd ~/ros2_ws && \
    git clone https://github.com/ros2/examples src/examples -b humble
    #colcon build --symlink-install

# Install tools for Gazebo Harmonic
RUN apt-get update && \
    apt-get install -y curl lsb-release gnupg

# Install Gazebo Harmonic
RUN curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null && \
    apt-get update && \
    apt-get install -y gz-harmonic

# Install NAV2
RUN apt-get install -y ros-jazzy-navigation2 ros-jazzy-nav2-bringup ros-jazzy-nav2-minimal-tb*

# Set up NAV2 environment
RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc && \
    echo "export GAZEBO_MODEL_PATH=\$GAZEBO_MODEL_PATH:/opt/ros/jazzy/share/turtlebot3_gazebo/models" >> ~/.bashrc