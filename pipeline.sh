#!/bin/bash

GIT_COMMIT=$(git rev-parse HEAD)

### Functions
search_docker_image () {
    docker images -f reference="algolia:$1" --format "{{.ID}}"
}

build_and_test () {
    # Set vars
    TEST_PORT=13000
    # Build container using git commit tag
    echo "TAG=$GIT_COMMIT" > test/.env

    # Build and run tests
    RUNNING=$(docker compose -f test/compose.yaml ps | grep -v NAME)

    if [ ! -z $RUNNING ]; then
        echo ">>> Test environment already running. Restarting it..."
        docker compose -f test/compose.yaml restart
    else
        echo ">>> Starting test environment..."
        docker compose -f test/compose.yaml up -d
    fi

    # Wait a bit
    echo ">>> Waiting until test is ready..."; sleep 5

    # Check if service is valid
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$TEST_PORT)

    if [ $HTTP_CODE == 200 ]; then
        echo ">>> Checks passed!"
        echo ">>> Stopping test environment"
        docker compose -f test/compose.yaml down
    else
        echo ">>> Container failed with HTTP status code: $HTTP_CODE"
        echo ">>> Stopping test environment"
        docker compose -f test/compose.yaml down
        echo ">>> Cleaning up invalid image..."
        docker rmi algolia:$GIT_COMMIT
    fi
}

promote_and_deploy () {
    echo ">>> Promote container rc to latest and create rollback image"
    if [ -z $(search_docker_image latest) ]; then
        echo ">>> algolia:latest doesn't exist, skipping rollback image creation."
    else
        docker tag algolia:latest algolia:rollback
    fi
    docker tag algolia:${GIT_COMMIT} algolia:latest
    echo ">>> Image algolia:${GIT_COMMIT} promoted to algolia:latest!"

    RUNNING=$(docker compose -f prod/compose.yaml ps | grep -v NAME)

    if [[ ! -z $RUNNING ]]; then
        echo ">>> Prod environment already running. Restarting..."
        bash ./docker_update.sh app
    else
        echo ">>> Starging prod environment..."
        docker compose -f prod/compose.yaml up -d
    fi
}


### Start
# Build image only if it doesn't exist
IMAGE_ID=$(search_docker_image $GIT_COMMIT)

if [ -z $IMAGE_ID ]; then
    build_and_test
else
    echo ">>> Image already built. Pipeline skipped"
fi

# Check if latest (prod) is the same image of the current commit
IMAGE_ID=$(search_docker_image $GIT_COMMIT)
IMAGE_ID_LATEST=$(search_docker_image latest)
RUNNING=$(docker compose -f prod/compose.yaml ps | grep -v NAME)

if [ -z $IMAGE_ID ]; then
    echo ">>> Pipeline failed. Fix your code"
elif [ -z $IMAGE_ID_LATEST ]; then
    echo ">>> Prod latest doesn't exist, creating it..."
    promote_and_deploy
elif [[ $IMAGE_ID == $IMAGE_ID_LATEST && ! -z $RUNNING ]]; then
    echo ">>> Prod already on current version. Skip deployment"
else 
    echo ">>> Deploying to prod..."
    promote_and_deploy
fi
