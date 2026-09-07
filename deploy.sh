#!/usr/bin/env bash
# Deploy manual no servidor: puxa a última versão do GitHub e recria os containers.
# Stack isolado (projeto "vellum"): MySQL próprio + backend + frontend na porta 8095.
# Uso:  ./deploy.sh
set -euo pipefail

cd "$(dirname "$0")"

COMPOSE="docker compose -p vellum -f docker-compose.prod.yml"

echo "==> git pull"
git pull --ff-only

echo "==> build + up (db + backend + frontend)"
$COMPOSE up -d --build

echo "==> limpando imagens antigas"
docker image prune -f

echo "==> status"
$COMPOSE ps
echo "OK. App em http://<ip-do-servidor>:${FRONTEND_PORT:-8095}"
