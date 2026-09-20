#!/usr/bin/env bash
BASE_URL="http://localhost:8082"

echo "=== [1/5] Verificando integridade (/health) ==="
curl -s "$BASE_URL/health/live" && echo ""
curl -s "$BASE_URL/health/ready" && echo ""

echo "=== [2/5] Enviando doacoes validas (APM Traces + SQL INSERT) ==="
curl -s -X POST "$BASE_URL/donations" -H "Content-Type: application/json" -d '{"ngo_id": 1, "amount": 150.00, "donor_name": "Carlos Silva"}' && echo ""
curl -s -X POST "$BASE_URL/donations" -H "Content-Type: application/json" -d '{"ngo_id": 2, "amount": 85.50, "donor_name": "Mariana Souza"}' && echo ""
curl -s -X POST "$BASE_URL/donations" -H "Content-Type: application/json" -d '{"ngo_id": 1, "amount": 320.00, "donor_name": "Ana Beatriz"}' && echo ""

echo "=== [3/5] Enviando doacao invalida (Erro 422 para Error Tracking) ==="
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" -X POST "$BASE_URL/donations" -H "Content-Type: application/json" -d '{"ngo_id": 1, "amount": -10.00, "donor_name": "Teste Invalido"}'

echo "=== [4/5] Listando doacoes (GET /donations -> SQL SELECT) ==="
curl -s "$BASE_URL/donations" | head -c 200 && echo "..."

echo "=== [5/5] Coletando metricas (/metrics) ==="
curl -s "$BASE_URL/metrics" | grep -E "http_requests_total|donations_created_total" | head -n 5

echo "=== Testes concluidos com sucesso! ==="
