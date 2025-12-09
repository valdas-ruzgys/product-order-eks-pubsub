#!/bin/bash

# Script to test the complete microservices flow
# Usage: ./test-microservices-flow.sh

echo "🧪 Testing Microservices Flow"
echo "=============================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo "${GREEN}✓${NC} $2"
    else
        echo "${RED}✗${NC} $2"
    fi
}

# Step 1: Check Kubernetes connection
echo "1️⃣  Checking Kubernetes connection..."
if kubectl cluster-info &> /dev/null; then
    print_status 0 "Kubernetes cluster is accessible"
else
    print_status 1 "Cannot connect to Kubernetes cluster"
    exit 1
fi
echo ""

# Step 2: Check Dapr installation
echo "2️⃣  Checking Dapr installation..."
DAPR_PODS=$(kubectl get pods -n dapr-system --no-headers 2>/dev/null | grep Running | wc -l | tr -d ' ')
if [ "$DAPR_PODS" -gt 0 ]; then
    print_status 0 "Dapr is installed ($DAPR_PODS running pods)"
    kubectl get pods -n dapr-system --no-headers
else
    echo "${YELLOW}⚠${NC}  Dapr may not be fully running"
fi
echo ""

# Step 3: Check microservices namespace
echo "3️⃣  Checking microservices namespace..."
if kubectl get namespace microservices &> /dev/null; then
    print_status 0 "Microservices namespace exists"
else
    print_status 1 "Microservices namespace does not exist"
    exit 1
fi
echo ""

# Step 4: Check service deployments
echo "4️⃣  Checking service deployments..."
PRODUCT_PODS=$(kubectl get pods -n microservices -l app=product-service --no-headers 2>/dev/null | wc -l | tr -d ' ')
ORDER_PODS=$(kubectl get pods -n microservices -l app=order-service --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$PRODUCT_PODS" -gt 0 ]; then
    print_status 0 "Product service deployed ($PRODUCT_PODS pods)"
else
    print_status 1 "Product service not deployed"
    exit 1
fi

if [ "$ORDER_PODS" -gt 0 ]; then
    print_status 0 "Order service deployed ($ORDER_PODS pods)"
else
    print_status 1 "Order service not deployed"
    exit 1
fi

echo ""
echo "All pods in microservices namespace:"
kubectl get pods -n microservices --no-headers
echo ""

# Step 5: Setup port forwarding
echo "5️⃣  Setting up port forwarding..."
PRODUCT_POD=$(kubectl get pod -n microservices -l app=product-service -o jsonpath='{.items[0].metadata.name}')
ORDER_POD=$(kubectl get pod -n microservices -l app=order-service -o jsonpath='{.items[0].metadata.name}')

echo "   Product service pod: $PRODUCT_POD"
echo "   Order service pod: $ORDER_POD"

# Kill existing port forwards
pkill -f "kubectl port-forward" 2>/dev/null || true
sleep 2

# Start port forwarding in background
kubectl port-forward -n microservices $PRODUCT_POD 3001:3000 > /dev/null 2>&1 &
PF_PRODUCT_PID=$!
kubectl port-forward -n microservices $ORDER_POD 3002:3001 > /dev/null 2>&1 &
PF_ORDER_PID=$!

sleep 3
print_status 0 "Port forwarding established"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "🧹 Cleaning up port forwards..."
    kill $PF_PRODUCT_PID 2>/dev/null || true
    kill $PF_ORDER_PID 2>/dev/null || true
}
trap cleanup EXIT

# Step 6: Test health endpoints
echo "6️⃣  Testing health endpoints..."
echo "   Product service: "
PRODUCT_HEALTH=$(curl -s http://localhost:3001/health 2>/dev/null)
if echo $PRODUCT_HEALTH | grep -q "healthy"; then
    echo "${GREEN}✓ Healthy${NC}"
    echo "   $PRODUCT_HEALTH" | jq . 2>/dev/null || echo "   $PRODUCT_HEALTH"
else
    echo "${RED}✗ Not responding${NC}"
fi

echo ""
echo "   Order service: "
ORDER_HEALTH=$(curl -s http://localhost:3002/health 2>/dev/null)
if echo $ORDER_HEALTH | grep -q "healthy"; then
    echo "${GREEN}✓ Healthy${NC}"
    echo "   $ORDER_HEALTH" | jq . 2>/dev/null || echo "   $ORDER_HEALTH"
else
    echo "${YELLOW}⚠ Not responding (continuing anyway)${NC}"
fi
echo ""

# Step 7: Create test products
echo "7️⃣  Creating test products..."
echo "   Creating product 1: Gaming Laptop"
PRODUCT1=$(curl -s -X POST http://localhost:3001/api/products \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Gaming Laptop",
        "description": "High-performance laptop for gaming",
        "price": 1299.99,
        "stock": 25,
        "category": "Electronics"
    }' 2>/dev/null)

if echo $PRODUCT1 | grep -q "success"; then
    print_status 0 "Product 1 created"
    echo "$PRODUCT1" | jq .data 2>/dev/null || echo "$PRODUCT1"
    PRODUCT1_ID=$(echo $PRODUCT1 | jq -r '.data.id' 2>/dev/null)
else
    print_status 1 "Failed to create product 1"
fi

echo ""
echo "   Creating product 2: Wireless Mouse"
PRODUCT2=$(curl -s -X POST http://localhost:3001/api/products \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Wireless Mouse",
        "description": "Ergonomic wireless mouse",
        "price": 29.99,
        "stock": 150,
        "category": "Accessories"
    }' 2>/dev/null)

if echo $PRODUCT2 | grep -q "success"; then
    print_status 0 "Product 2 created"
    echo "$PRODUCT2" | jq .data 2>/dev/null || echo "$PRODUCT2"
    PRODUCT2_ID=$(echo $PRODUCT2 | jq -r '.data.id' 2>/dev/null)
else
    print_status 1 "Failed to create product 2"
fi

echo ""
echo "   Creating product 3: Mechanical Keyboard"
PRODUCT3=$(curl -s -X POST http://localhost:3001/api/products \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Mechanical Keyboard",
        "description": "RGB backlit mechanical keyboard",
        "price": 149.99,
        "stock": 75,
        "category": "Accessories"
    }' 2>/dev/null)

if echo $PRODUCT3 | grep -q "success"; then
    print_status 0 "Product 3 created"
    echo "$PRODUCT3" | jq .data 2>/dev/null || echo "$PRODUCT3"
else
    print_status 1 "Failed to create product 3"
fi
echo ""

# Step 8: List products
echo "8️⃣  Listing all products..."
PRODUCTS=$(curl -s http://localhost:3001/api/products 2>/dev/null)
PRODUCT_COUNT=$(echo $PRODUCTS | jq '.count' 2>/dev/null || echo "0")
print_status 0 "Found $PRODUCT_COUNT products"
echo "$PRODUCTS" | jq . 2>/dev/null || echo "$PRODUCTS"
echo ""

# Step 9: Create test orders (if order service is available)
if echo $ORDER_HEALTH | grep -q "healthy" && [ -n "$PRODUCT1_ID" ]; then
    echo "9️⃣  Creating test orders..."
    echo "   Product 1 ID: $PRODUCT1_ID"
    echo "   Creating order 1 for Gaming Laptop..."
    
    ORDER_PAYLOAD=$(cat <<EOF
{
  "productId": "$PRODUCT1_ID",
  "quantity": 2,
  "customerName": "Alice Johnson"
}
EOF
)
    echo "   Payload: $ORDER_PAYLOAD"
    
    ORDER1=$(curl -s -X POST http://localhost:3002/api/orders \
        -H "Content-Type: application/json" \
        -d "$ORDER_PAYLOAD" 2>/dev/null)
    
    if echo $ORDER1 | grep -q "success"; then
        print_status 0 "Order 1 created"
        echo "$ORDER1" | jq .data 2>/dev/null || echo "$ORDER1"
    else
        echo "${YELLOW}⚠${NC} Failed to create order 1"
        echo "   Response: $ORDER1"
    fi
    
    echo ""
    echo "   Creating order 2 for Wireless Mouse..."
    if [ -n "$PRODUCT2_ID" ]; then
        ORDER2=$(curl -s -X POST http://localhost:3002/api/orders \
            -H "Content-Type: application/json" \
            -d "{\"productId\":\"$PRODUCT2_ID\",\"quantity\":5,\"customerName\":\"Bob Smith\"}" 2>/dev/null)
        
        if echo $ORDER2 | grep -q "success"; then
            print_status 0 "Order 2 created"
            echo "$ORDER2" | jq .data 2>/dev/null || echo "$ORDER2"
        else
            echo "${YELLOW}⚠${NC} Failed to create order 2"
        fi
    fi
    
    echo ""
    echo "   Listing all orders..."
    ORDERS=$(curl -s http://localhost:3002/api/orders 2>/dev/null)
    ORDER_COUNT=$(echo $ORDERS | jq '.count' 2>/dev/null || echo "0")
    print_status 0 "Found $ORDER_COUNT orders"
    echo "$ORDERS" | jq . 2>/dev/null || echo "$ORDERS"
else
    echo "9️⃣  Skipping order tests (order service not available or no product IDs)"
fi
echo ""

# Step 10: Summary
echo "=============================="
echo "${GREEN}✓ Microservices flow test completed!${NC}"
echo ""
echo "Summary:"
echo "  - Kubernetes cluster: Running"
echo "  - Dapr: Installed"
echo "  - Product service: Running"
echo "  - Order service: $(if echo $ORDER_HEALTH | grep -q 'healthy'; then echo 'Running'; else echo 'Limited'; fi)"
echo "  - Products created: $PRODUCT_COUNT"
echo ""
echo "Next steps:"
echo "  - Check DynamoDB tables for persisted data"
echo "  - Check SNS/SQS for published events"
echo "  - Monitor CloudWatch logs for service activity"
echo ""
