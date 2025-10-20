#!/bin/bash
#
# Copyright NIT Warangal. All Rights Reserved.
#
# Script to bring down the network

function networkDown() {
  
  COMPOSE_FILES="-f docker/docker-compose-net.yaml"
  
  docker-compose ${COMPOSE_FILES} down --volumes --remove-orphans
  
  # Cleanup docker containers and volumes
  docker rm -f $(docker ps -aq --filter label=service=hyperledger-fabric) 2>/dev/null || true
  docker volume prune -f
  docker network prune -f
  
  # Remove generated artifacts
  rm -rf organizations/ordererOrganizations
  rm -rf organizations/peerOrganizations
  rm -rf system-genesis-block/*.block
  rm -rf channel-artifacts/*.tx
  rm -rf channel-artifacts/*.block
  
  echo "Network shut down completed"
}

networkDown
