#!/bin/bash
# Simple health check for GRR admin UI
if curl -s http://localhost:8000/ | grep -q "GRR"; then
  exit 0
else
  exit 1
fi
