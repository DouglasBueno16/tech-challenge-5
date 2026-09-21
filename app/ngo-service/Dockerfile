# ==========================================
# ESTÁGIO 1: Builder (Instala dependências)
# ==========================================
FROM python:3.9-slim AS builder

WORKDIR /app
COPY requirements.txt .

# Instala as dependências da aplicação e do ecossistema OpenTelemetry
RUN pip install --user --no-cache-dir -r requirements.txt && \
    pip install --user --no-cache-dir \
    opentelemetry-api \
    opentelemetry-sdk \
    opentelemetry-instrumentation \
    opentelemetry-instrumentation-flask \
    opentelemetry-exporter-otlp

# ==========================================
# ESTÁGIO 2: Produção (Imagem limpa e leve)
# ==========================================
FROM python:3.9-slim

WORKDIR /app

# Copia APENAS as dependências prontas do estágio 1 (Multi-stage build)
COPY --from=builder /root/.local /root/.local

# Copia o código-fonte da aplicação
COPY . .

# Garante acesso aos executáveis instalados pelo pip (--user)
ENV PATH=/root/.local/bin:$PATH
ENV PORT=8081

# Expõe a porta que o edital pediu
EXPOSE 8081

# O comando mágico: Inicia a aplicação com o agente automático do OpenTelemetry
CMD ["opentelemetry-instrument", "gunicorn", "--bind", "0.0.0.0:8081", "--workers", "2", "--threads", "4", "app:app"]