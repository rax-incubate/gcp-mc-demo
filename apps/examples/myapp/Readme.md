# Build and push the image

MYAPP_REPO=us-east1-docker.pkg.dev/gcp-mc-demo-prime/myapp/myapp:1.10

docker build .  -t ${MYAPP_REPO}

docker push ${MYAPP_REPO}