gcloud auth configure-docker us-east1-docker.pkg.dev
docker build . --tag us-east1-docker.pkg.dev/caged-rais-vplentz/caged-rais-docker-repo/extractor_gsutil:tag1
docker push us-east1-docker.pkg.dev/caged-rais-vplentz/caged-rais-docker-repo/extractor_gsutil:tag1