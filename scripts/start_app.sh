#!/bin/bash
cd /home/ec2-user/my-api
echo "Starting app..."
nohup node app.js > /dev/null 2>&1 &
echo "App started"
