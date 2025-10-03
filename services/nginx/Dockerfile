FROM nginx:alpine

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy frontend files (will be provided via volume mount in docker-compose)
# Create logs directory
RUN mkdir -p /var/log/nginx

# Create a default index.html if none exists
RUN echo '<!DOCTYPE html><html><head><title>Voicebot RAG</title></head><body><h1>Loading...</h1><p>Frontend files will be mounted here</p></body></html>' > /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
