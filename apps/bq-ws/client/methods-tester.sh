#!/bin/bash

HOST=${THOST:-"localhost"}
# test if TPORT env var exists, if not use default 8080
PORT=${TPORT:-"8080"}
echo "Testing $HOST:$PORT..."

# read methods from ../docs/README.md
# METHODS=$(grep -oP '(?<=### ).*' ../docs/README.md)


mapfile -t METHODS < <(
  awk '
  /```examples/ {flag=1; next}
  /```/ {flag=0}
  flag && /^[A-Z]+[[:space:]]+\// {print}
  ' ../docs/README.md
)

curl http://$HOST:$PORT/ -i
echo -e "\n"

for METHOD in "${METHODS[@]}"; do
    # echo "Testing method: $METHOD"

    read -r VERB URL_PATH <<< "$METHOD"
    echo "Testing $VERB  http://$HOST:$PORT$URL_PATH"
    # invoke method and test response status code is 200

    RESPONSE=$(curl -s -w "\n%{http_code}" -X $VERB "http://$HOST:$PORT$URL_PATH" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json")
    
    BODY=$(echo "$RESPONSE" | sed '$d')
    STATUS=$(echo "$RESPONSE" | tail -n 1)
    
    if [ "$STATUS" -eq 200 ] && [ "$BODY" != '["No data found"]' ]; then
        echo "SUCCESS: Status code 200 and data found"
    else
        echo -e "\033[1mFAILURE\033[0m: Status code $STATUS or response is '$BODY'"
    fi
    echo -e "\n"

done

