#!/bin/sh -e

OS=$1
DOCKERFILE_PATH=""
BASE_IMAGE_NAME="pingdom/"

trap "rm -f $DOCKERFILE_PATH.version" INT QUIT EXIT

docker_build_with_version()
{
    local dockerfile="$1"
    DOCKERFILE_PATH=$(perl -MCwd -e 'print Cwd::abs_path shift' $dockerfile)
    cp $DOCKERFILE_PATH "$DOCKERFILE_PATH.version"
    git_version=$(git rev-parse --short HEAD)
    echo "LABEL io.openshift.builder-version=\"$git_version\"" >>"$dockerfile.version"
    docker build -t $IMAGE_NAME -f "$dockerfile.version" .
    if test "$SKIP_SQUASH" != "1"; then
	squash "$dockerfile.version"
    fi
    rm -f "$DOCKERFILE_PATH.version"
}

squash()
{
    easy_install -q --user docker_py==1.6.0 docker-scripts==0.4.4
    base=$(awk '/^FROM/{print $2}' $1)
    $HOME/.local/bin/docker-scripts squash -f $base $IMAGE_NAME
}

IMAGE_NAME=${BASE_IMAGE_NAME}redisexporter
if test "$TEST_MODE"; then
    IMAGE_NAME="$IMAGE_NAME-candidate"
fi
echo "-> Building $IMAGE_NAME ..."
if test "$OS" = "rhel7" -o "$OS" = "rhel7-candidate"; then
    docker_build_with_version Dockerfile.rhel7
else
    docker_build_with_version Dockerfile
fi
