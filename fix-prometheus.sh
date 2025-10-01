#!/bin/bash
# Fix Prometheus config and start services

rm -rf /opt/app/monitoring/prometheus/prometheus.yml

cat > /opt/app/monitoring/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'app'
    static_configs:
      - targets: ['app:8080']
  
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

ls -la /opt/app/monitoring/prometheus/prometheus.yml

docker compose up -d app postgres prometheus grafana

echo ""
echo "Services starting! Check status:"
docker compose ps

echo ""
echo "Test health check:"
sleep 5
curl http://localhost:8080/healthz

