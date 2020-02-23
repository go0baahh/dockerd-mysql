###
# Makefile for building, testing and deploying a Dockerfile.
# Arguments can be defined either via make command line or
# the included env.mk file.
###
# > dockerd@example:~$ make build
# > dockerd@example:~$ make start NAME=CustomName
###
-include env_file

#ifeq ($(TAG),)
#    TAG := $(MYSQL_VER)
#else
#    TAG := $(MYSQL_VER)-$(TAG)
#endif

ifneq ($(DIO_TAG),)
    ifneq ($(TAG),latest)
        TAG := $(TAG)-$(DIO_TAG)
    endif
endif

.PHONY: testing build test push shell run start stop logs clean nuke release

default: build

build:
	docker build -t $(REPO):$(TAG) \
		--build-arg FROM=$(FROM) \
	    -f $(DOCKER_FILE) ./

test:
	cd ./tests && IMAGE=$(REPO):$(TAG) ./run.sh

push:
	docker push $(REPO):$(TAG)

shell:
	docker run --rm --env-file $(ENV) --name $(NAME) -it $(PORTS) $(VOLUMES) $(REPO):$(TAG) /bin/bash

#docker exec -it mysql-dockerd mysql -u root -p -P 33060

run:
	docker run --rm --env-file $(ENV) --name $(NAME) $(PORTS) $(VOLUMES) $(REPO):$(TAG) $(CMD)

start:
	docker run -d --env-file $(ENV) --name $(NAME) $(PORTS) $(VOLUMES) $(REPO):$(TAG)

stop:
	docker stop $(NAME)

logs:
	docker logs $(NAME)

clean:
	-docker rm -f $(NAME)

nuke:
	docker system prune -a

release: build push

%:
	@:
