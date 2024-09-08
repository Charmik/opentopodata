# Some geo dependencies (like rasterio) don't have wheels that work for M1
# macs. So this image includes gdal, as well as other dependencies needed to
# build those libraries from scratch.
#
# It works just the same as the main image, but is much larger and slower to
# build.

FROM ghcr.io/osgeo/gdal:ubuntu-full-3.9.1

# Ensure the base image's Python version is compatible
RUN python --version

# Install required packages including python3-venv and python3-dev
RUN set -e && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        memcached \
        python3-pip \
        python3-venv \
        python3-dev \
        gcc \
        g++ \
        supervisor \
        libmemcached-dev \
        libssl-dev && \
    rm -rf /var/lib/apt/lists/*
# Set up the virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements file and install Python packages
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --disable-pip-version-check uwsgi regex pylibmc && \
    pip install --no-cache-dir --disable-pip-version-check -r /app/requirements.txt && \
    rm -rf /root/.cache/pip/* && \
    rm /app/requirements.txt

# Ensure uwsgi is linked correctly
RUN ln -s /opt/venv/bin/uwsgi /usr/local/bin/uwsgi

# Set the working directory
WORKDIR /app
COPY . /app/

# Configure Nginx and Supervisor
RUN echo > /etc/nginx/sites-available/default && \
    cp /app/docker/nginx.conf /etc/nginx/conf.d/nginx.conf && \
    cp /app/docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set the command to run the application
CMD ["sh", "/app/docker/run.sh"]

# Expose the application port
EXPOSE 5000

# Set environment variables
ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENV GDAL_DISABLE_READDIR_ON_OPEN=TRUE
ENV GDAL_NUM_THREADS=ALL_CPUS
ENV GDAL_CACHEMAX=512