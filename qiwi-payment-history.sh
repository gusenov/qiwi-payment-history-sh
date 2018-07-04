#!/bin/bash 

#set -x  # echo on

personId='__YOUR_PHONE_HERE__'
TokenHeadV2='__YOUR_AUTHORIZATION_TOKEN_HERE__'
token_tail_sso='__YOUR_COOKIE_TOKEN_HERE__'

for i in "$@"; do
	case $i in
		-p=*|--person=*)
			personId="${i#*=}"
			shift  # past argument=value
			;;
		-a=*|--authorization=*)
			TokenHeadV2="${i#*=}"
			shift  # past argument=value
			;;
		-c=*|--cookie=*)
			token_tail_sso="${i#*=}"
			shift  # past argument=value
			;;
		--default)
			DEFAULT=YES
			shift  # past argument with no value
			;;
		*)
			# unknown option
			;;
	esac
done

function payments() {
	local personId="$1"
	local TokenHeadV2="$2"
	local token_tail_sso="$3"
	local rows="$4"
	local nextTxnId="$5"
	local nextTxnDate="$6"
	
	local Host='edge.qiwi.com'
	local Connection='keep-alive'
	local Origin='https://qiwi.com'
	local Accept_Language='ru'
	local Authorization="TokenHeadV2 $TokenHeadV2"
	local Content_Type='application/json'
	local Accept='application/json'
	local User_Agent='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/66.0.3359.181 Chrome/66.0.3359.181 Safari/537.36'
	local Client_Software='WEB v4.36.0'
	local DNT='1'
	local Referer='https://qiwi.com/history'
	local Accept_Encoding='gzip, deflate, br'
	local Cookie="token-tail-sso.qiwi.com=$token_tail_sso;"

	if [ "$nextTxnId" == "null" ] || [ "$nextTxnDate" == "null" ]; then
		curl --silent --get "https://edge.qiwi.com/payment-history/v2/persons/$personId/payments" \
			--data-urlencode "rows=$rows" \
			--header "Host: $Host" \
			--header "Connection: $Connection" \
			--header "Origin: $Origin" \
			--header "Accept-Language: $Accept_Language" \
			--header "Authorization: $Authorization" \
			--header "Content-Type: $Content_Type" \
			--header "Accept: $Accept" \
			--header "User-Agent: $User_Agent" \
			--header "Client-Software: $Client_Software" \
			--header "DNT: $DNT" \
			--header "Referer: $Referer" \
			--header "Accept-Encoding: $Accept_Encoding" \
			--compressed \
			--header "Cookie: $Cookie"
	else
		curl --silent --get "https://edge.qiwi.com/payment-history/v2/persons/$personId/payments" \
			--data-urlencode "rows=$rows" \
			--data-urlencode "nextTxnId=$nextTxnId" \
			--data-urlencode "nextTxnDate=$nextTxnDate" \
			--header "Host: $Host" \
			--header "Connection: $Connection" \
			--header "Origin: $Origin" \
			--header "Accept-Language: $Accept_Language" \
			--header "Authorization: $Authorization" \
			--header "Content-Type: $Content_Type" \
			--header "Accept: $Accept" \
			--header "User-Agent: $User_Agent" \
			--header "Client-Software: $Client_Software" \
			--header "DNT: $DNT" \
			--header "Referer: $Referer" \
			--header "Accept-Encoding: $Accept_Encoding" \
			--compressed \
			--header "Cookie: $Cookie"
	fi
}

function loopPayments() {
	local personId="$1"
	local TokenHeadV2="$2"
	local token_tail_sso="$3"
	
	local response=$(payments "$personId" "$TokenHeadV2" "$token_tail_sso" "1" "null" "null")
	if [ -n "$response" ]; then
		local nextTxnId=$(echo "$response" | jq --raw-output '.nextTxnId')
		local nextTxnDate=$(echo "$response" | jq --raw-output '.nextTxnDate')
		
		while [ "$nextTxnId" != "null" ] && [ "$nextTxnDate" != "null" ]; do
			response=$(payments "$personId" "$TokenHeadV2" "$token_tail_sso" "1" "$nextTxnId" "$nextTxnDate")
			nextTxnId=$(echo "$response" | jq --raw-output '.nextTxnId')
			nextTxnDate=$(echo "$response" | jq --raw-output '.nextTxnDate')
			
			echo "${response}" | jq --compact-output '.data[]' | while read -r data; do
				txnId=$(echo "$data" | jq --raw-output '.txnId')
				type=$(echo "$data" | jq --raw-output '.type')

				mkdir -p "qiwi-payment-history/$personId/$txnId"
				echo "$data" | jq '.' > "qiwi-payment-history/$personId/$txnId/$type.json"
			done

		done
	fi
}

loopPayments "$personId" "$TokenHeadV2" "$token_tail_sso"

