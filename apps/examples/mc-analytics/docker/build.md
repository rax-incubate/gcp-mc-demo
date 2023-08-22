# Build and push the image
MYAPP_REPO=us-east1-docker.pkg.dev/gcp-mc-demo-prime/myapp/mc-analytics:0.9  && docker build .  -t ${MYAPP_REPO} && docker push ${MYAPP_REPO}
