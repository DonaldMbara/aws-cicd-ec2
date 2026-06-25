#!/bin/bash
echo "Validating service..."
sleep 5   # give app time to start

response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)

if [ "$response" == "200" ]; then
  echo "Validation passed — app is healthy"
  exit 0
else
  echo "Validation FAILED — got HTTP $response"
  exit 1   # non-zero exit fails the deployment and triggers rollback
fi