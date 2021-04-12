#!/bin/bash

source .env

# Stop running Docker containers
docker-compose -f ./docker/docker-compose-ca.yaml -f ./docker/docker-compose-dopmam-network.yaml down --volumes --remove-orphans

# Remove previous generated artifacts
rm -fr ./organizations/*
rm -fr ./system-genesis-block/*
rm -fr ./channel-artifacts/*
rm -fr ./anchor-artifacts/*
