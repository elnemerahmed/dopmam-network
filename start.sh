#!/bin/bash

echo "$(tput setaf 3) _____   ____  _____  __  __          __  __ "
echo "|  __ \ / __ \|  __ \|  \/  |   /\   |  \/  |"
echo "| |  | | |  | | |__) | \  / |  /  \  | \  / |"
echo "| |  | | |  | |  ___/| |\/| | / /\ \ | |\/| |"
echo "| |__| | |__| | |    | |  | |/ ____ \| |  | |"
echo "|_____/ \____/|_|    |_|  |_/_/    \_\_|  |_|"
echo ""
echo "$(tput setaf 7)Authors: "
echo "  - Ahmed El Nemer: ahmedelnemer02@gmail.com"
echo "  - Waleed Mortaja: waleedmortaja@protonmail.com"
echo "  - Ahmed Afifi:    ahmedafifi1500@gmail.com$(tput sgr0)"
echo ""
echo ""

source .env

log "Stoping running Docker containers"
docker-compose -f "${PWD}/docker/docker-compose-ca.yaml" -f "${PWD}/docker/docker-compose-dopmam-network.yaml" down --volumes --remove-orphans 2>&1 > /dev/null

log "Removing previous generated artifacts"
rm -fr "${PWD}/channel-artifacts" 2>&1 > /dev/null
rm -fr "${PWD}/ccp" 2>&1 > /dev/null
rm -fr "${PWD}/system-genesis-block" 2>&1 > /dev/null

log "Creating directory structure"
mkdir -p "${PWD}/channel-artifacts" 2>&1 > /dev/null
mkdir -p "${PWD}/organizations" 2>&1 > /dev/null
mkdir -p "${PWD}/ccp" 2>&1 > /dev/null
mkdir -p "${PWD}/system-genesis-block" 2>&1 > /dev/null

log "Installing and starting Docker Certificate Authority containers"
docker-compose -f "${PWD}/docker/docker-compose-ca.yaml" up -d 2>&1 > /dev/null

log "Creating DOPMAM Organization"
./createOrg.sh dopmam localhost 7054 ca-dopmam 2>&1 > /dev/null

log "Creating Shifa Organization"
./createOrg.sh shifa localhost 8054 ca-shifa 2>&1 > /dev/null

log "Creating Naser Organization"
./createOrg.sh naser localhost 9054 ca-naser 2>&1 > /dev/null

log "Creating Orderer Organization"
./createOrderer.sh orderer localhost 10054 ca-orderer 2>&1 > /dev/null

export FABRIC_CFG_PATH=${PWD}/configtx

log "Creating Genisis Block"
configtxgen -profile OrdererGenesis -channelID system-channel -outputBlock "${PWD}/system-genesis-block/genesis.block" 2>&1 > /dev/null

log "Installing and starting Docker Network containers (Peers & Organizations)"
docker-compose -f "${PWD}/docker/docker-compose-dopmam-network.yaml" up -d 2>&1 > /dev/null

log "Creating Channel Artifacts (dopmam-shifa)"
configtxgen -profile DopmamShifaChannel -outputCreateChannelTx "${PWD}/channel-artifacts/dopmam-shifa.tx" -channelID dopmam-shifa 2>&1 > /dev/null

log "Creating Channel Artifacts (dopmam-naser)"
configtxgen -profile DopmamNaserChannel -outputCreateChannelTx "${PWD}/channel-artifacts/dopmam-naser.tx" -channelID dopmam-naser 2>&1 > /dev/null

log "Creating Channel Block (dopmam-shifa)"
setEnv dopmam

RETRY_COUNT=0
rc=1
while [ $rc -ne 0 -a $RETRY_COUNT -lt 10 ] ; do
  sleep 1
  peer channel create -o localhost:10050 -c dopmam-shifa --ordererTLSHostnameOverride orderer.moh.ps -f "${PWD}/channel-artifacts/dopmam-shifa.tx" --outputBlock "${PWD}/channel-artifacts/dopmam-shifa.block" --tls --cafile "${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem" 2>&1 > /dev/null
  rc=$?
  RETRY_COUNT=$(expr $RETRY_COUNT + 1)
done

log "Creating Channel Block (dopmam-naser)"
RETRY_COUNT=0
rc=1
while [ $rc -ne 0 -a $RETRY_COUNT -lt 10 ] ; do
  sleep 1
  peer channel create -o localhost:10050 -c dopmam-naser --ordererTLSHostnameOverride orderer.moh.ps -f "${PWD}/channel-artifacts/dopmam-naser.tx" --outputBlock "${PWD}/channel-artifacts/dopmam-naser.block" --tls --cafile "${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem" 2>&1 > /dev/null
  rc=$?
  RETRY_COUNT=$(expr $RETRY_COUNT + 1)
done


log "Joining dopmam-shifa Channel from peer0.dopmam.moh.ps"
RETRY_COUNT=0
rc=1
while [ $rc -ne 0 -a $RETRY_COUNT -lt 10 ] ; do
  sleep 1
  peer channel join -b "${PWD}/channel-artifacts/dopmam-shifa.block" 2>&1 > /dev/null
  rc=$?
  RETRY_COUNT=$(expr $RETRY_COUNT + 1)
done

log "Joining dopmam-naser Channel from peer0.dopmam.moh.ps"
RETRY_COUNT=0
rc=1
while [ $rc -ne 0 -a $RETRY_COUNT -lt 10 ] ; do
  sleep 1
  peer channel join -b "${PWD}/channel-artifacts/dopmam-naser.block" 2>&1 > /dev/null
  rc=$?
  RETRY_COUNT=$(expr $RETRY_COUNT + 1)
done

log "Joining dopmam-shifa Channel from peer0.shifa.moh.ps"
setEnv shifa

RETRY_COUNT=0
rc=1
while [ $rc -ne 0 -a $RETRY_COUNT -lt 10 ] ; do
  sleep 1
  peer channel join -b "${PWD}/channel-artifacts/dopmam-shifa.block" 2>&1 > /dev/null
  rc=$?
  RETRY_COUNT=$(expr $RETRY_COUNT + 1)
done

log "Joining dopmam-naser Channel from peer0.naser.moh.ps"
setEnv naser

RETRY_COUNT=0
rc=1
while [ $rc -ne 0 -a $RETRY_COUNT -lt 10 ] ; do
  sleep 1
  peer channel join -b "${PWD}/channel-artifacts/dopmam-naser.block" 2>&1 > /dev/null
  rc=$?
  RETRY_COUNT=$(expr $RETRY_COUNT + 1)
done

# return the config export to configtx
export FABRIC_CFG_PATH=${PWD}/configtx

log "Generating connection profiles for peers"
./ccp-generate.sh
