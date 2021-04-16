#!/bin/bash

source .env

# Stop running Docker containers
docker-compose -f "${PWD}/docker/docker-compose-ca.yaml" -f "${PWD}/docker/docker-compose-dopmam-network.yaml" down --volumes --remove-orphans

# Remove previous generated artifacts
rm -fr "${PWD}/channel-artifacts"
rm -fr "${PWD}/organizations"
rm -fr "${PWD}/system-genesis-block"

# Crete directory structure
mkdir -p "${PWD}/channel-artifacts"
mkdir -p "${PWD}/organizations"
mkdir -p "${PWD}/system-genesis-block"

# Install and start Docker containers
docker-compose -f "${PWD}/docker/docker-compose-ca.yaml" up -d

# Create DOPMAM
./createOrg.sh dopmam localhost 7054 ca-dopmam

# Create Shifa
./createOrg.sh shifa localhost 8054 ca-shifa

# Create Orderer 
./createOrderer.sh orderer localhost 9054 ca-orderer

export FABRIC_CFG_PATH=${PWD}/configtx

# Create Genisis Block
configtxgen -profile OrdererGenesis -channelID system-channel -outputBlock "${PWD}/system-genesis-block/genesis.block"

# Install and start Docker containers
docker-compose -f "${PWD}/docker/docker-compose-dopmam-network.yaml" up -d

# Create Channel Artifacts
configtxgen -profile DopmamShifaChannel -outputCreateChannelTx "${PWD}/channel-artifacts/dopmam-shifa.tx" -channelID dopmam-shifa

# Create Channel Block
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem
export CORE_PEER_LOCALMSPID="DopmamMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/dopmam.moh.ps/users/Admin@dopmam.moh.ps/msp
export CORE_PEER_ADDRESS=localhost:7051
export FABRIC_CFG_PATH=${PWD}/config

# Poll in case the raft leader is not set yet
RETRY_COUNT=0
rc=1
while [ $rc -ne 0 -a $RETRY_COUNT -lt 10 ] ; do
  sleep 1
  peer channel create -o localhost:7050 -c dopmam-shifa --ordererTLSHostnameOverride orderer.moh.ps -f "${PWD}/channel-artifacts/dopmam-shifa.tx" --outputBlock "${PWD}/channel-artifacts/dopmam-shifa.block" --tls --cafile "${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem"
  rc=$?
  RETRY_COUNT=$(expr $RETRY_COUNT + 1)
done

# Join Channel From peer 0 Dopmam Org
# Sometimes Join takes time, hence retry
RETRY_COUNT=0
rc=1
while [ $rc -ne 0 -a $RETRY_COUNT -lt 10 ] ; do
  sleep 1
  peer channel join -b "${PWD}/channel-artifacts/dopmam-shifa.block"
  rc=$?
  RETRY_COUNT=$(expr $RETRY_COUNT + 1)
done


# Join Channel From peer 0 Shifa Org
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem
export CORE_PEER_LOCALMSPID="ShifaMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/shifa.moh.ps/users/Admin@shifa.moh.ps/msp
export CORE_PEER_ADDRESS=localhost:9051
export FABRIC_CFG_PATH=${PWD}/config

# Sometimes Join takes time, hence retry
RETRY_COUNT=0
rc=1
while [ $rc -ne 0 -a $RETRY_COUNT -lt 10 ] ; do
  sleep 1
  peer channel join -b "${PWD}/channel-artifacts/dopmam-shifa.block"
  rc=$?
  RETRY_COUNT=$(expr $RETRY_COUNT + 1)
done


# return the config export to configtx
export FABRIC_CFG_PATH=${PWD}/configtx
