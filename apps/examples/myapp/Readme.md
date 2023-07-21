# Build and push the image

MYAPP_REPO=us-east1-docker.pkg.dev/gcp-multi-cloud-demo/myapp/myapp:1.8

docker build .  -t ${MYAPP_REPO}

docker push ${MYAPP_REPO}