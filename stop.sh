#!/bin/bash

source .env

# Stop running Docker containers
docker-compose -f "${PWD}/docker/docker-compose-ca.yaml" -f "${PWD}/docker/docker-compose-dopmam-network.yaml" down --volumes --remove-orphans

# Remove previous generated artifacts
rm -fr "${PWD}/channel-artifacts"
rm -fr "${PWD}/organizations"
rm -fr "${PWD}/system-genesis-block"
