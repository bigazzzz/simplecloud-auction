#!/bin/bash

bold=$(tput bold)
underline=$(tput smul)
italic=$(tput sitm)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
red=$(tput setaf 1)
reset=$(tput sgr0)

SLEEPTIME=600
MESSAGE_COLOR=$reset
PREVIOUS_PRICE_DISCOUNT=100

echo "Enter your credentials on simplecloud.ru"
read -p "Login: " LOGIN
read -s -p "Password: " PASSWORD
BEARER_TOKEN=$(curl -d "{\"login\":\"$LOGIN\",\"password\":\"$PASSWORD\"}" -X POST -H'Content-Type:application/json;charset=UTF-8' -s https://simplecloud.ru/api/v3/auth/login | jq -r '.session_key')
echo

PRICE_START=$(curl -s -H"Authorization: Bearer $BEARER_TOKEN" https://simplecloud.ru/api/v3/auction\?per_page\=1000 | jq -r '.lots[0].start_price' | sed 's/\"//g' | sed 's/\.00//g')

echo "${green}----------------------------------------------------------------------"
curl -s -H"Authorization: Bearer $BEARER_TOKEN" https://simplecloud.ru/api/v3/auction\?per_page\=1000 | jq -r '.lots[0] | @sh "Lot price - \(.start_price). Started at \(.started)\nLot config - \(.size.vcpus)/\(.size.ram)/\(.size.disk)"' | tr -d "'"
echo "----------------------------------------------------------------------${reset}"

echo "**********************************************************************"
echo "|        DATE         | PERIOD | YEAR PRICE | MONTH PRICE | DISCOUNT |"
while [ 1=1 ]; do
  PRICE=$(curl -s -H"Authorization: Bearer $BEARER_TOKEN" https://simplecloud.ru/api/v3/auction\?per_page\=1000 | jq '.lots[0] .price' | sed 's/\"//g' | sed 's/\.00//g')
  let PRICE_DISCOUNT=100-$PRICE*100/$PRICE_START
  let PRICE_MONTH=$PRICE/12
  if [ $PRICE_DISCOUNT -ge 50 ]; then
    echo -ne '\007'
    SLEEPTIME=1
    MESSAGE_COLOR=$red
  elif [ $PRICE_DISCOUNT -ge 40 ]; then
    SLEEPTIME=15
    MESSAGE_COLOR=$red
  elif [ $PRICE_DISCOUNT -ge 30 ]; then
    SLEEPTIME=60
    MESSAGE_COLOR=$yellow
  elif [ $PRICE_DISCOUNT -ge 20 ]; then
    SLEEPTIME=120
    MESSAGE_COLOR=$green
  elif [ $PRICE_DISCOUNT -lt 20 ]; then
    if [ $PRICE_DISCOUNT -lt $PREVIOUS_PRICE_DISCOUNT ]; then
      SLEEPTIME=600
      MESSAGE_COLOR=$reset
      echo
    fi
  fi
  printf "\r${MESSAGE_COLOR}| $(date +"%T %m-%d-%Y") | %5ds | %6d RUB | %7d RUB | %7d%% |${reset}" $SLEEPTIME $PRICE $PRICE_MONTH $PRICE_DISCOUNT
  PREVIOUS_PRICE_DISCOUNT=$PRICE_DISCOUNT
  sleep $SLEEPTIME
done
