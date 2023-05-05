FROM ubuntu:latest

# Install nginx
RUN apt-get update && apt-get install -y nginx

# Deploy web application
COPY index.html /var/www/html/

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]