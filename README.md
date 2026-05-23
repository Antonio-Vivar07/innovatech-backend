# innovatech-backend

API REST Innovatech Chile - Spring Boot (Java 17) + MySQL + Docker + CI/CD

## Tecnologías
- Java 17 + Spring Boot 3.4.4
- MySQL 8.0
- Docker + Docker Compose
- GitHub Actions (CI/CD)

## Arquitectura
- EC2 Frontend (subred pública) → EC2 Backend (subred privada)
- Imágenes publicadas en Docker Hub
- Pipeline CI/CD: build → push → deploy automático en rama `deploy`

## Requisitos
- Docker y Docker Compose instalados
- Java 17

## Ejecución local
```bash
docker-compose up -d
```

## Pipeline CI/CD
El pipeline se activa con push a la rama `deploy`:
1. Construye la imagen Docker del backend
2. Publica en Docker Hub
3. Despliega en EC2 via SSH

## Variables de entorno
| Variable | Descripción |
|---|---|
| DB_ENDPOINT | Host de la base de datos |
| DB_PORT | Puerto MySQL (3306) |
| DB_NAME | Nombre de la base de datos |
| DB_USERNAME | Usuario de la base de datos |
| DB_PASSWORD | Contraseña de la base de datos |
