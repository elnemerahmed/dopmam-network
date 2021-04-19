#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' ${1}`"
}

function json_ccp {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    sed -e "s/\${ORG_S}/${1}/" \
        -e "s/\${ORG_C}/${2}/" \
        -e "s/\${P0PORT}/${3}/" \
        -e "s/\${CAPORT}/${4}/" \
        -e "s#\${PEERPEM}#${PP}#" \
        -e "s#\${CAPEM}#${CP}#" \
        template/ccp-template.json
}

function org_ccp {
    ORG_S=${1}
    ORG_C=${2}
    P0PORT=${3}
    CAPORT=${4}
    PEERPEM=organizations/peerOrganizations/${1}.moh.ps/tlsca/tlsca.${1}.moh.ps-cert.pem
    CAPEM=organizations/peerOrganizations/${1}.moh.ps/ca/ca.${1}.moh.ps-cert.pem

    echo "$(json_ccp ${ORG_S} ${ORG_C} ${P0PORT} ${CAPORT} ${PEERPEM} ${CAPEM})" > ./ccp/connection-${1}.json
}

org_ccp dopmam Dopmam 7051 7054
org_ccp shifa Shifa 8051 8054
org_ccp naser Naser 12051 12054