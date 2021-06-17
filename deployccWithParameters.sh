#!/bin/bash

export EXPECTED_PARAM_COUNT=9

if [ $# -ne ${EXPECTED_PARAM_COUNT} ]
then
        echo "Wrong number of parameters for ${0}. Expected ${EXPECTED_PARAM_COUNT} parameter(s), but found $# parameters!" >&2
        exit
fi

export chaincode_source_path=${1}
export chaincode_name=${2}
export chaincode_sequence=${3}
export channel_id=${4}
export org_name=${5}
export orderer_address=${6}
export orderer_port=${7}
export orderer_name=${8}
export orderer_tls_cert=${9}

source .env

export chaincode_build_path=${chaincode_source_path}/build/install/chaincode
export chaincode_packages_path=$PWD/chaincode-packages

mkdir -p ${chaincode_packages_path}

pushd "${chaincode_source_path}" > /dev/null
./gradlew installDist
popd > /dev/null

setOrganization ${org_name}

peer lifecycle chaincode package "${chaincode_packages_path}/${chaincode_name}.tar.gz" --path "${chaincode_build_path}" --lang java --label ${chaincode_name}_${chaincode_sequence}

peer lifecycle chaincode install "${chaincode_packages_path}/${chaincode_name}.tar.gz"
peer lifecycle chaincode queryinstalled > installed.txt
package_id=$(sed -n "/${chaincode_name}_${chaincode_sequence}/{s/^Package ID: //; s/, Label:.*$//; p;}" installed.txt)
rm -f installed.txt

peer lifecycle chaincode approveformyorg -o ${orderer_address}:${orderer_port} --ordererTLSHostnameOverride ${orderer_name} --channelID ${channel_id} --name ${chaincode_name} --version ${chaincode_sequence} --package-id ${package_id} --sequence ${chaincode_sequence} --tls --cafile "${orderer_tls_cert}"
