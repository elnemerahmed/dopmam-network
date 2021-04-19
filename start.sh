#!/bin/bash

echo "$(tput setaf 3) _____   ____  _____  __  __          __  __ "
echo "|  __ \ / __ \|  __ \|  \/  |   /\   |  \/  |"
echo "| |  | | |  | | |__) | \  / |  /  \  | \  / |"
echo "| |  | | |  | |  ___/| |\/| | / /\ \ | |\/| |"
echo "| |__| | |__| | |    | |  | |/ ____ \| |  | |"
echo "|_____/ \____/|_|    |_|  |_/_/    \_\_|  |_|"
echo ""
echo "$(tput setaf 7)Authors: "
echo "  - Ahmed El Nemer: aelnemer1@smail.ucas.edu.ps"
echo "  - Waleed Mortaja: wmortaja1@smail.ucas.edu.ps"
echo "  - Ahmed Afifi:    aafifi4@smail.ucas.edu.ps$(tput sgr0)"
echo ""
echo ""

source .env

log "Stoping running Docker containers"
docker-compose -f "${PWD}/docker/docker-compose-ca.yaml" -f "${PWD}/docker/docker-compose-dopmam-network.yaml" down --volumes --remove-orphans 2>&1 > /dev/null

log "Removing previous generated artifacts"
rm -fr "${PWD}/channel-artifacts" 2>&1 > /dev/null
rm -fr "${PWD}/organizations" 2>&1 > /dev/null
rm -fr "${PWD}/ccp" 2>&1 > /dev/null
rm -fr "${PWD}/system-genesis-block" 2>&1 > /dev/null

echo '
{
    "name": "dopmam-network-${ORG_S}",
    "version": "1.0.0",
    "client": {
        "organization": "${ORG_C}",
        "connection": {
            "timeout": {
                "peer": {
                    "endorser": "300"
                }
            }
        }
    },
    "organizations": {
        "${ORG_C}": {
            "mspid": "${ORG_C}MSP",
            "peers": [
                "peer0.${ORG_S}.moh.ps"
            ],
            "certificateAuthorities": [
                "ca.${ORG_S}.moh.ps"
            ]
        }
    },
    "peers": {
        "peer0.${ORG_S}.moh.ps": {
            "url": "grpcs://localhost:${P0PORT}",
            "tlsCACerts": {
                "pem": "${PEERPEM}"
            },
            "grpcOptions": {
                "ssl-target-name-override": "peer0.${ORG_S}.moh.ps",
                "hostnameOverride": "peer0.${ORG_S}.moh.ps"
            }
        }
    },
    "certificateAuthorities": {
        "ca.${ORG_S}.moh.ps": {
            "url": "https://localhost:${CAPORT}",
            "caName": "ca-${ORG_S}",
            "tlsCACerts": {
                "pem": ["${CAPEM}"]
            },
            "httpOptions": {
                "verify": false
            }
        }
    }
}
' >> ${PWD}/ccp/ccp-template.json

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
./createOrg.sh naser localhost 12054 ca-naser 2>&1 > /dev/null

log "Creating Orderer Organization"
./createOrderer.sh orderer localhost 9054 ca-orderer 2>&1 > /dev/null

export FABRIC_CFG_PATH=${PWD}/configtx

log "Creating Genisis Block"
configtxgen -profile OrdererGenesis -channelID system-channel -outputBlock "${PWD}/system-genesis-block/genesis.block" 2>&1 > /dev/null

log "Installing and starting Docker Network containers (Peers & Organizations)"
docker-compose -f "${PWD}/docker/docker-compose-dopmam-network.yaml" up -d 2>&1 > /dev/null

log "Creating Channel Artifacts (dopmam-shifa)"
configtxgen -profile DopmamShifaChannel -outputCreateChannelTx "${PWD}/channel-artifacts/dopmam-shifa.tx" -channelID dopmam-shifa 2>&1 > /dev/null

log "Creating Channel Block (dopmam-shifa)"
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem
export CORE_PEER_LOCALMSPID="DopmamMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/dopmam.moh.ps/users/Admin@dopmam.moh.ps/msp
export CORE_PEER_ADDRESS=localhost:7051
export FABRIC_CFG_PATH=${PWD}/config

RETRY_COUNT=0
rc=1
while [ $rc -ne 0 -a $RETRY_COUNT -lt 10 ] ; do
  sleep 1
  peer channel create -o localhost:7050 -c dopmam-shifa --ordererTLSHostnameOverride orderer.moh.ps -f "${PWD}/channel-artifacts/dopmam-shifa.tx" --outputBlock "${PWD}/channel-artifacts/dopmam-shifa.block" --tls --cafile "${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem" 2>&1 > /dev/null
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

log "Joining dopmam-shifa Channel from peer0.shifa.moh.ps"
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem
export CORE_PEER_LOCALMSPID="ShifaMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/shifa.moh.ps/users/Admin@shifa.moh.ps/msp
export CORE_PEER_ADDRESS=localhost:9051
export FABRIC_CFG_PATH=${PWD}/config

RETRY_COUNT=0
rc=1
while [ $rc -ne 0 -a $RETRY_COUNT -lt 10 ] ; do
  sleep 1
  peer channel join -b "${PWD}/channel-artifacts/dopmam-shifa.block" 2>&1 > /dev/null
  rc=$?
  RETRY_COUNT=$(expr $RETRY_COUNT + 1)
done

# return the config export to configtx
export FABRIC_CFG_PATH=${PWD}/configtx

log "Generating connection profiles for peers"
./ccp-generate.sh
