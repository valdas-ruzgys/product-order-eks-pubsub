#!/bin/bash

# Script to test pub/sub event publishing
# Usage: ./test-publish.sh

echo "🧪 Testing Product Event Publishing..."
echo ""

# Check if product service is accessible
echo "🔍 Checking Product Service..."

# Get product service load balancer URL
PRODUCT_LB=$(kubectl get svc product-service -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -z "$PRODUCT_LB" ]; then
    echo "⚠️  LoadBalancer not assigned. Starting port-forward..."
    
    # Kill any existing port-forward on 4000
    lsof -ti:4000 | xargs kill -9 2>/dev/null || true
    
    # Start port-forward in background
    kubectl port-forward -n microservices svc/product-service 4000:80 > /dev/null 2>&1 &
    PORT_FORWARD_PID=$!
    
    # Wait for port-forward to be ready
    echo "⏳ Waiting for port-forward to be ready..."
    sleep 3
    
    PRODUCT_URL="http://localhost:4000"
else
    PRODUCT_URL="http://${PRODUCT_LB}"
fi

echo "Product Service URL: ${PRODUCT_URL}"
echo ""

# Create a test product
echo "📤 Creating test product..."
RESPONSE=$(curl -s -X POST "${PRODUCT_URL}/api/products" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "MacBook Pro 16",
        "description": "High-performance laptop for professionals",
        "price": 2499.99,
        "stock": 25,
        "category": "Electronics"
    }' 2>/dev/null || echo '{"error":"Connection failed"}')

echo "Response: ${RESPONSE}"
PRODUCT_ID=$(echo ${RESPONSE} | grep -o '"id":"[^"]*"' | cut -d'"' -f4 || echo "")

if [ -z "$PRODUCT_ID" ]; then
    echo ""
    echo "❌ Failed to create product."
    
    # Cleanup port-forward if we started it
    if [ ! -z "$PORT_FORWARD_PID" ]; then
        kill $PORT_FORWARD_PID 2>/dev/null || true
    fi
    
    exit 1
fi

echo ""
echo "✅ Product created with ID: ${PRODUCT_ID}"
echo ""

# Wait for event to be processed
echo "⏳ Waiting for event to be processed by Order Service..."
sleep 5

# Check order service logs
echo ""
echo "📋 Order Service Logs (last 20 lines):"
kubectl logs -l app=order-service -n microservices --tail=20 2>/dev/null | grep -i "product" || echo "No product events found yet"

echo ""
echo "📋 Product Service Logs (last 20 lines):"
kubectl logs -l app=product-service -n microservices --tail=20 2>/dev/null | grep -i "publish" || echo "No publish events found yet"

echo ""
echo "✅ Test completed!"

# Cleanup port-forward if we started it
if [ ! -z "$PORT_FORWARD_PID" ]; then
    echo ""
    echo "🧹 Cleaning up port-forward..."
    kill $PORT_FORWARD_PID 2>/dev/null || true
fi

echo ""
echo "To verify the event was processed:"
echo "  1. Check Order Service logs: npm run logs:order"
echo "  2. Check Dapr logs: kubectl logs -l app=order-service -c daprd -n microservices"



