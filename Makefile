# ==============================================
# 🚀 HeadlessX - Docker Makefile
# ==============================================
# Convenient commands for Docker management
# ==============================================

.PHONY: help build up down restart logs logs-backend logs-frontend logs-postgres clean rebuild shell-backend shell-frontend db-reset db-backup db-restore health status

# Default target
help: ## Show this help message
	@echo "🚀 HeadlessX Docker Commands"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ==============================================
# 🏗️ Build & Deployment
# ==============================================

build: ## Build all Docker images
	docker-compose build

up: ## Start all services
	docker-compose up -d
	@echo "✅ Services started!"
	@echo "📊 Frontend: http://localhost:3000"
	@echo "🔗 Backend:  http://localhost:3001"

down: ## Stop all services
	docker-compose down

restart: ## Restart all services
	docker-compose restart

rebuild: ## Rebuild and restart all services
	docker-compose down
	docker-compose build --no-cache
	docker-compose up -d

# ==============================================
# 📝 Logs
# ==============================================

logs: ## View logs from all services
	docker-compose logs -f

logs-backend: ## View backend logs
	docker-compose logs -f backend

logs-frontend: ## View frontend logs
	docker-compose logs -f frontend

logs-postgres: ## View PostgreSQL logs
	docker-compose logs -f postgres

# ==============================================
# 🛠️ Maintenance
# ==============================================

status: ## Check service status
	docker-compose ps

health: ## Check service health
	@echo "🔍 Checking service health..."
	@docker-compose ps
	@echo ""
	@echo "🔗 Backend health:"
	@curl -s http://localhost:3001/api/health | jq '.' || echo "❌ Backend not responding"
	@echo ""
	@echo "🖥️ Frontend health:"
	@curl -s http://localhost:3000 > /dev/null && echo "✅ Frontend is healthy" || echo "❌ Frontend not responding"

shell-backend: ## Open shell in backend container
	docker-compose exec backend sh

shell-frontend: ## Open shell in frontend container
	docker-compose exec frontend sh

shell-postgres: ## Open PostgreSQL shell
	docker-compose exec postgres psql -U headlessx -d headlessx

# ==============================================
# 🗄️ Database Management
# ==============================================

db-reset: ## Reset database (⚠️ destructive!)
	@echo "⚠️  This will DELETE all data! Press Ctrl+C to cancel..."
	@sleep 5
	docker-compose down -v
	docker-compose up -d

db-backup: ## Backup database to backup.sql
	docker-compose exec -T postgres pg_dump -U headlessx headlessx > backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "✅ Database backed up to backup_$(shell date +%Y%m%d_%H%M%S).sql"

db-restore: ## Restore database from backup.sql (requires BACKUP_FILE=path/to/backup.sql)
ifndef BACKUP_FILE
	@echo "❌ Please specify BACKUP_FILE=path/to/backup.sql"
	@exit 1
endif
	cat $(BACKUP_FILE) | docker-compose exec -T postgres psql -U headlessx -d headlessx
	@echo "✅ Database restored from $(BACKUP_FILE)"

# ==============================================
# 🧹 Cleanup
# ==============================================

clean: ## Remove containers (keeps volumes)
	docker-compose down

clean-all: ## Remove containers AND volumes (⚠️ deletes data!)
	@echo "⚠️  This will DELETE all data including volumes! Press Ctrl+C to cancel..."
	@sleep 5
	docker-compose down -v
	@echo "✅ All containers and volumes removed"

prune: ## Clean up unused Docker resources
	docker system prune -a --volumes

# ==============================================
# 🔄 Development
# ==============================================

dev: ## Start services in development mode (with logs)
	docker-compose up

dev-build: ## Rebuild and start in development mode
	docker-compose up --build

# ==============================================
# 📦 Production
# ==============================================

prod-deploy: ## Deploy to production (build + up)
	@echo "🚀 Deploying to production..."
	docker-compose build
	docker-compose up -d
	@echo "✅ Production deployment complete!"
	@make health

prod-update: ## Update production (pull + rebuild + restart)
	@echo "🔄 Updating production..."
	git pull
	docker-compose down
	docker-compose build --no-cache
	docker-compose up -d
	@echo "✅ Production updated!"
	@make health
