# Use nginx alpine image
FROM nginx:alpine

# Copy the HTML file to nginx html directory
COPY index.html /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Start nginx (default command from base image)
CMD ["nginx", "-g", "daemon off;"]
