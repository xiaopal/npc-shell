#! /bin/bash

# Environment Variables:
# - NPC_API_ENDPOINT
# - NPC_API_KEY
# - NPC_API_SECRET
# - NPC_API_TOKEN
# - NPC_NOS_ENDPOINT

[ -z "$NPC_API_ENDPOINT" ] && NPC_API_ENDPOINT="https://open.c.163.com"
[ -z "$NPC_NOS_ENDPOINT" ] && NPC_NOS_ENDPOINT="https://nos-eastchina1.126.net"

([ -z "$NPC_API_KEY" ] || [ -z "$NPC_API_SECRET" ]) && if [ -f ./api.key ]; then
	NPC_API_KEY="$(jq -r '.app_key//.api_key//empty' ./api.key)"
	NPC_API_SECRET="$(jq -r '.app_secret//.api_secret//empty' ./api.key)"
elif [ -f ~/.npc/api.key ]; then
	NPC_API_KEY="$(jq -r '.app_key//.api_key//empty' ~/.npc/api.key)"
	NPC_API_SECRET="$(jq -r '.app_secret//.api_secret//empty' ~/.npc/api.key)"
fi 

do_http(){
	local METHOD="$1" URI="$2"; shift && shift	
	[ ! -z "$NPC_DEBUG" ] && echo "curl -s -k -X '$METHOD' $(printf "'%s' " "$@") '$URI'" >&2
	http_headers(){
		jq -sR 'split("\r\n") | {
			status: (.[0]|capture("^HTTP/(1.0|1.1) +(?<code>[0-9]+) +*(?<text>.+)$")//{code:"000"}),
			headers: (.[1:]|map(capture("^(?<key>[^:]+): *(?<value>.+)$"))|from_entries)
		}'
	}	
	local RESPONSE="$( 
		exec 3> >(export METHOD URI;jq -sc '{method: env.METHOD, uri: env.URI} + (.[0]//{}) + { raw:.[1], body:.[2] }')
		export BODY_RAW="$(curl -s -k -D >(http_headers >&3) -X "$METHOD" "$@" "$URI" | base64 -w 0)"
		export BODY=$(base64 -d <<<"$BODY_RAW")
		jq -n 'env.BODY_RAW, env.BODY' >&3 )"
	jq -r '"HTTP \(.status.code) \(.status.text) - \(.method) \(.uri)"'<<<"$RESPONSE" >&2 && echo "$RESPONSE" 
}

check_http_response(){
	local RESPONSE="$(cat -)" FILTER="$1" ERROR_OUTPUT="$2" && [ -z "$RESPONSE" ] && return 1
	do_output(){
		if [ "$FILTER" = '.raw' ]; then
			jq -ecr ".raw"<<<"$RESPONSE" | base64 -d || return 1
		elif [ ! -z "$FILTER" ]; then
			jq -ecr "$FILTER"<<<"$RESPONSE" || return 1 
		fi
		return 0
	}
	if [[ "$(jq -r '.status.code'<<<"$RESPONSE")" = 20* ]]; then
		[ ! -z "$FILTER" ] && {
			do_output  || return 1
		} 
		return 0
	else
		[ ! -z "$FILTER" ] && [ "$ERROR_OUTPUT" != "false" ] && {
			if [ ! -z "$ERROR_OUTPUT" ]; then
				do_output >"$ERROR_OUTPUT" 
			else
				do_output
			fi
		}
		return 1
	fi
}

api_http(){
	local METHOD="$1" URI="$2" && shift && shift
	local ARGS=("$@")

	local API_CREDENTIAL API_TOKEN="$NPC_API_TOKEN"
    [ ! -z "$NPC_API_KEY" ] && [ ! -z "$NPC_API_SECRET" ] && {
		API_CREDENTIAL="$(
			export NPC_API_KEY NPC_API_SECRET
			jq -nc '{app_key: env.NPC_API_KEY,app_secret: env.NPC_API_SECRET}'
		)"
		[ -z "$API_TOKEN" ] && API_TOKEN="$(mkdir -p ~/.npc; cd ~/.npc; pwd)/api.token.$NPC_API_KEY"
	}
	
	[[ "$URI" =~ ^(http|https)'://' ]] || URI="${NPC_API_ENDPOINT%/}/${URI#/}"
	local API_ENDPOINT API_PROTO API_HOSTNAME \
		&& IFS=/ read -r API_PROTO _ API_HOSTNAME _ <<<"$URI" \
		&& API_ENDPOINT="$API_PROTO//$API_HOSTNAME"

	do_auth(){
		[ -z "$API_CREDENTIAL" ] && {
			echo 'api.key required'>&2
			return 1
		}

		do_http POST "$API_ENDPOINT/api/v1/token" -d "$API_CREDENTIAL" -H 'Content-Type: application/json'| check_http_response '.body' false > $API_TOKEN && return 0 || {
			 cat $API_TOKEN >&2 && echo >&2 && rm -f $API_TOKEN
			 return 1
		}
	}

	do_api(){
		[ ! -z "$API_TOKEN" ] && {
			[ ! -f $API_TOKEN ] && { do_auth || return 1; }
			local TOKEN=$(jq -r '.token//empty' $API_TOKEN)
		}
		do_http "$METHOD" "$URI" ${TOKEN:+-H "Authorization: Token $TOKEN"} -H 'Content-Type: application/json' "${ARGS[@]}"
	}

	local RESPONSE=$(do_api)
	
	[ "$(check_http_response '.status.code'<<<"$RESPONSE")" = "401" ] && {
		rm -f $API_TOKEN
		RESPONSE=$(do_api)
	}
	echo "$RESPONSE"
}

nos_http(){
	local ARGS=() METHOD="$1" URI="$2" && shift && shift

	[ ! -z "$NPC_API_KEY" ] && [ ! -z "$NPC_API_SECRET" ] || {
		echo 'api.key required'>&2
		return 1
	}

	[[ "$URI" =~ ^(http|https)'://' ]] || URI="${NPC_NOS_ENDPOINT%/}/${URI#/}"
	local NOS_ENDPOINT NOS_PROTO NOS_HOSTNAME NOS_BUCKET NOS_PATH NOS_QUERY
	IFS=/ read -r NOS_PROTO _ NOS_HOSTNAME NOS_PATH <<<"$URI" \
		&& NOS_PROTO="$NOS_PROTO//" \
		&& IFS=? read -r NOS_PATH NOS_QUERY <<<"$NOS_PATH" \
		&& IFS=/ read -r NOS_BUCKET NOS_PATH <<<"$NOS_PATH" \
		&& NOS_ENDPOINT="$NOS_PROTO$NOS_HOSTNAME" \
		&& URI="$NOS_PROTO${NOS_BUCKET:+$NOS_BUCKET.}$NOS_HOSTNAME/$NOS_PATH${NOS_QUERY:+?$NOS_QUERY}"

	local NOS_HEADERS DATA CONTENT_TYPE CONTENT_MD5 NOS_DATE NOS_ENTITY_TYPE
	while true; do 
		local ARG="$1"; shift || break
		case "$ARG" in
		"-H"|"--header")
			local HEADER="$1"; shift || break
			local HEADER_NAME HEADER_VALUE && IFS=': ' read -r HEADER_NAME HEADER_VALUE <<<"$HEADER" && {
				[[ "${HEADER_NAME,,}" = "x-nos-"* ]] && NOS_HEADERS="$NOS_HEADERS${HEADER_NAME,,}:$HEADER_VALUE"$'\n'
				[[ "${HEADER_NAME,,}" = "content-type" ]] && CONTENT_TYPE="$HEADER_VALUE"
				[[ "${HEADER_NAME,,}" = "content-md5" ]] && CONTENT_MD5="$HEADER_VALUE"
				[[ "${HEADER_NAME,,}" = "date" ]] && NOS_DATE="$HEADER_VALUE"
				ARGS=("${ARGS[@]}" "-H" "$HEADER_NAME: $HEADER_VALUE")
			}
			;;
		"-d"|"--data")
			DATA="$1"; shift || break
			ARGS=("${ARGS[@]}" "--data-binary" "$DATA")
			;;
		"--xml")
			NOS_ENTITY_TYPE='xml'
			;;
		"--json")
			NOS_ENTITY_TYPE='json'
			;;
		*)
			ARGS=("${ARGS[@]}" "$ARG")
			;;
		esac
	done
	[ -z "$NOS_ENTITY_TYPE" ] && NOS_ENTITY_TYPE="json"
	NOS_HEADERS="${NOS_HEADERS}x-nos-entity-type:$NOS_ENTITY_TYPE"$'\n'
	ARGS=("${ARGS[@]}" "-H" "x-nos-entity-type: $NOS_ENTITY_TYPE")

	[ -z "$NOS_DATE" ] && {
		NOS_DATE="$(date -Ru | sed s/+0000/GMT/)"
		ARGS=("${ARGS[@]}" "-H" "Date: $NOS_DATE")
	}
	[ -z "$CONTENT_TYPE" ] && {
		ARGS=("${ARGS[@]}" "-H" "Content-Type:")
	}
	[ -z "$CONTENT_MD5" ] && [ ! -z "$DATA" ] && {
		read -r CONTENT_MD5 _ <<<"$(([[ "$DATA" = "@"* ]] && cat ${DATA#@} || echo -n "$DATA")| md5sum)" \
			&& ARGS=("${ARGS[@]}" "-H" "Content-MD5: $CONTENT_MD5")
	}
	[ ! -z "$NOS_HEADERS" ] && NOS_HEADERS="$(echo -n "$NOS_HEADERS"|sort)"$'\n'
	
	local NOS_RESOURCE="/${NOS_BUCKET:+$NOS_BUCKET/}${NOS_PATH//'/'/'%2F'}" NOS_SUBRESOURCES
	[ ! -z "$NOS_QUERY" ] && while IFS='=' read -r -d '&' PARAM_NAME PARAM_VALUE; do
		[[ "$PARAM_NAME" =~ ^(acl|location|versioning|versions|versionId|uploadId|uploads|partNumber|delete|deduplication)$ ]] \
			&& NOS_SUBRESOURCES="$NOS_SUBRESOURCES$PARAM_NAME${PARAM_VALUE:+=$PARAM_VALUE}"$'\n'
	done <<<"$NOS_QUERY&"
	[ ! -z "$NOS_SUBRESOURCES" ] && NOS_SUBRESOURCES="$(echo -n "$NOS_SUBRESOURCES"|sort)" \
		&& NOS_RESOURCE="$NOS_RESOURCE?${NOS_SUBRESOURCES//$'\n'/&}"

	local NOS_SIGNATURE="$(printf '%s\n%s\n%s\n%s\n%s%s' \
			"$METHOD" "$CONTENT_MD5" "$CONTENT_TYPE" "$NOS_DATE" "$NOS_HEADERS" "$NOS_RESOURCE" \
		| openssl sha256 -hmac "$NPC_API_SECRET" -binary | base64)"
	ARGS=("${ARGS[@]}" "-H" "Authorization: NOS $NPC_API_KEY:$NOS_SIGNATURE")

	do_http "$METHOD" "$URI" "${ARGS[@]}"
}

do_action(){
    local ACTION FILTER FIXED_ACTION

	[[ "$0" =~ api(.sh)?$ ]] && FIXED_ACTION="api"
	[[ "$0" =~ nos(.sh)?$ ]] && FIXED_ACTION="nos"
	[ ! -z "$FIXED_ACTION" ] && ACTION="$FIXED_ACTION" || {
		[[ "$1" =~ ^(api|nos)$ ]] && ACTION="$1" && shift
	} 

	local FILTER_FUNCTIONS='
		. as $response |
		def status:
			$response.status.code;
		def headers:
			$response.headers;
		def body:
			$response.body;
		def text:
			$response.body;
		def json: 
			(try $response.body|fromjson);
	'

	if [[ "$2" =~ ^(GET|PUT|POST|DELETE|HEAD)$ ]]; then
		FILTER="$FILTER_FUNCTIONS$1" && shift
	elif [[ "$1" =~ ^(GET|PUT|POST|DELETE|HEAD)$ ]]; then
		FILTER=".raw"
	else
		{
			[ "$FIXED_ACTION" = "api" ] && echo "Usage: $(basename $0) (GET|PUT|POST|DELETE|HEAD) /api/v1/namespaces [data]" >&2
			[ "$FIXED_ACTION" = "nos" ] && echo "Usage: $(basename $0) (GET|PUT|POST|DELETE|HEAD) /<bucket>/ [data]" >&2
			[ -z "$FIXED_ACTION" ] && {
				echo "Usage: $(basename $0) api (GET|PUT|POST|DELETE|HEAD) /api/v1/namespaces [data]" >&2
				echo "       $(basename $0) nos (GET|PUT|POST|DELETE|HEAD) /<bucket>/ [data]"
			}
		} >&2
		return 1
	fi

	local ARGS=() METHOD="$1" URI="$2" && shift && shift
	[[ "$METHOD" =~ ^(PUT|POST)$ ]] && DATA="$1" && {
		ARGS=("${ARGS[@]}" "-d" "$DATA")
		shift
	}
	[ "$METHOD" = "HEAD" ] && ARGS=("-I" "${ARGS[@]}")
	ARGS=("${ARGS[@]}" "$@")
	"${ACTION:-api}_http" "$METHOD" "$URI" "${ARGS[@]}" | check_http_response "$FILTER" /dev/fd/2 && return 0 || return 1
}

api(){
	do_action api "$@"
}

nos(){
	do_action nos "$@"
}

([ "${BASH_SOURCE[0]}" = "$0" ] || [ -z "${BASH_SOURCE[0]}" ]) && do_action "$@"
