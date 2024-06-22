# Stage 1: Downloading files
FROM ollama/ollama as downloader

# Copy the startup script into the image
COPY setup.sh /setup.sh

# Make sure the script is executable
RUN chmod +x /setup.sh

# Run the initialization script to perform the pull operation
RUN /setup.sh llama3:8b

# Use an official base image with your desired version
FROM ollama/ollama

# Copy the model files
COPY --from=downloader /root/.ollama/ /root/.ollama/
# Copy the ollama binary
COPY --from=downloader /bin/ollama /bin/ollama

ENV PYTHONUNBUFFERED=1 

# Set up the working directory
WORKDIR /

RUN apt-get update --yes --quiet && DEBIAN_FRONTEND=noninteractive apt-get install --yes --quiet --no-install-recommends \
    software-properties-common \
    gpg-agent \
    build-essential apt-utils \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get install --reinstall ca-certificates

# PYTHON 3.11
RUN add-apt-repository --yes ppa:deadsnakes/ppa && apt update --yes --quiet

RUN DEBIAN_FRONTEND=noninteractive apt-get install --yes --quiet --no-install-recommends \
    python3.11 \
    python3.11-dev \
    python3.11-distutils \
    python3.11-lib2to3 \
    python3.11-gdbm \
    python3.11-tk \
    pip

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 999 \
    && update-alternatives --config python3 && ln -s /usr/bin/python3 /usr/bin/python

RUN pip install --upgrade pip

# Add your file
ADD runpod_wrapper.py .
ADD start.sh .

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Override Ollama's entrypoint
ENTRYPOINT ["bin/bash", "start.sh"]

CMD ["llama3:8b"]