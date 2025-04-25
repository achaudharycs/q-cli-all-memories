STAGE=prod
REGION=us-east-1
OIDC_ENDPOINT=https://$REGION.$STAGE.oidc.access.idaho.aws.a2z.com
DIR_START_URL=https://view.awsapps.com/start
CLIENT_REG=$(aws sso-oidc register-client --client-type public --client-name aws-toolkit-jetbrains-$(uuidgen) --region $REGION --scopes "codewhisperer:completions" "codewhisperer:analysis" "codewhisperer:transformations" --endpoint-url $OIDC_ENDPOINT)
DYNAMIC_CLIENT_ID=$(echo $CLIENT_REG | jq -r '.clientId')
DYNAMIC_CLIENT_SECRET=$(echo $CLIENT_REG | jq -r '.clientSecret')
DEVICE_AUTHORIZATION_INPUT='{
    "clientId": "'${DYNAMIC_CLIENT_ID}'",
    "clientSecret": "'${DYNAMIC_CLIENT_SECRET}'",
    "startUrl": "'${DIR_START_URL}'"
}'
DEVICE_AUTH_RESP=$(curl -d "${DEVICE_AUTHORIZATION_INPUT}" -H 'Content-Type: application/json' -X POST ${OIDC_ENDPOINT}/device_authorization)
URI_WITH_QUOTES=$(echo $DEVICE_AUTH_RESP | jq '.verificationUriComplete')
URI="${URI_WITH_QUOTES:1:${#URI_WITH_QUOTES}-2}"
echo $URI
open -u $URI
echo "Enter Y after authenticated to continue"
read input
if [ "$input" = "Y" ] || [ "$input" = "y" ]; then
    DEVICE_CODE=$(echo $DEVICE_AUTH_RESP | jq -r '.deviceCode')
    CREATE_TOKEN_INPUT='{
                "clientId": "'${DYNAMIC_CLIENT_ID}'",
                "clientSecret": "'${DYNAMIC_CLIENT_SECRET}'",
                "grantType": "urn:ietf:params:oauth:grant-type:device_code",
                "deviceCode": "'${DEVICE_CODE}'"
            }'

    TOKEN=$(curl -d "${CREATE_TOKEN_INPUT}" -H 'Content-Type: application/json' -X POST ${OIDC_ENDPOINT}/token)
    # echo "ACCESS Token= $(echo $TOKEN | jq '.accessToken')"
    echo "export BEARER_TOKEN=$(echo $TOKEN | jq '.accessToken')"
    echo "export ENDPOINT=https://rts.gamma-us-east-1.codewhisperer.ai.aws.dev/"
fi