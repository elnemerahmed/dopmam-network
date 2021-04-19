#!/bin/bash

source .env

# Stop running Docker containers
docker-compose -f "${PWD}/docker/docker-compose-ca.yaml" -f "${PWD}/docker/docker-compose-dopmam-network.yaml" down --volumes --remove-orphans

# Remove previous generated artifacts
rm -fr "${PWD}/channel-artifacts" 2>&1 > /dev/null
rm -fr "${PWD}/organizations" 2>&1 > /dev/null
rm -fr "${PWD}/ccp" 2>&1 > /dev/null
rm -fr "${PWD}/system-genesis-block" 2>&1 > /dev/null
