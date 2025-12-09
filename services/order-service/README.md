# Order Service

Handles orders and consumes product events via Dapr pub/sub. Built with NestJS.

## Quick Start

- Prerequisites: Node.js 18+, Docker, Dapr CLI, AWS CLI (optional), Kubernetes (optional)
- Env: copy `.env.example` → `.env` and adjust values

```zsh
npm install
npm run start:dev
```

Swagger UI: `http://localhost:3002/api`

## API Endpoints

- `POST /api/orders` — create order
- `GET /api/health` — health check

## Dapr Subscriptions

- Subscribes to topic `product-events` via `pubsub` component
- Controller handles CloudEvents (supports `data_base64`)
