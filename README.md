# Environment preparation
## Requirements
The following software is required to run the pipeline:
- [bash](https://www.gnu.org/software/bash/) - unix shell
- [docker](https://docs.docker.com/get-docker/) - container runtime
- [git](https://github.com/git-guides/install-git#install-git) - cli for git version control software

## Usage
---
1. Download this repository to your local env (pipeline relay on Git commits to do the work)
    >```git clone https://github.com/enmuro/demo-deploy.git ```
1. Update your code in directory [instant-search-demo](instant-search-demo)
1. Commit your changes
1. Run the [pipeline](pipeline.sh) manually from unix shell console
    >```./pipeline.sh```
1. Check application on
    >[http://localhost:3000](http://localhost:3000)

    >[http://localhost:3001](http://localhost:3001)  
    > user: admin  
    > pass: admin

## Pipeline
---
The pipeline is controlled by [pipeline.sh](pipeline.sh) file.  
Actions:
- Run [test docker-compose](test/compose.yaml) to build and deploy on testing.
- Check if container is responding correctly.
- Once the check passes, a backup of `algolia:latest` image to `algolia:rollback` is created for fast rollback just in case.
- Docker image `algolia:$GIT_COMMIT` is promoted to `algolia:latest`.
- Run [prod docker-compose](prod/compose.yaml) or [docker_udpate](docker_update.sh) to deploy/update in production.

> Note: All containers are build and stored locally.

### Deployment
[docker_update](docker_update.sh) file is in charge of scaling up/down production containers and to reload nginx proxy.

Nginx proxy server's purpose is to manage a smooth deployment without downtime and to enable basic authentication for port 3001.  
The reason for this authentication is that port 3001 content looks like an administrator's area to me.

> user: admin  
> pass: admin

### Dockerfile
[Dockerfile](Dockerfile) defines the configuration for building the application container.
- Install necessary packages
- Add the code
- Create an entrypoint and expose ports

## Why docker compose?
---
Reasons for using docker compose in this practice:
- A way to test locally is required. Docker is easy to run on any environment and architecture.
- Time limitation for building more complex environments and possible issues when configuring on testing env.

## What would I ideally do?
---
The best scenario in my mind would be a webhook to run the pipeline (Github actions, Gitlab CI/CD, Argo Workflows...) automatically with every commit.  
Environment wise I would like to use kubernetes clusters (test / prod) static or dynamically created.  
One option for local development is k3d but I have not yet experience with it and there's a time limitation.  
For deployment I would use ArgoCD as it keeps synchronization for whatever is in the Git repository avoiding manual changes on the cluster.