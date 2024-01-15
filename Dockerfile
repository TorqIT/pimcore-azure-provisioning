FROM ubuntu:latest

RUN apt-get update && \
    apt-get install curl vim docker.io jq -y && \
    # Install Azure CLI
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Required to use Bicep templates
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

# Install AZ CLI extensions
RUN az config set bicep.use_binary_from_path=false
RUN az bicep install
RUN az bicep upgrade
RUN az extension add -n containerapp
RUN az extension add -n storage-preview

ADD /*.sh /azure/
ADD /bicep /azure/bicep
ADD /scripts /azure/scripts
ADD /js /azure/js

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    cd /azure/js && \
    npm install && \
    npm install -g ts-node

WORKDIR /azure

CMD [ "tail", "-f", "/dev/null" ]
