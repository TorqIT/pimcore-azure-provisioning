FROM mcr.microsoft.com/azure-cli@sha256:e02c9723b6e2296e98f54eeb3630b95206aef06aa04251e097ce8390904ba396

# Install required packages
RUN tdnf update -y glibc sqlite-libs; \
    tdnf install -y curl tar jq vim

# Install Docker
ENV DOCKER_CHANNEL=stable
ENV DOCKER_VERSION=29.5.3
ENV DOCKER_API_VERSION=1.52
RUN curl -fsSL "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" | tar -xzC /usr/local/bin --strip=1 docker/docker

# Configure Azure CLI and patch vulnerable Python dependencies in the az environment
RUN az config set bicep.use_binary_from_path=False; \
    PYTHONPATH=/usr/lib/az/lib/python3.12/site-packages python3 -m pip install --upgrade --target=/usr/lib/az/lib/python3.12/site-packages "PyJWT>=2.13.0" "cryptography>=48.0.1"

# Add Bicep templates and scripts
RUN mkdir -p /azure
ADD /*.sh /azure
ADD /bicep /azure/bicep
ADD /helper-scripts /azure/helper-scripts
ADD /provisioning-scripts /azure/provisioning-scripts

WORKDIR /azure

CMD [ "tail", "-f", "/dev/null" ]
