# Product Service

REST API for managing products, built with NestJS and integrated with Dapr for pub/sub. Publishes product events to AWS SNS/SQS via Dapr.

## Quick Start

- Prerequisites: Node.js 18+, Docker, Dapr CLI, AWS CLI (optional), Kubernetes (optional)
- Env: copy `.env.example` → `.env` and adjust values

```zsh
npm install
npm run start:dev
```

Swagger UI: `http://localhost:3001/api`

## API Endpoints

- `POST /api/products` — create product
- `GET /api/health` — health check

## Dapr Pub/Sub

- Publishes events to topic `product-events`
