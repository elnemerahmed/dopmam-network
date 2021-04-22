#!/bin/bas

export FABRIC_CFG_PATH=$PWD/config

peer lifecycle chaincode package dopmam_simple.tar.gz --path "$PWD/../dopmam-chaincode/build/install/chaincode" --lang java --label dopmam_simple_1.0

export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="DopmamMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/dopmam.moh.ps/users/Admin@dopmam.moh.ps/msp
export CORE_PEER_ADDRESS=localhost:7051

peer lifecycle chaincode install dopmam_simple.tar.gz

peer lifecycle chaincode queryinstalled

export CC_PACKAGE_ID=dopmam_simple_1.0:732e2ccd9f1d352804fb395d8ac0d42641f102afdbb352c711efe572114b992c

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.moh.ps --channelID dopmam-shifa --name dopmam_simple --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile "${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem"


peer lifecycle chaincode checkcommitreadiness --channelID dopmam-shifa --name dopmam_simple --version 1.0 --sequence 1 --tls --cafile "${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem" --output json



export CORE_PEER_LOCALMSPID="ShifaMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/shifa.moh.ps/users/Admin@shifa.moh.ps/msp
export CORE_PEER_ADDRESS=localhost:9051

peer lifecycle chaincode install dopmam_simple.tar.gz
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.moh.ps --channelID dopmam-shifa --name dopmam_simple --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile "${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem"

peer lifecycle chaincode checkcommitreadiness --channelID dopmam-shifa --name dopmam_simple --version 1.0 --sequence 1 --tls --cafile "${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem" --output json


peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.moh.ps --channelID dopmam-shifa --name dopmam_simple --version 1.0 --sequence 1 --tls --cafile "${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem" --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/ca.crt"


peer lifecycle chaincode querycommitted --channelID dopmam-shifa --name dopmam_simple --cafile "${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem"

c='{"function":"initLedger","Args":[]}'
c='{"function":"GetAllSimplePatients","Args":[]}'
c='{"function":"CreateSimplePatient","Args":["54321", "Samy", "4/4/2004"]}'
c='{"function":"GetAllSimplePatients","Args":[]}'
c='{"function":"DeleteSimplePatient","Args":["123456789"]}'
c='{"function":"GetAllSimplePatients","Args":[]}'

peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.moh.ps --tls --cafile "${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem" -C dopmam-shifa -n dopmam_simple  --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/ca.crt" -c "$c"


