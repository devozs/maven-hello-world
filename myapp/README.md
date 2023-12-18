# Blog Post for Java (Maven and Docker) & CI/CD- using GitHub Action & FluxCD
Read more at the [GitHub Actions FluxCD & Helm Blog Post](https://devozs.com/blog/2023/12/17/ci-cd-github-actions-flux-helm)

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
