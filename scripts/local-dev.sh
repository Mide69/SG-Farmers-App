#!/bin/bash
set -e

echo "Starting SG Farmers App in development mode..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Function to check if port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "Warning: Port $port is already in use"
        return 1
    fi
    return 0
}

# Check required ports
echo "Checking required ports..."
ports=(5432 6379 3000 3001 3002 3003 80)
for port in "${ports[@]}"; do
    if ! check_port $port; then
        echo "Port $port is in use. Please free the port or stop conflicting services."
    fi
done

# Create .env files for services
create_env_files() {
    echo "Creating environment files..."
    
    # Registration API .env
    cat > services/registration-api/.env << EOF
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://postgres:postgres123@postgres:5432/sg_farmers_db
REDIS_URL=redis://redis:6379
JWT_SECRET=your-jwt-secret-key-change-in-production
LOG_LEVEL=debug
EOF

    # Search API .env
    cat > services/search-api/.env << EOF
NODE_ENV=development
PORT=3001
DATABASE_URL=postgresql://postgres:postgres123@postgres:5432/sg_farmers_db
REDIS_URL=redis://redis:6379
LOG_LEVEL=debug
EOF

    # Chat API .env
    cat > services/chat-api/.env << EOF
NODE_ENV=development
PORT=3002
DATABASE_URL=postgresql://postgres:postgres123@postgres:5432/sg_farmers_db
REDIS_URL=redis://redis:6379
OPENAI_API_KEY=your-openai-api-key-here
LOG_LEVEL=debug
EOF

    # Frontend .env
    cat > services/frontend/.env << EOF
REACT_APP_API_URL=http://localhost/api
REACT_APP_SEARCH_API_URL=http://localhost/api/search
REACT_APP_CHAT_API_URL=http://localhost/api/chat
REACT_APP_SOCKET_URL=http://localhost
EOF

    echo "Environment files created"
}

# Install dependencies
install_dependencies() {
    echo "Installing dependencies..."
    
    # Registration API
    if [ -f "services/registration-api/package.json" ]; then
        echo "Installing Registration API dependencies..."
        cd services/registration-api
        npm install
        cd ../..
    fi
    
    # Search API
    if [ -f "services/search-api/package.json" ]; then
        echo "Installing Search API dependencies..."
        cd services/search-api
        npm install
        cd ../..
    fi
    
    # Chat API
    if [ -f "services/chat-api/package.json" ]; then
        echo "Installing Chat API dependencies..."
        cd services/chat-api
        npm install
        cd ../..
    fi
    
    # Frontend
    if [ -f "services/frontend/package.json" ]; then
        echo "Installing Frontend dependencies..."
        cd services/frontend
        npm install
        cd ../..
    fi
    
    echo "Dependencies installed"
}

# Start services
start_services() {
    echo "Starting services with Docker Compose..."
    
    # Build and start services
    docker-compose up --build -d
    
    echo "Services started successfully!"
    echo ""
    echo "Service URLs:"
    echo "Frontend: http://localhost"
    echo "Registration API: http://localhost/api/farmers"
    echo "Search API: http://localhost/api/search"
    echo "Chat API: http://localhost/api/chat"
    echo "Database: localhost:5432"
    echo "Redis: localhost:6379"
    echo ""
    echo "To view logs: docker-compose logs -f [service-name]"
    echo "To stop services: docker-compose down"
}

# Wait for services to be ready
wait_for_services() {
    echo "Waiting for services to be ready..."
    
    # Wait for database
    echo "Waiting for database..."
    until docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
        sleep 2
    done
    echo "Database is ready"
    
    # Wait for Redis
    echo "Waiting for Redis..."
    until docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; do
        sleep 2
    done
    echo "Redis is ready"
    
    # Wait for APIs
    echo "Waiting for APIs..."
    sleep 10
    
    # Test health endpoints
    for i in {1..30}; do
        if curl -f http://localhost/health > /dev/null 2>&1; then
            echo "Services are healthy"
            break
        fi
        echo "Waiting for services... ($i/30)"
        sleep 2
    done
}

# Show service status
show_status() {
    echo "Service Status:"
    docker-compose ps
    
    echo ""
    echo "Testing endpoints..."
    
    # Test health endpoints
    endpoints=(
        "http://localhost/health"
        "http://localhost/api/farmers/health"
        "http://localhost/api/search/health"
        "http://localhost/api/chat/health"
    )
    
    for endpoint in "${endpoints[@]}"; do
        if curl -f "$endpoint" > /dev/null 2>&1; then
            echo "✓ $endpoint - OK"
        else
            echo "✗ $endpoint - FAILED"
        fi
    done
}

# Main function
main() {
    case "${1:-start}" in
        "start")
            create_env_files
            install_dependencies
            start_services
            wait_for_services
            show_status
            ;;
        "stop")
            echo "Stopping services..."
            docker-compose down
            ;;
        "restart")
            echo "Restarting services..."
            docker-compose restart
            wait_for_services
            show_status
            ;;
        "logs")
            docker-compose logs -f "${2:-}"
            ;;
        "status")
            show_status
            ;;
        "clean")
            echo "Cleaning up..."
            docker-compose down -v --remove-orphans
            docker system prune -f
            ;;
        *)
            echo "Usage: $0 [start|stop|restart|logs|status|clean]"
            echo ""
            echo "Commands:"
            echo "  start   - Start all services (default)"
            echo "  stop    - Stop all services"
            echo "  restart - Restart all services"
            echo "  logs    - Show logs (optionally specify service name)"
            echo "  status  - Show service status and test endpoints"
            echo "  clean   - Stop services and clean up volumes"
            exit 1
            ;;
    esac
}

main "$@"