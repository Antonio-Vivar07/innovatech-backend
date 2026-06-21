# innovatech-backend
Backend API REST Innovatech Chile - Node.js + PostgreSQL + Docker + CI/CD

## EP3 - Despliegue en AWS ECS Fargate

### Arquitectura
- Clúster ECS Fargate: ep3-innovatech-cluster-v2
- Servicio backend: ep3-backend-service (2-4 tareas, autoscaling)
- Base de datos: RDS MySQL (ep3-despachos-db)
- Comunicación interna: Network Load Balancer (ep3-backend-nlb), puerto 8081
- Se eligió NLB en lugar de ECS Service Connect porque el rol IAM de AWS Academy (voclabs) deniega explícitamente el permiso servicediscovery:*, requerido por Service Connect.

### Pipeline CI/CD
- GitHub Actions (.github/workflows/deploy.yml), runner self-hosted
- Flujo: checkout → build imagen Docker → push a Docker Hub → configurar credenciales AWS → aws ecs update-service --force-new-deployment
- Reemplaza un flujo anterior (heredado de EP2) que hacía deploy vía SSH a instancias EC2; se migró a despliegue real en ECS Fargate.

### Autoscaling
- Target Tracking Scaling configurado vía Application Auto Scaling
- Métrica: ECSServiceAverageCPUUtilization
- Umbral: 50% (valor estándar recomendado por AWS: equilibra capacidad de respuesta ante picos de carga sin escalar de forma excesiva ante fluctuaciones normales)
- Rango: mínimo 2 tareas, máximo 4 tareas
- Validado con prueba de carga (múltiples peticiones concurrentes vía curl), confirmando incremento real de CPU y tráfico de red en CloudWatch Container Insights

### Gestión de Secrets
Los siguientes secrets están configurados en GitHub (Settings > Secrets and variables > Actions), nunca expuestos en el código fuente:
- DOCKER_USER / DOCKER_TOKEN: autenticación con Docker Hub para push de imágenes
- AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN: credenciales temporales de AWS Academy (tipo STS), referenciadas en el workflow como ${{ secrets.NOMBRE }}, nunca impresas en logs ni hardcodeadas
- Limitación conocida: al ser credenciales de laboratorio académico con expiración (~4 horas), deben renovarse manualmente en GitHub cuando el lab se reinicia

### Problemas encontrados y solución
1. **Conexión RDS bloqueada por Security Group**: el Security Group de RDS solo permitía la IP de un desarrollador específico. Se agregó regla de entrada permitiendo el Security Group del backend en el puerto 3306.
2. **Error "Public Key Retrieval is not allowed"**: el driver MySQL Connector/J moderno requiere el parámetro allowPublicKeyRetrieval=true en la URL JDBC para el método de autenticación caching_sha2_password de MySQL 8. Se agregó a application.properties.
3. **Healthcheck del NLB fallando de forma intermitente**: el Security Group del backend solo permitía tráfico en el puerto 8081 desde un Security Group específico, bloqueando el healthcheck del NLB en una de las dos zonas de disponibilidad. Se agregó regla permitiendo el rango completo de la VPC (10.0.0.0/16) en el puerto 8081.

### Tiempos del pipeline (referencia)
- Build + push de imagen Docker: ~53 segundos
- Deploy completo (incluyendo redeploy ECS): ~29 segundos tras build exitoso
