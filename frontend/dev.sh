#!/bin/bash

podman image exists rpv-web-dev

if [ $? -ne 0 ]; then
    echo '[+] Building rpv-web-dev image.'
    podman build -t rpv-web-dev -f Dockerfile.dev .
else
    echo '[+] rpv-web-dev image already exists.'
fi

echo '[+] Starting rpv-web-dev container.'
podman run -v ${PWD}/src/:/app/src:Z -it -p 5173:5173 rpv-web-dev
