# Use a lightweight base image with bash
FROM debian:12-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    ca-certificates \
    curl \
    gnupg \
  && rm -rf /var/lib/apt/lists/*

# Install gcloud CLI (for gcloud storage + run jobs)
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
    > /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
  && apt-get update && apt-get install -y google-cloud-cli \
  && rm -rf /var/lib/apt/lists/*

# Set working dir
WORKDIR /app

# Copy your script
COPY setup.sh .

# Make it executable
RUN chmod +x setup.sh

# Run the script
ENTRYPOINT ["./setup.sh"]