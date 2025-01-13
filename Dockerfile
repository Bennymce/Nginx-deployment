# Use official NGINX image from Docker Hub
FROM nginx:latest

# Copy custom HTML content to NGINX's default directory
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80
