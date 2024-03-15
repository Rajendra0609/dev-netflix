FROM node:16.17.0-alpine as builder

# Set working directory inside the container
WORKDIR /app

# Copy package.json and yarn.lock to work directory
COPY package.json yarn.lock ./

# Install dependencies with retry mechanism
RUN set -eux; \
    apk add --no-cache bash; \
    for i in $(seq 1 5); do \
        yarn install --frozen-lockfile && break; \
        sleep 5; \
    done

# Copy the rest of the application files
COPY . .

# Set environment variables
ARG TMDB_V3_API_KEY
ENV VITE_APP_TMDB_V3_API_KEY=${TMDB_V3_API_KEY}
ENV VITE_APP_API_ENDPOINT_URL="https://api.themoviedb.org/3"

# Build the application
RUN yarn build

# Use nginx stable-alpine as production stage
FROM nginx:stable-alpine

# Set working directory inside the nginx container
WORKDIR /usr/share/nginx/html

# Remove default nginx content
RUN rm -rf ./*

# Copy the built application from the builder stage to nginx container
COPY --from=builder /app/dist .

# Expose port 80
EXPOSE 80

# Set nginx as entrypoint with daemon off
CMD ["nginx", "-g", "daemon off;"]
