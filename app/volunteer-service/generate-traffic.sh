#!/usr/bin/env bash
BASE_URL="http://localhost:8083"

echo "=== [1/4] Verificando integridade (/health) ==="
curl -s "$BASE_URL/health" && echo ""

echo "=== [2/4] Registrando voluntarios validos (DynamoDB PUT) ==="
curl -s -X POST "$BASE_URL/volunteers" -H "Content-Type: application/json" -d '{"name": "Carlos Silva", "email": "carlos.silva@email.com", "ngo_id": 1}' && echo ""
curl -s -X POST "$BASE_URL/volunteers" -H "Content-Type: application/json" -d '{"name": "Mariana Souza", "email": "mariana.souza@email.com", "ngo_id": 2}' && echo ""
curl -s -X POST "$BASE_URL/volunteers" -H "Content-Type: application/json" -d '{"name": "Ana Beatriz", "email": "ana.beatriz@email.com", "ngo_id": 1}' && echo ""

echo "=== [3/4] Enviando requisicoes invalidas (Erro 400 para Error Tracking) ==="
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" -X POST "$BASE_URL/volunteers" -H "Content-Type: application/json" -d '{"name": "Teste Invalido"}'
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" -X POST "$BASE_URL/volunteers" -H "Content-Type: application/json" -d '{"email": "sem.nome@email.com", "ngo_id": 1}'
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" -X POST "$BASE_URL/volunteers" -H "Content-Type: application/json" -d '{}'

echo "=== [4/4] Listando voluntarios por ONG (GET /volunteers/<ngo_id> -> DynamoDB SCAN) ==="
curl -s "$BASE_URL/volunteers/1" | head -c 200 && echo "..."
curl -s "$BASE_URL/volunteers/2" | head -c 200 && echo "..."

echo "=== Testes concluidos com sucesso! ==="
