#!/bin/bash
#
# Copyright NIT Warangal. All Rights Reserved.
#
# Script to bring up the NIT Warangal Academic Records Blockchain Network

export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx
export VERBOSE=false

# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  network.sh <Mode> [Flags]"
  echo "    <Mode>"
  echo "      - 'up' - bring up fabric orderer and peer nodes."
  echo "      - 'down' - clear the network with docker-compose down"
  echo "      - 'restart' - restart the network"
  echo
  echo "    Flags:"
  echo "    -ca <use CAs> -  create Certificate Authorities to generate certificates"
  echo "    -c <channel name> - channel name to use (defaults to \"academic-records-channel\")"
  echo "    -s <dbtype> - the database backend to use: goleveldb (default) or couchdb"
  echo "    -verbose - verbose mode"
  echo
  echo " Examples:"
  echo "   network.sh up"
  echo "   network.sh up -ca"
  echo "   network.sh down"
}

# Parse commandline args
while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp
    exit 0
    ;;
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -ca )
    CRYPTO="Certificate Authorities"
    ;;
  -s )
    DATABASE="$2"
    shift
    ;;
  -verbose )
    VERBOSE=true
    ;;
  up )
    MODE="up"
    ;;
  down )
    MODE="down"
    ;;
  restart )
    MODE="restart"
    ;;
  * )
    echo "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done

# Determine mode
if [ "$MODE" == "up" ]; then
  echo "Starting nodes with CLI timeout of '5' tries and CLI delay of '3' seconds"
  ./scripts/networkUp.sh
elif [ "$MODE" == "down" ]; then
  echo "Stopping network"
  ./scripts/networkDown.sh
elif [ "$MODE" == "restart" ]; then
  echo "Restarting network"
  ./scripts/networkDown.sh
  ./scripts/networkUp.sh
else
  printHelp
  exit 1
fi
