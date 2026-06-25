#!/bin/bash
echo "Stopping app..."
pkill -f "node app.js" || true   # || true so it doesn't fail if app isn't running
echo "App stopped"