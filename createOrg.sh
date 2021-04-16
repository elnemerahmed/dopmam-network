#!/bin/bash

export EXPECTED_PARAM_COUNT=4
export DOMAIN=moh.ps

if [ $# -ne ${EXPECTED_PARAM_COUNT} ]
then
	echo "Wrong number of parameters for ${0}. Expected ${EXPECTED_PARAM_COUNT} parameter(s), but found $# parameters!" >&2
	exit
fi

export org_name=${1,} # converts the first character in input#1 to lowercase
export org_ca_address=${2}
export org_ca_port=${3}
export org_ca_name=${4}

source .env

export org_name_with_domain=${org_name}.${DOMAIN}
export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/${org_name_with_domain}

# Crete directory structure
mkdir -p "${PWD}/organizations/fabric-ca/${org_name}"
mkdir -p "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/ca"
mkdir -p "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/msp/cacerts"
mkdir -p "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/msp/tlscacerts"
mkdir -p "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/peers/peer0.${org_name_with_domain}"
mkdir -p "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/tlsca"
mkdir -p "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/users/Admin@${org_name_with_domain}"
mkdir -p "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/users/User1@${org_name_with_domain}"

#TODO use inotifywaint to efficiently wait for the appearance of a file instead of fixed time interval polling. Becareful not to miss the file if already exist. see (https://unix.stackexchange.com/a/407301), (https://stackoverflow.com/a/53436784) and whatever you find useful.
RETRY_COUNT=0
while : ; do
  if [ ! -f "${PWD}/organizations/fabric-ca/${org_name}/tls-cert.pem" -a $RETRY_COUNT -lt 10 ]; then
    sleep 1
    RETRY_COUNT=$(expr $RETRY_COUNT + 1)
  else
    break
  fi
done

fabric-ca-client enroll -u https://admin:adminpw@${org_ca_address}:${org_ca_port} --caname ${org_ca_name} --tls.certfiles "${PWD}/organizations/fabric-ca/${org_name}/tls-cert.pem"

echo "NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/${org_ca_address}-${org_ca_port}-${org_ca_name}.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/${org_ca_address}-${org_ca_port}-${org_ca_name}.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/${org_ca_address}-${org_ca_port}-${org_ca_name}.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/${org_ca_address}-${org_ca_port}-${org_ca_name}.pem
    OrganizationalUnitIdentifier: orderer" > "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/msp/config.yaml"

fabric-ca-client register --caname ${org_ca_name} --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/${org_name}/tls-cert.pem"

fabric-ca-client register --caname ${org_ca_name} --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/${org_name}/tls-cert.pem"

fabric-ca-client register --caname ${org_ca_name} --id.name ${org_name}admin --id.secret ${org_name}adminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/${org_name}/tls-cert.pem"

fabric-ca-client enroll -u https://peer0:peer0pw@${org_ca_address}:${org_ca_port} --caname ${org_ca_name} -M "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/peers/peer0.${org_name_with_domain}/msp" --csr.hosts peer0.${org_name_with_domain} --tls.certfiles "${PWD}/organizations/fabric-ca/${org_name}/tls-cert.pem"

cp "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/msp/config.yaml" "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/peers/peer0.${org_name_with_domain}/msp/config.yaml"

fabric-ca-client enroll -u https://peer0:peer0pw@${org_ca_address}:${org_ca_port} --caname ${org_ca_name} -M "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/peers/peer0.${org_name_with_domain}/tls" --enrollment.profile tls --csr.hosts peer0.${org_name_with_domain} --csr.hosts ${org_ca_address} --tls.certfiles "${PWD}/organizations/fabric-ca/${org_name}/tls-cert.pem"

cp "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/peers/peer0.${org_name_with_domain}/tls/tlscacerts"/* "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/peers/peer0.${org_name_with_domain}/tls/ca.crt"
cp "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/peers/peer0.${org_name_with_domain}/tls/signcerts"/* "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/peers/peer0.${org_name_with_domain}/tls/server.crt"
cp "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/peers/peer0.${org_name_with_domain}/tls/keystore"/* "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/peers/peer0.${org_name_with_domain}/tls/server.key"
cp "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/peers/peer0.${org_name_with_domain}/tls/tlscacerts"/* "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/msp/tlscacerts/ca.crt"
cp "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/peers/peer0.${org_name_with_domain}/tls/tlscacerts"/* "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/tlsca/tlsca.${org_name_with_domain}-cert.pem"
cp "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/peers/peer0.${org_name_with_domain}/msp/cacerts"/* "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/ca/ca.${org_name_with_domain}-cert.pem"

fabric-ca-client enroll -u https://user1:user1pw@${org_ca_address}:${org_ca_port} --caname ${org_ca_name} -M "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/users/User1@${org_name_with_domain}/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/${org_name}/tls-cert.pem"

cp "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/msp/config.yaml" "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/users/User1@${org_name_with_domain}/msp/config.yaml"

fabric-ca-client enroll -u https://${org_name}admin:${org_name}adminpw@${org_ca_address}:${org_ca_port} --caname ${org_ca_name} -M "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/users/Admin@${org_name_with_domain}/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/${org_name}/tls-cert.pem"

cp "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/msp/config.yaml" "${PWD}/organizations/peerOrganizations/${org_name_with_domain}/users/Admin@${org_name_with_domain}/msp/config.yaml"
