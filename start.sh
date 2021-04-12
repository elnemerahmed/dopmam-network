#!/bin/bash

source .env

# Remove previous generated artifacts
rm -fr ./organizations/*
rm -fr ./system-genesis-block/*
rm -fr ./channel-artifacts/*
rm -fr ./anchor-artifacts/*

# Stop running Docker containers
docker-compose -f ./docker/docker-compose-ca.yaml -f ./docker/docker-compose-dopmam-network.yaml down --volumes --remove-orphans

# Install and start Docker containers
docker-compose -f ./docker/docker-compose-ca.yaml up -d

# Create DOPMAM

mkdir -p organizations/peerOrganizations/dopmam.moh.ps/

export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/dopmam.moh.ps/

fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-dopmam --tls.certfiles ${PWD}/organizations/fabric-ca/dopmam/tls-cert.pem

echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-dopmam.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-dopmam.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-dopmam.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-dopmam.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/msp/config.yaml

fabric-ca-client register --caname ca-dopmam --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/dopmam/tls-cert.pem

fabric-ca-client register --caname ca-dopmam --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/dopmam/tls-cert.pem

fabric-ca-client register --caname ca-dopmam --id.name dopmamadmin --id.secret dopmamadminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/dopmam/tls-cert.pem

mkdir -p organizations/peerOrganizations/dopmam.moh.ps/peers
mkdir -p organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps

fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-dopmam -M ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/msp --csr.hosts peer0.dopmam.moh.ps --tls.certfiles ${PWD}/organizations/fabric-ca/dopmam/tls-cert.pem

cp ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/msp/config.yaml ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/msp/config.yaml

fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-dopmam -M ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls --enrollment.profile tls --csr.hosts peer0.dopmam.moh.ps --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/dopmam/tls-cert.pem

cp ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls/ca.crt
cp ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls/signcerts/* ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls/server.crt
cp ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls/keystore/* ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls/server.key

mkdir ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/msp/tlscacerts
cp ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/msp/tlscacerts/ca.crt
mkdir ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/tlsca
cp ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/tlsca/tlsca.dopmam.moh.ps-cert.pem
mkdir ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/ca
cp ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/msp/cacerts/* ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/ca/ca.dopmam.moh.ps-cert.pem
mkdir -p organizations/peerOrganizations/dopmam.moh.ps/users
mkdir -p organizations/peerOrganizations/dopmam.moh.ps/users/User1@dopmam.moh.ps

fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca-dopmam -M ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/users/User1@dopmam.moh.ps/msp --tls.certfiles ${PWD}/organizations/fabric-ca/dopmam/tls-cert.pem

cp ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/msp/config.yaml ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/users/User1@dopmam.moh.ps/msp/config.yaml
mkdir -p organizations/peerOrganizations/dopmam.moh.ps/users/Admin@dopmam.moh.ps

fabric-ca-client enroll -u https://dopmamadmin:dopmamadminpw@localhost:7054 --caname ca-dopmam -M ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/users/Admin@dopmam.moh.ps/msp --tls.certfiles ${PWD}/organizations/fabric-ca/dopmam/tls-cert.pem

cp ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/msp/config.yaml ${PWD}/organizations/peerOrganizations/dopmam.moh.ps/users/Admin@dopmam.moh.ps/msp/config.yaml

# Create Shifa

mkdir -p organizations/peerOrganizations/shifa.moh.ps/

export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/shifa.moh.ps/

fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-shifa --tls.certfiles ${PWD}/organizations/fabric-ca/shifa/tls-cert.pem

echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-shifa.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-shifa.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-shifa.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-shifa.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/shifa.moh.ps/msp/config.yaml

fabric-ca-client register --caname ca-shifa --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/shifa/tls-cert.pem

fabric-ca-client register --caname ca-shifa --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/shifa/tls-cert.pem

fabric-ca-client register --caname ca-shifa --id.name shifaadmin --id.secret shifaadminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/shifa/tls-cert.pem

mkdir -p organizations/peerOrganizations/shifa.moh.ps/peers
mkdir -p organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps

fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-shifa -M ${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/msp --csr.hosts peer0.shifa.moh.ps --tls.certfiles ${PWD}/organizations/fabric-ca/shifa/tls-cert.pem

cp ${PWD}/organizations/peerOrganizations/shifa.moh.ps/msp/config.yaml ${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/msp/config.yaml

fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-shifa -M ${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls --enrollment.profile tls --csr.hosts peer0.shifa.moh.ps --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/shifa/tls-cert.pem

cp ${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/ca.crt
cp ${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/signcerts/* ${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/server.crt
cp ${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/keystore/* ${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/server.key
mkdir ${PWD}/organizations/peerOrganizations/shifa.moh.ps/msp/tlscacerts
cp ${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/shifa.moh.ps/msp/tlscacerts/ca.crt
mkdir ${PWD}/organizations/peerOrganizations/shifa.moh.ps/tlsca
cp ${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/shifa.moh.ps/tlsca/tlsca.shifa.moh.ps-cert.pem
mkdir ${PWD}/organizations/peerOrganizations/shifa.moh.ps/ca
cp ${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/msp/cacerts/* ${PWD}/organizations/peerOrganizations/shifa.moh.ps/ca/ca.shifa.moh.ps-cert.pem
mkdir -p organizations/peerOrganizations/shifa.moh.ps/users
mkdir -p organizations/peerOrganizations/shifa.moh.ps/users/User1@shifa.moh.ps

fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca-shifa -M ${PWD}/organizations/peerOrganizations/shifa.moh.ps/users/User1@shifa.moh.ps/msp --tls.certfiles ${PWD}/organizations/fabric-ca/shifa/tls-cert.pem

cp ${PWD}/organizations/peerOrganizations/shifa.moh.ps/msp/config.yaml ${PWD}/organizations/peerOrganizations/shifa.moh.ps/users/User1@shifa.moh.ps/msp/config.yaml
mkdir -p organizations/peerOrganizations/shifa.moh.ps/users/Admin@shifa.moh.ps

fabric-ca-client enroll -u https://shifaadmin:shifaadminpw@localhost:8054 --caname ca-shifa -M ${PWD}/organizations/peerOrganizations/shifa.moh.ps/users/Admin@shifa.moh.ps/msp --tls.certfiles ${PWD}/organizations/fabric-ca/shifa/tls-cert.pem

cp ${PWD}/organizations/peerOrganizations/shifa.moh.ps/msp/config.yaml ${PWD}/organizations/peerOrganizations/shifa.moh.ps/users/Admin@shifa.moh.ps/msp/config.yaml

# Create Orderer 

mkdir -p organizations/ordererOrganizations/moh.ps

export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/moh.ps

fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem

echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/ordererOrganizations/moh.ps/msp/config.yaml

fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem

fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem

mkdir -p organizations/ordererOrganizations/moh.ps/orderers
mkdir -p organizations/ordererOrganizations/moh.ps/orderers/moh.ps
mkdir -p organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps

fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp --csr.hosts orderer.moh.ps --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem

cp ${PWD}/organizations/ordererOrganizations/moh.ps/msp/config.yaml ${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/config.yaml

fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/tls --enrollment.profile tls --csr.hosts orderer.moh.ps --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem

cp ${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/tls/ca.crt
cp ${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/tls/signcerts/* ${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/tls/server.crt
cp ${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/tls/keystore/* ${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/tls/server.key
mkdir ${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts
cp ${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem
mkdir ${PWD}/organizations/ordererOrganizations/moh.ps/msp/tlscacerts
cp ${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem
mkdir -p organizations/ordererOrganizations/moh.ps/users
mkdir -p organizations/ordererOrganizations/moh.ps/users/Admin@moh.ps

fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/moh.ps/users/Admin@moh.ps/msp --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem

cp ${PWD}/organizations/ordererOrganizations/moh.ps/msp/config.yaml ${PWD}/organizations/ordererOrganizations/moh.ps/users/Admin@moh.ps/msp/config.yaml

export FABRIC_CFG_PATH=${PWD}/configtx

# Create Genisis Block
configtxgen -profile OrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block

# Install and start Docker containers
docker-compose -f ./docker/docker-compose-dopmam-network.yaml up -d

sleep 5

# Create Channel Artifacts
configtxgen -profile DopmamShifaChannel -outputCreateChannelTx ./channel-artifacts/dopmam-shifa.tx -channelID dopmam-shifa

# Create anchors
# configtxgen -profile DopmamShifaChannel -outputAnchorPeersUpdate ./channel-artifacts/dopmamanchors.tx -channelID dopmam-shifa -asOrg DopmamMSP
# configtxgen -profile DopmamShifaChannel -outputAnchorPeersUpdate ./channel-artifacts/shifaanchors.tx -channelID dopmam-shifa -asOrg ShifaMSP
		
# Create Channel Block
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem
export CORE_PEER_LOCALMSPID="DopmamMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/dopmam.moh.ps/users/Admin@dopmam.moh.ps/msp
export CORE_PEER_ADDRESS=localhost:7051
export FABRIC_CFG_PATH=${PWD}/config
peer channel create -o localhost:7050 -c dopmam-shifa --ordererTLSHostnameOverride orderer.moh.ps -f ./channel-artifacts/dopmam-shifa.tx --outputBlock ./channel-artifacts/dopmam-shifa.block --tls --cafile ${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem

# Join Channel From peer 0 Dopmam Org
peer channel join -b ./channel-artifacts/dopmam-shifa.block

# Join Channel From peer 0 Shifa Org
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem
export CORE_PEER_LOCALMSPID="ShifaMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/shifa.moh.ps/users/Admin@shifa.moh.ps/msp
export CORE_PEER_ADDRESS=localhost:9051
export FABRIC_CFG_PATH=${PWD}/config
peer channel join -b ./channel-artifacts/dopmam-shifa.block

# return the config export to configtx
export FABRIC_CFG_PATH=${PWD}/configtx

