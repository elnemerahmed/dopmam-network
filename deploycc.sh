#!/bin/bash

source .env

printInfo

export chaincode_source_path=${PWD}/../dopmam-chaincode
export chaincode_name=dopmam_smart_contract
export chaincode_sequence=1
export channel_id=dopmam-shifa
export org_name=dopmam
export orderer_address=localhost
export orderer_port=10050
export orderer_name=orderer.moh.ps
export orderer_tls_cert=${PWD}/organizations/ordererOrganizations/moh.ps/orderers/orderer.moh.ps/msp/tlscacerts/tlsca.moh.ps-cert.pem
export peers_info=(--peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/dopmam.moh.ps/peers/peer0.dopmam.moh.ps/tls/ca.crt" --peerAddresses localhost:8051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/shifa.moh.ps/peers/peer0.shifa.moh.ps/tls/ca.crt")

./deployccWithParameters.sh "${chaincode_source_path}" "${chaincode_name}" "${chaincode_sequence}" "${channel_id}" "${org_name}" "${orderer_address}" "${orderer_port}" "${orderer_name}" "${orderer_tls_cert}"

org_name=shifa
./deployccWithParameters.sh "${chaincode_source_path}" "${chaincode_name}" "${chaincode_sequence}" "${channel_id}" "${org_name}" "${orderer_address}" "${orderer_port}" "${orderer_name}" "${orderer_tls_cert}"


setOrganization dopmam

peer lifecycle chaincode commit -o ${orderer_address}:${orderer_port} --ordererTLSHostnameOverride ${orderer_name} --channelID ${channel_id} --name ${chaincode_name} --version ${chaincode_sequence} --sequence ${chaincode_sequence} --tls --cafile "${orderer_tls_cert}" "${peers_info[@]}"

peer lifecycle chaincode querycommitted --channelID ${channel_id} --name ${chaincode_name} --cafile "${orderer_tls_cert}"

c='{"function":"initLedger","Args":[]}'

peer chaincode invoke -o ${orderer_address}:${orderer_port} --ordererTLSHostnameOverride ${orderer_name} --tls --cafile "${orderer_tls_cert}" -C ${channel_id} -n ${chaincode_name} "${peers_info[@]}" -c "$c"

