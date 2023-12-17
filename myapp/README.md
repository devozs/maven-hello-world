Link to my blog post

# Plain Maven Build and Java Execution
Build
`mvn package`

Run
`java -cp target/myapp-1.0.0.jar com.myapp.App`

Or with Java arg
`java -cp target/myapp-1.0.0.jar com.myapp.App Oz`

# Docker
Set the version `VERSION=1.0.5` (or keep it as default)
#### Build
`docker build --build-arg VERSION=${VERSION} -t myapp:${VERSION} .`
#### Run
Run and keep the container ID
`CONTAINER_ID=$(docker run -d -e NAME="Oz" -d myapp:${VERSION})`

And print the logs `docker logs {$CONTAINER_ID}`

# Deployment

#### Helm

#### FluxCD

`
flux bootstrap github \
--owner=$GITHUB_USER \
--repository=maven-hello-world \
--branch=master \
--path=./deployment/flux/infrastructure/dev \
--personal
`
`
flux create kustomization myapp \
--target-namespace=default \
--source=flux-system \
--path="./kustomize" \
--prune=true \
--wait=true \
--interval=30m \
--retry-interval=2m \
--health-check-timeout=3m \
--export > ./deployment/clusters/dev/myapp.yaml
`
