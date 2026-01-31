# 🐳 HeadlessX - Docker Status

## ✅ **¡TODO FUNCIONANDO!**

| Componente | Build | Runtime    | Puerto |
| ---------- | ----- | ---------- | ------ |
| PostgreSQL | ✅    | ✅ Healthy | 5432   |
| Backend    | ✅    | ✅ Healthy | 3001   |
| Frontend   | ✅    | ✅ Running | 3000   |

## 🚀 Comandos Rápidos

```bash
# Iniciar todo
docker compose up -d

# Ver logs
docker compose logs -f

# Parar todo
docker compose down

# Rebuild completo
docker compose up -d --build
```

## 🔧 Networking Fix (Frontend)

Se corrigió la configuración de red para que el Frontend se comunique correctamente tanto del lado del cliente como del servidor:

| Variable              | Valor                   | Uso                              |
| --------------------- | ----------------------- | -------------------------------- |
| `NEXT_PUBLIC_API_URL` | `http://localhost:3001` | Browser -> Backend (Directo)     |
| `INTERNAL_API_URL`    | `http://backend:3001`   | Server Proxy -> Backend (Docker) |

## 📁 Archivos Creados/Modificados

- `backend/Dockerfile` - Multi-stage build + Camoufox params
- `frontend/Dockerfile` - Multi-stage + Standalone
- `docker-compose.yml` - Fixed env vars override
- `frontend/next.config.ts` - Added `INTERNAL_API_URL` logic
- `backend/prisma/client.config.ts` - Config Prisma v7
- `backend/docker-entrypoint.sh` - Init DB con fixes
- `DOCKER.md` - Documentación completa

## 🌐 URLs

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:3001
- **Health Check**: http://localhost:3001/api/health

---

✅ **Última actualización**: 31 Enero 2026, 15:40 CET
