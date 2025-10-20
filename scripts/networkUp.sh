#!/bin/bash
#
# Copyright NIT Warangal. All Rights Reserved.
#
# Script to bring up the network

function createOrgs() {
  echo "Generating certificates using cryptogen tool"
  
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. Exiting..."
    exit 1
  fi
  
  echo "##########################################################"
  echo "##### Generate certificates using cryptogen tool #########"
  echo "##########################################################"

  if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

  set -x
  cryptogen generate --config=./crypto-config.yaml --output="organizations"
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi

  echo "##########################################################"
  echo "############ Create Org3 Identities ######################"
  echo "##########################################################"
}

function createConsortium() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found."
    exit 1
  fi

  echo "#########  Generating Orderer Genesis block ##############"

  set -x
  configtxgen -profile ThreeOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi
}

function networkUp() {
  
  if [ ! -d "organizations/peerOrganizations" ]; then
    createOrgs
    createConsortium
  fi

  COMPOSE_FILES="-f docker/docker-compose-net.yaml"

  docker-compose ${COMPOSE_FILES} up -d 2>&1

  docker ps -a
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start network"
    exit 1
  fi
}

# Generate crypto material
createOrgs

# Generate genesis block
createConsortium

# Bring up the network
networkUp
