.PHONY: all prepare run clean-image clean-volume clean-all rebuild status help

# Default target
all: prepare run

# Prepare by making scripts executable
prepare:
	@echo "Making scripts executable..."
	chmod +x run-windsurf.sh
	@echo "Windsurf preparation complete!"

# Run the application
run: prepare
	@echo "Running Windsurf..."
	./run-windsurf.sh

# Force rebuild the Docker image
rebuild: clean-image
	@echo "Force rebuilding Windsurf container..."
	docker build -t windsurf-container -f Dockerfile .

# Remove docker image for Windsurf and Firefox
clean-image:
	@echo "Removing docker image: windsurf-container..."
	docker rmi windsurf-container 2>/dev/null || true

# Remove docker volumes for Windsurf and Firefox
clean-volume:
	@echo "Removing docker volumes: windsurf_app_data, windsurf_config_data, firefox_profile_data..."
	docker volume rm windsurf_app_data windsurf_config_data firefox_profile_data 2>/dev/null || true

# Clean everything (image + volumes)
clean-all: clean-image clean-volume
	@echo "Cleaned all Windsurf Docker resources!"

# Show status of Docker resources
status:
	@echo "=== Docker Images ==="
	@docker images | grep -E "(REPOSITORY|windsurf-container)" || echo "No windsurf-container image found"
	@echo ""
	@echo "=== Docker Volumes ==="
	@docker volume ls | grep -E "(DRIVER|windsurf_|firefox_profile_data)" || echo "No windsurf volumes found"
	@echo ""
	@echo "=== Running Containers ==="
	@docker ps | grep -E "(CONTAINER|windsurf-instance)" || echo "No windsurf-instance container running"

# Help target
help:
	@echo "Windsurf Docker Makefile"
	@echo "========================"
	@echo ""
	@echo "Available targets:"
	@echo "  all         - Prepare and run Windsurf (default)"
	@echo "  prepare     - Make scripts executable"
	@echo "  run         - Run Windsurf container"
	@echo "  rebuild     - Force rebuild Docker image"
	@echo "  clean-image - Remove Windsurf Docker image"
	@echo "  clean-volume- Remove Windsurf Docker volumes"
	@echo "  clean-all   - Remove both image and volumes"
	@echo "  status      - Show Docker resources status"
	@echo "  help        - Show this help message"
	@echo ""
	@echo "Quick start:"
	@echo "  make        - Run Windsurf"
	@echo "  make status - Check what's installed"
	@echo "  make clean-all && make - Fresh restart"