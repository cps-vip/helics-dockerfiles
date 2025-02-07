# Use Ubuntu 22.04 (Jammy) as base image since ROS 2 Humble and GridLAB-D supports it
FROM tiryoh/ros2-desktop-vnc:humble

# Set non-interactive mode for apt-get
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG en_US.UTF-8
ENV LC_ALL C.UTF-8

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

# Add ROS 2 GPG key and repository to sources list
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Update apt repository caches and upgrade system packages
RUN apt-get update && apt-get upgrade -y

# Install ROS 2 Humble Desktop version (includes GUI tools like RViz)
RUN apt-get install -y ros-humble-desktop

# Install ROS development tools
RUN apt-get install -y ros-dev-tools

# Install HELICS from source
WORKDIR /software
RUN git clone https://github.com/GMLC-TDC/HELICS && \
    cd HELICS && \
    git checkout v3.5.1 && \
    mkdir build && cd build && \
    cmake -DHELICS_BUILD_CXX_SHARED_LIB=ON -DCMAKE_INSTALL_PREFIX=/software/HELICS ../ && \
    make -j$(nproc) && make install 

RUN export PATH=/software/HELICS/build/bin:$PATH && \
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/software/HELICS/build/lib && \
    export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:/software/HELICS/include && \
    ls /software/HELICS/build/lib

# Install HELICS Python bindings
RUN pip3 install helics==3.5.1 helics[cli]==3.5.1

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

# Set environment variables for ROS 2, HELICS, and GridLAB-D
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc && \
    echo "export PATH=/software/GridLAB-D/bin:\$PATH" >> ~/.bashrc && \
    echo "export GLPATH=/software/GridLAB-D/share" >> ~/.bashrc

RUN    pip3 install --force-reinstall numpy==1.26.3 && \
    pip3 install --force-reinstall PYPOWER==5.1.16

RUN cd ~ && \
    git clone https://github.com/fizzyforever101/ros2-helics.git && \
    mkdir -p ~/ros2_ws/src && \
    cd ~/ros2_ws && \
    git clone https://github.com/ros2/examples src/examples -b humble
    #colcon build --symlink-install

# Source the setup.bash to ensure environment variables are set correctly
# SHELL ["/bin/bash", "-c", "source ~/.bashrc"]

# Default command to launch bash shell
# CMD ["/bin/bash"]
