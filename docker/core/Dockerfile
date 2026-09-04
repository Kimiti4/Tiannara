FROM python:3.11-slim

WORKDIR /app

# Install system dependencies for scientific computing
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libblas-dev \
    liblapack-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy core code
COPY tiannara_core/ ./tiannara_core/

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser
USER appuser

# No exposed ports - internal service only
# Run as background worker
CMD ["python", "-m", "tiannara_core.autonomous.loop"]
