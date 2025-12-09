# Architecture Diagram - EKS Microservices with Dapr Pub/Sub

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                  AWS Cloud (us-east-1)                              │
│                                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────────┐ │
│  │                          VPC (10.0.0.0/16)                                     │ │
│  │                                                                                │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐   │ │
│  │  │          Public Subnet 1 (10.0.1.0/24)      AZ1                         │   │ │
│  │  │  ┌──────────────┐      ┌──────────────┐                                 │   │ │
│  │  │  │   NAT GW 1   │      │   ALB/NLB    │                                 │   │ │
│  │  │  └──────────────┘      └──────────────┘                                 │   │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘   │ │
│  │                                                                                │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐   │ │
│  │  │          Public Subnet 2 (10.0.2.0/24)      AZ2                         │   │ │
│  │  │  ┌──────────────┐      ┌──────────────┐                                 │   │ │
│  │  │  │   NAT GW 2   │      │   ALB/NLB    │                                 │   │ │
│  │  │  └──────────────┘      └──────────────┘                                 │   │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘   │ │
│  │                                                                                │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐   │ │
│  │  │       Private Subnet 1 (10.0.10.0/24)       AZ1                         │   │ │
│  │  │                                                                         │   │ │
│  │  │  ┌──────────────────────────────────────────────────────────────────┐   │   │ │
│  │  │  │             Amazon EKS Cluster (microservices-cluster)           │   │   │ │
│  │  │  │                                                                  │   │   │ │
│  │  │  │  ┌───────────────────────────────────────────────────────────┐   │   │   │ │
│  │  │  │  │  Namespace: microservices                                 │   │   │   │ │
│  │  │  │  │                                                           │   │   │   │ │
│  │  │  │  │  ┌──────────────────────┐    ┌──────────────────────┐     │   │   │   │ │
│  │  │  │  │  │  ProductService Pod  │    │  OrderService Pod    │     │   │   │   │ │
│  │  │  │  │  │  ┌────────────────┐  │    │  ┌────────────────┐  │     │   │   │   │ │
│  │  │  │  │  │  │  Node.js/TS    │  │    │  │  Node.js/TS    │  │     │   │   │   │ │
│  │  │  │  │  │  │  Container     │  │    │  │  Container     │  │     │   │   │   │ │
│  │  │  │  │  │  │  Port: 3000    │  │    │  │  Port: 3001    │  │     │   │   │   │ │
│  │  │  │  │  │  └────────┬───────┘  │    │  └────────▲───────┘  │     │   │   │   │ │
│  │  │  │  │  │           │          │    │           │          │     │   │   │   │ │
│  │  │  │  │  │  ┌────────▼───────┐  │    │  ┌────────┴───────┐  │     │   │   │   │ │
│  │  │  │  │  │  │  Dapr Sidecar  │  │    │  │  Dapr Sidecar  │  │     │   │   │   │ │
│  │  │  │  │  │  │  (daprd)       │  │    │  │  (daprd)       │  │     │   │   │   │ │
│  │  │  │  │  │  │  Port: 3500    │◄─┼────┼─►│  Port: 3500    │  │     │   │   │   │ │
│  │  │  │  │  │  └────────┬───────┘  │    │  └────────▲───────┘  │     │   │   │   │ │
│  │  │  │  │  └───────────┼──────────┘    └───────────┼──────────┘     │   │   │   │ │
│  │  │  │  │              │ Pub                    Sub │               │   │   │   │ │
│  │  │  │  │              │                            │               │   │   │   │ │
│  │  │  │  └──────────────┼────────────────────────────┼───────────────┘   │   │   │ │
│  │  │  │                 │                            │                   │   │   │ │
│  │  │  │  ┌──────────────┼────────────────────────────┼───────────────┐   │   │   │ │
│  │  │  │  │  Namespace: dapr-system                   │               │   │   │   │ │
│  │  │  │  │                                           │               │   │   │   │ │
│  │  │  │  │  ┌─────────────┐  ┌─────────────┐  ┌──────▼──────┐        │   │   │   │ │
│  │  │  │  │  │   Dapr      │  │   Dapr      │  │   Dapr      │        │   │   │   │ │
│  │  │  │  │  │  Operator   │  │  Sentry     │  │  Placement  │        │   │   │   │ │
│  │  │  │  │  └─────────────┘  └─────────────┘  └─────────────┘        │   │   │   │ │
│  │  │  │  └───────────────────────────────────────────────────────────┘   │   │   │ │
│  │  │  └──────────────────────────────────────────────────────────────────┘   │   │ │
│  │  │                                                                         │   │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘   │ │
│  │                                                                                │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐   │ │
│  │  │       Private Subnet 2 (10.0.11.0/24)       AZ2                         │   │ │
│  │  │  (EKS Worker Nodes - Same architecture as Subnet 1)                     │   │ │
│  │  └─────────────────────────────────────────────────────────────────────────┘   │ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────────┐ │
│  │                          AWS Services (Managed)                                │ │
│  │                                                                                │ │
│  │  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │ │
│  │  │  Amazon ECR  │    │  Amazon SNS  │    │  Amazon SQS  │    │  CloudWatch  │  │ │
│  │  │              │    │              │    │              │    │              │  │ │
│  │  │  - product-  │    │  Topic:      │    │  Queue:      │    │  - Logs      │  │ │
│  │  │    service   │    │  product-    │    │  order-      │    │  - Metrics   │  │ │
│  │  │              │    │  events      │    │  service-    │    │  - Alarms    │  │ │
│  │  │  - order-    │    │              │    │  queue       │    │              │  │ │
│  │  │    service   │    │              │    │              │    │              │  │ │
│  │  │              │    │              │    │  DLQ:        │    │              │  │ │
│  │  │              │    │              │    │  order-      │    │              │  │ │
│  │  │              │    │              │    │  service-dlq │    │              │  │ │
│  │  └──────────────┘    └──────┬───────┘    └──────▲───────┘    └──────────────┘  │ │
│  │                             │                   │                              │ │
│  │                             │  Subscription     │                              │ │
│  │                             └───────────────────┘                              │ │
│  │                                                                                │ │
│  │                      ┌──────────────┐    ┌──────────────┐                      │ │
│  │                      │  AWS IAM     │    │  Amazon      │                      │ │
│  │                      │              │    │  VPC         │                      │ │
│  │                      │  - EKS Role  │    │  Endpoints   │                      │ │
│  │                      │  - Node Role │    │              │                      │ │
│  │                      │  - Pod SA    │    │  - ECR       │                      │ │
│  │                      │    Role      │    │              │                      │ │
│  │                      └──────────────┘    └──────────────┘                      │ │
│  └────────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Event Flow Diagram

```
┌──────────────┐
│   Client /   │
│   External   │
│   System     │
└──────┬───────┘
       │
       │ HTTP POST /api/products
       │ {name, price, stock}
       ▼
┌─────────────────────────────────────────┐
│      ProductService                     │
│  ┌───────────────────────────────────┐  │
│  │  1. Receive HTTP Request          │  │
│  │  2. Validate Input                │  │
│  │  3. Create Product (UUID)         │  │
│  │  4. Store in Memory/DB            │  │
│  └───────────────┬───────────────────┘  │
│                  │                      │
│  ┌───────────────▼───────────────────┐  │
│  │  5. Publish Event via Dapr        │  │
│  │     - Topic: product-events       │  │
│  │     - Type: product.created       │  │
│  │     - Payload: Product details    │  │
│  └───────────────┬───────────────────┘  │
└──────────────────┼──────────────────────┘
                   │
                   │ Dapr Pub/Sub API
                   │ POST /v1.0/publish/product-pubsub/product-events
                   ▼
        ┌──────────────────────┐
        │   Dapr Sidecar       │
        │   (ProductService)   │
        └──────────┬───────────┘
                   │
                   │ AWS SDK Call
                   ▼
        ┌──────────────────────┐
        │   Amazon SNS         │
        │   Topic:             │
        │   product-events     │
        └──────────┬───────────┘
                   │
                   │ SNS → SQS Subscription
                   │ (Fan-out pattern)
                   ▼
        ┌──────────────────────┐
        │   Amazon SQS         │
        │   Queue:             │
        │   order-service-     │
        │   queue              │
        └──────────┬───────────┘
                   │
                   │ Long Polling (20s)
                   │ Batch: 10 messages
                   ▼
        ┌──────────────────────┐
        │   Dapr Sidecar       │
        │   (OrderService)     │
        └──────────┬───────────┘
                   │
                   │ HTTP POST /product-events
                   │ (Subscriber endpoint)
                   ▼
┌─────────────────────────────────────────┐
│      OrderService                       │
│  ┌───────────────────────────────────┐  │
│  │  6. Receive Event from Dapr       │  │
│  │  7. Parse Event Payload           │  │
│  │  8. Process Based on Event Type:  │  │
│  │     - product.created             │  │
│  │     - product.updated             │  │
│  │     - product.deleted             │  │
│  └───────────────┬───────────────────┘  │
│                  │                      │
│  ┌───────────────▼───────────────────┐  │
│  │  9. Business Logic:               │  │
│  │     - Cache product info          │  │
│  │     - Update existing orders      │  │
│  │     - Cancel orders if deleted    │  │
│  └───────────────┬───────────────────┘  │
│                  │                      │
│  ┌───────────────▼───────────────────┐  │
│  │ 10. Send ACK to Dapr              │  │
│  │     - HTTP 200 OK                 │  │
│  │     - Delete from SQS             │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## Component Interaction

### 1. **Product Creation Flow**

1. Client sends HTTP POST to ProductService Load Balancer
2. Request routed to ProductService pod
3. ProductService validates and creates product
4. ProductService publishes event via Dapr sidecar
5. Dapr publishes to SNS topic
6. SNS delivers to subscribed SQS queue
7. Dapr sidecar polls SQS queue
8. Event delivered to OrderService subscriber endpoint
9. OrderService processes event
10. OrderService acknowledges, Dapr deletes from SQS

### 2. **Failure Scenarios**

**Scenario A: OrderService is Down**

- Events accumulate in SQS queue
- Messages retained for 14 days
- When OrderService recovers, backlog is processed
- DLQ handles messages that fail 3 times

**Scenario B: SNS Publishing Fails**

- ProductService receives error
- Can implement retry with exponential backoff
- Log error for monitoring
- Consider local queue for retry

**Scenario C: Event Processing Fails**

- OrderService returns HTTP 500
- Dapr doesn't delete from SQS
- Message becomes visible again after timeout
- Retry up to 3 times
- After 3 failures, moved to DLQ

## Scaling Architecture

```
                    ┌─────────────────────────┐
                    │  Horizontal Pod         │
                    │  Autoscaler (HPA)       │
                    └────────┬────────────────┘
                             │
                             │ Metrics: CPU, Memory, Custom
                             ▼
          ┌──────────────────────────────────────────┐
          │  Scale ProductService                    │
          │  Min: 1 replica.                         │
          │  Max: 10 replicas                        │
          │  Target CPU: 70%                         │
          └──────────────────────────────────────────┘

          ┌──────────────────────────────────────────┐
          │  Scale OrderService                      │
          │  Min: 1 replica                          │
          │  Max: 10 replicas                        │
          │  Target: SQS Queue Depth                 │
          └──────────────────────────────────────────┘
```

## Network Flow

```
Internet
   │
   ▼
Internet Gateway
   │
   ▼
Application Load Balancer (Public Subnet)
   │
   ▼
EKS Service (ClusterIP/LoadBalancer)
   │
   ▼
Pod (Private Subnet)
   │
   ├──► Container (Port 3000/3001)
   │
   └──► Dapr Sidecar (Port 3500)
        │
        ├──► SNS (via NAT Gateway)
        │
        └──► SQS (via NAT Gateway)
```
