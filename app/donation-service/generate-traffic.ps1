<#
.SYNOPSIS
    Script de teste e geração de carga para o donation-service com Datadog APM.
#>

$BaseUrl = "http://localhost:8082"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  TESTE LOCAL DO DONATION-SERVICE & DATADOG APM" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Health Checks
Write-Host "`n[1/5] Verificando integridade do servico..." -ForegroundColor Yellow
try {
    $live = Invoke-RestMethod -Uri "$BaseUrl/health/live" -Method Get
    Write-Host " [PASS] Liveness: $($live | ConvertTo-Json -Compress)" -ForegroundColor Green
    
    $ready = Invoke-RestMethod -Uri "$BaseUrl/health/ready" -Method Get
    Write-Host " [PASS] Readiness: $($ready | ConvertTo-Json -Compress)" -ForegroundColor Green
} catch {
    Write-Host " [FAIL] Falha ao conectar em $BaseUrl. O servico esta de pe?" -ForegroundColor Red
    exit 1
}

# 2. Criacao de Doacoes Validas (Gera Traces HTTP + SQL INSERT + Metricas)
Write-Host "`n[2/5] Enviando doacoes validas para registrar APM Traces e Spans SQL..." -ForegroundColor Yellow

$donations = @(
    @{ ngo_id = 1; amount = 150.00; donor_name = "Carlos Silva" },
    @{ ngo_id = 2; amount = 85.50;  donor_name = "Mariana Souza" },
    @{ ngo_id = 1; amount = 320.00; donor_name = "Ana Beatriz" },
    @{ ngo_id = 3; amount = 50.00;  donor_name = "Lucas Mendes" },
    @{ ngo_id = 2; amount = 200.00; donor_name = "Fernanda Lima" }
)

foreach ($d in $donations) {
    $bodyJson = $d | ConvertTo-Json
    try {
        $res = Invoke-RestMethod -Uri "$BaseUrl/donations" -Method Post -Body $bodyJson -ContentType "application/json"
        Write-Host " [PASS] Doacao criada: ID $($res.id) | ONG $($res.ngo_id) | R$ $($res.amount) | Doador: $($res.donor_name)" -ForegroundColor Green
    } catch {
        Write-Host " [FAIL] Erro ao criar doacao: $_" -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 300
}

# 3. Teste de Validacao com Erros Controlados (HTTP 422 - Gera spans com erro no Datadog)
Write-Host "`n[3/5] Testando cenarios de erro 422 para evidenciar Error Tracking no Datadog..." -ForegroundColor Yellow

$invalidPayloads = @(
    @{ ngo_id = 1; amount = -10.0; donor_name = "Teste Negativo" },
    @{ ngo_id = 0; amount = 100.0; donor_name = "ONG Invalida" },
    @{ ngo_id = 2; amount = 50.0;  donor_name = "" }
)

foreach ($bad in $invalidPayloads) {
    $bodyJson = $bad | ConvertTo-Json
    try {
        $res = Invoke-RestMethod -Uri "$BaseUrl/donations" -Method Post -Body $bodyJson -ContentType "application/json"
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        Write-Host " [PASS] Rejeicao esperada (Status $status): $($_.Exception.Message)" -ForegroundColor Magenta
    }
    Start-Sleep -Milliseconds 200
}

# 4. Listagem de Doacoes (Gera Traces HTTP + SQL SELECT)
Write-Host "`n[4/5] Consultando listagem de doacoes (GET /donations)..." -ForegroundColor Yellow
try {
    $list = Invoke-RestMethod -Uri "$BaseUrl/donations" -Method Get
    Write-Host " [PASS] Total de doacoes retornadas do banco: $($list.Count)" -ForegroundColor Green
} catch {
    Write-Host " [FAIL] Erro ao listar doacoes: $_" -ForegroundColor Red
}

# 5. Endpoint de Metricas Prometheus
Write-Host "`n[5/5] Consultando endpoint de metricas Prometheus (/metrics)..." -ForegroundColor Yellow
try {
    $metrics = Invoke-RestMethod -Uri "$BaseUrl/metrics" -Method Get
    $matchRequests = [regex]::Match($metrics, "http_requests_total\{[^}]+\}\s+\d+")
    $matchDonations = [regex]::Match($metrics, "donations_created_total\{[^}]+\}\s+\d+")
    Write-Host " [PASS] Metricas SRE coletadas com sucesso!" -ForegroundColor Green
    if ($matchRequests.Success) { Write-Host "   Exemplo: $($matchRequests.Value)" -ForegroundColor Gray }
    if ($matchDonations.Success) { Write-Host "   Exemplo: $($matchDonations.Value)" -ForegroundColor Gray }
} catch {
    Write-Host " [FAIL] Erro ao consultar /metrics: $_" -ForegroundColor Red
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  TESTES FINALIZADOS COM SUCESSO!" -ForegroundColor Green
Write-Host "  Aguarde 1 a 2 minutos e acesse o Datadog para ver os traces." -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
