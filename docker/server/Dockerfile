# Multi-stage build for OpenKO Server Applications
# This Dockerfile builds all server components: AIServer, Aujard, Ebenezer, ItemManager, VersionManager

# Build stage
FROM ubuntu:24.04 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    clang-18 \
    libc++-18-dev \
    libc++abi-18-dev \
    unixodbc-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set clang as default compiler
ENV CC=clang-18
ENV CXX=clang++-18

# Set working directory
WORKDIR /build

# Copy source code
COPY . .

# Initialize and update git submodules
RUN git config --global --add safe.directory /build && \
    git submodule update --init --recursive || true

# Configure CMake
RUN cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPENKO_BUILD_CLIENT=OFF \
    -DOPENKO_BUILD_CLIENT_TOOLS=OFF \
    -DOPENKO_BUILD_TOOLS=OFF \
    -DOPENKO_BUILD_SERVERS=ON \
    -DOPENKO_BUILD_TESTS=OFF \
    -DOPENKO_COMPILE_WARNINGS_AS_ERROR=OFF

# Build all servers
RUN cmake --build build --config Release -j$(nproc)

# Runtime stage
FROM ubuntu:24.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    unixodbc \
    unixodbc-dev \
    curl \
    gnupg \
    apt-transport-https \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Microsoft ODBC Driver for SQL Server
# Using modern gpg method instead of deprecated apt-key
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main" > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    rm -rf /var/lib/apt/lists/*

# Create application directory
WORKDIR /app

# Copy built binaries from builder
COPY --from=builder /build/build/bin/Release/AIServer /app/bin/AIServer
COPY --from=builder /build/build/bin/Release/Aujard /app/bin/Aujard
COPY --from=builder /build/build/bin/Release/Ebenezer /app/bin/Ebenezer
COPY --from=builder /build/build/bin/Release/ItemManager /app/bin/ItemManager
COPY --from=builder /build/build/bin/Release/VersionManager /app/bin/VersionManager

# Copy server assets (MAP and QUESTS)
COPY --from=builder /build/build/bin/MAP /app/bin/MAP
COPY --from=builder /build/build/bin/QUESTS /app/bin/QUESTS

# Copy configuration templates
COPY docker/server/*.ini /app/config/

# Copy entrypoint script
COPY docker/server/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && \
    sed -i 's/\r$//' /app/entrypoint.sh

# Configure ODBC for SQL Server connection
RUN echo "[KN_online]" > /etc/odbc.ini && \
    echo "Driver = ODBC Driver 18 for SQL Server" >> /etc/odbc.ini && \
    echo "Server = sqlserver,1433" >> /etc/odbc.ini && \
    echo "Database = KN_online" >> /etc/odbc.ini && \
    echo "TrustServerCertificate = yes" >> /etc/odbc.ini

# Set working directory to bin
WORKDIR /app/bin

# Use entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]

# Default command (can be overridden in docker-compose)
CMD ["Ebenezer", "Ebenezer.ini"]
