#!/bin/bash
#Argument $1 is the file path containing the lifecycle configuration in xml format

ACCESS_KEY_ID="Im6wMbASZ9FPQcRztTka"
SECRET_ACCESS_KEY="YxKCLbQuSQrX/wa+rDJSNNDRHYGT0ZnTaVtOWNHQ"

HOSTNAME="a38676c2b4b6b47eeb176aeb09bb8566-2027527576.eu-west-1.elb.amazonaws.com"
REGION=""
AWS_SERVICE="s3"

HTTP_METHOD="PUT"
CANONICAL_URI="/loki-bucket-odf-4ff4f440-5128-46a5-b6ba-58d67c4b6cc4/"
CANONICAL_QUERY_STRING="lifecycle="

LIFECYCLE_CONF=$(cat <<EOF
<LifecycleConfiguration>
    <Rule>
        <ID>logging-data-expire</ID>
        <Filter>
	  <Prefix>/</Prefix>
        </Filter>
        <Status>Enabled</Status>
        <Expiration>
             <Days>1</Days>
        </Expiration>
    </Rule>
</LifecycleConfiguration>
EOF
)

#Retreive current date in appropriate format
DATE_AND_TIME=$(date -u +"%Y%m%dT%H%M%SZ")
DATE=$(date -u +"%Y%m%d")
CONTENT_SHA256=$(echo -n "$LIFECYCLE_CONF" | openssl dgst -sha256 | cut -d ' ' -f 2)
CONTENT_MD5=$(echo -n "$LIFECYCLE_CONF" | openssl dgst -md5 -binary |openssl enc -base64)

#Store Canonical request
#The blank line is important according to the schema https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html
CANONICAL_REQ=$(cat <<EOF
$HTTP_METHOD
$CANONICAL_URI
$CANONICAL_QUERY_STRING
content-md5:$CONTENT_MD5
host:$HOSTNAME
x-amz-content-sha256:$CONTENT_SHA256
x-amz-date:$DATE_AND_TIME

content-md5;host;x-amz-content-sha256;x-amz-date
$CONTENT_SHA256
EOF
)

# Generate canonical request hash
CANONICAL_REQUEST_HASH=$(echo -n "$CANONICAL_REQ" | openssl dgst -sha256 | awk -F ' ' '{print $2}')

# Function to generate sha256 hash
function hmac_sha256 {
  key="$1"
  data="$2"
  echo -n "$data" | openssl dgst -sha256 -mac HMAC -macopt "$key" | sed 's/^.* //'
}

# Compute signing key
DATE_KEY=$(hmac_sha256 key:"AWS4$SECRET_ACCESS_KEY" $DATE)
DATE_REGION_KEY=$(hmac_sha256 hexkey:$DATE_KEY $REGION)
DATE_REGION_SERVICE_KEY=$(hmac_sha256 hexkey:$DATE_REGION_KEY $AWS_SERVICE)
HEX_KEY=$(hmac_sha256 hexkey:$DATE_REGION_SERVICE_KEY "aws4_request")

# Store string to sign
SIGN_STRING=$(cat <<EOF
AWS4-HMAC-SHA256
$DATE_AND_TIME
$DATE/$REGION/$AWS_SERVICE/aws4_request
$CANONICAL_REQUEST_HASH
EOF
)

# Generate signature
SIGNATURE=$(echo -n "$SIGN_STRING" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$HEX_KEY | awk -F ' ' '{print $2}')

# HTTP Request using signature
curl -k https://${HOSTNAME}${CANONICAL_URI}?lifecycle= \
  -X $HTTP_METHOD \
  -H "content-md5: $CONTENT_MD5" \
  -H "Authorization: AWS4-HMAC-SHA256 Credential=$ACCESS_KEY_ID/$DATE/$REGION/$AWS_SERVICE/aws4_request, SignedHeaders=content-md5;host;x-amz-content-sha256;x-amz-date, Signature=$SIGNATURE" \
  -H "x-amz-content-sha256: $CONTENT_SHA256" \
  -H "x-amz-date: $DATE_AND_TIME" \
  -H "content-type:" \
  --data "$LIFECYCLE_CONF"
