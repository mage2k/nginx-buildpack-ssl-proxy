#!/bin/bash

echo "Serving files from /tmp on $PORT"
cd tmp
python -m SimpleHTTPServer $PORT &

while true
do
	sleep 1
	echo "."
done