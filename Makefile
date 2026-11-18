PYTHON ?= $(shell command -v python3.14 || command -v python3.13 || command -v python3.12 || command -v python3)
VENV ?= .venv
BIN := $(VENV)/bin

# Оболочка контроллера часто экспортирует mitogen_linear. Playbook'и Molecule
# его не содержат, поэтому тесты и lint идут на встроенной стратегии.
export ANSIBLE_STRATEGY := linear
unexport ANSIBLE_STRATEGY_PLUGINS

# Docker Desktop на macOS слушает ~/.docker/run/docker.sock, а не /var/run/docker.sock.
ifeq ($(DOCKER_HOST),)
ifneq ($(wildcard $(HOME)/.docker/run/docker.sock),)
export DOCKER_HOST := unix://$(HOME)/.docker/run/docker.sock
endif
endif

IMAGE_2204 ?= auditd-ubuntu2204:local
IMAGE_2404 ?= auditd-ubuntu2404:local
IMAGE_2604 ?= auditd-ubuntu2604:local

.PHONY: lint test test-ubuntu2204 test-ubuntu2404 test-ubuntu2604 test-profiles link image

$(BIN)/molecule: requirements.txt
	$(PYTHON) -m venv $(VENV)
	$(BIN)/python -m pip install -U pip
	$(BIN)/python -m pip install -r requirements.txt

lint: $(BIN)/molecule
	$(BIN)/ansible-lint
	$(BIN)/yamllint .

test-ubuntu2204: $(BIN)/molecule image
	$(BIN)/molecule test -s ubuntu2204

test-ubuntu2404: $(BIN)/molecule image
	$(BIN)/molecule test -s ubuntu2404

test-ubuntu2604: $(BIN)/molecule image
	$(BIN)/molecule test -s ubuntu2604

test-profiles: $(BIN)/molecule image
	$(BIN)/molecule test -s profiles

test: test-ubuntu2204 test-ubuntu2404 test-ubuntu2604 test-profiles

link:
	mkdir -p .cache/roles
	ln -sfn "$(CURDIR)" .cache/roles/auditd

image:
	docker build --build-arg UBUNTU_VERSION=22.04 -t $(IMAGE_2204) -f molecule/Dockerfile molecule
	docker build --build-arg UBUNTU_VERSION=24.04 -t $(IMAGE_2404) -f molecule/Dockerfile molecule
	docker build --build-arg UBUNTU_VERSION=26.04 -t $(IMAGE_2604) -f molecule/Dockerfile molecule
