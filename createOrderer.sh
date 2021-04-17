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
export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/${DOMAIN}
export FABRIC_CA_CLIENT_TLS_CERTFILES=${PWD}/organizations/fabric-ca/${org_name}/tls-cert.pem

# Crete directory structure
mkdir -p "${PWD}/organizations/fabric-ca/${org_name}"
mkdir -p "${PWD}/organizations/ordererOrganizations/${DOMAIN}"
mkdir -p "${PWD}/organizations/ordererOrganizations/${DOMAIN}/msp/tlscacerts"
mkdir -p "${PWD}/organizations/ordererOrganizations/${DOMAIN}/orderers/${DOMAIN}"
mkdir -p "${PWD}/organizations/ordererOrganizations/${DOMAIN}/orderers/${org_name_with_domain}"
mkdir -p "${PWD}/organizations/ordererOrganizations/${DOMAIN}/orderers/${org_name_with_domain}/msp/tlscacerts"
mkdir -p "${PWD}/organizations/ordererOrganizations/${DOMAIN}/users/Admin@${DOMAIN}"


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

fabric-ca-client enroll -u https://admin:adminpw@${org_ca_address}:${org_ca_port} --caname ${org_ca_name} 2>&1 > /dev/null

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
    OrganizationalUnitIdentifier: orderer" > "${PWD}/organizations/ordererOrganizations/${DOMAIN}/msp/config.yaml"

fabric-ca-client register --caname ${org_ca_name} --id.name orderer --id.secret ordererpw --id.type orderer 2>&1 > /dev/null

fabric-ca-client register --caname ${org_ca_name} --id.name ${org_name}admin --id.secret ${org_name}adminpw --id.type admin 2>&1 > /dev/null

fabric-ca-client enroll -u https://orderer:ordererpw@${org_ca_address}:${org_ca_port} --caname ${org_ca_name} -M "${PWD}/organizations/ordererOrganizations/${DOMAIN}/orderers/${org_name_with_domain}/msp" --csr.hosts ${org_name_with_domain} --csr.hosts ${org_ca_address} 2>&1 > /dev/null

cp "${PWD}/organizations/ordererOrganizations/${DOMAIN}/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/${DOMAIN}/orderers/${org_name_with_domain}/msp/config.yaml"

fabric-ca-client enroll -u https://orderer:ordererpw@${org_ca_address}:${org_ca_port} --caname ${org_ca_name} -M "${PWD}/organizations/ordererOrganizations/${DOMAIN}/orderers/${org_name_with_domain}/tls" --enrollment.profile tls --csr.hosts ${org_name_with_domain} --csr.hosts ${org_ca_address} 2>&1 > /dev/null

cp "${PWD}/organizations/ordererOrganizations/${DOMAIN}/orderers/${org_name_with_domain}/tls/tlscacerts"/* "${PWD}/organizations/ordererOrganizations/${DOMAIN}/orderers/${org_name_with_domain}/tls/ca.crt"
cp "${PWD}/organizations/ordererOrganizations/${DOMAIN}/orderers/${org_name_with_domain}/tls/signcerts"/* "${PWD}/organizations/ordererOrganizations/${DOMAIN}/orderers/${org_name_with_domain}/tls/server.crt"
cp "${PWD}/organizations/ordererOrganizations/${DOMAIN}/orderers/${org_name_with_domain}/tls/keystore"/* "${PWD}/organizations/ordererOrganizations/${DOMAIN}/orderers/${org_name_with_domain}/tls/server.key"
cp "${PWD}/organizations/ordererOrganizations/${DOMAIN}/orderers/${org_name_with_domain}/tls/tlscacerts"/* "${PWD}/organizations/ordererOrganizations/${DOMAIN}/orderers/${org_name_with_domain}/msp/tlscacerts/tlsca.${DOMAIN}-cert.pem"
cp "${PWD}/organizations/ordererOrganizations/${DOMAIN}/orderers/${org_name_with_domain}/tls/tlscacerts"/* "${PWD}/organizations/ordererOrganizations/${DOMAIN}/msp/tlscacerts/tlsca.${DOMAIN}-cert.pem"

fabric-ca-client enroll -u https://${org_name}admin:${org_name}adminpw@${org_ca_address}:${org_ca_port} --caname ${org_ca_name} -M "${PWD}/organizations/ordererOrganizations/${DOMAIN}/users/Admin@${DOMAIN}/msp" 2>&1 > /dev/null

cp "${PWD}/organizations/ordererOrganizations/${DOMAIN}/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/${DOMAIN}/users/Admin@${DOMAIN}/msp/config.yaml"

