FROM ubuntu:22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    nodejs \
    npm \
    python3 \
    python3-pip \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Install act (GitHub Actions local runner)
RUN curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Install additional tools
RUN npm install -g @actions/core @actions/github

# Set working directory
WORKDIR /workspace

# Copy application files
COPY package*.json ./
COPY src/ ./src/
COPY scripts/ ./scripts/

# Install Node.js dependencies
RUN npm install

# Expose port
EXPOSE 3000

# Default command
CMD ["npm", "start"]
