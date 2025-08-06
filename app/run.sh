#!/bin/bash

# Default to running directly if no argument is provided
RUN_MODE=${1:-direct}

case $RUN_MODE in
  "docker")
    echo "Running application using Docker..."
    
    # Build the Docker image
    docker build -t waf-demo-app .
    
    # Run the container
    docker run -d \
      --name waf-demo-app \
      -p 3000:3000 \
      --restart unless-stopped \
      waf-demo-app
    
    echo "Docker container started. Check status with: docker ps"
    ;;

  "direct")
    echo "Running application directly with Node.js..."
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
      npm install
    fi
    
    # Start the application
    node app.js
    ;;

  *)
    echo "Invalid run mode. Use 'docker' or 'direct'"
    exit 1
    ;;
esac
