#!/bin/bash

ACCESS_KEY_ID="Im6wMbASZ9FPQcRztTka"
SECRET_ACCESS_KEY="YxKCLbQuSQrX/wa+rDJSNNDRHYGT0ZnTaVtOWNHQ"

REGION=""
AWS_SERVICE="s3"

HTTP_METHOD="GET"
CANONICAL_URI="/loki-bucket-odf-4ff4f440-5128-46a5-b6ba-58d67c4b6cc4/"
CANONICAL_QUERY_STRING="lifecycle="

#Retreive current date in appropriate format
DATE_AND_TIME=$(date -u +"%Y%m%dT%H%M%SZ")
DATE=$(date -u +"%Y%m%d")
EMPTY_STRING_HASH=$(printf "" | openssl dgst -sha256 | cut -d ' ' -f 2)

#Store Canonical request
#The blank line is important according to the schema https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html
/bin/cat >./canonical_request.tmp <<EOF
$HTTP_METHOD
$CANONICAL_URI
$CANONICAL_QUERY_STRING
host:a38676c2b4b6b47eeb176aeb09bb8566-2027527576.eu-west-1.elb.amazonaws.com
x-amz-content-sha256:$EMPTY_STRING_HASH
x-amz-date:$DATE_AND_TIME

host;x-amz-content-sha256;x-amz-date
$EMPTY_STRING_HASH
EOF


# Remove trailing newline
printf %s "$(cat canonical_request.tmp)" > canonical_request.tmp 

# Generate canonical request hash
CANONICAL_REQUEST_HASH=$(openssl dgst -sha256 canonical_request.tmp | awk -F ' ' '{print $2}')

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
/bin/cat >./string_to_sign.tmp <<EOF
AWS4-HMAC-SHA256
$DATE_AND_TIME
$DATE/$REGION/$AWS_SERVICE/aws4_request
$CANONICAL_REQUEST_HASH
EOF

# Remove trailing newline
printf %s "$(cat string_to_sign.tmp)" > string_to_sign.tmp

# Generate signature
SIGNATURE=$(openssl dgst -sha256 -mac HMAC -macopt hexkey:$HEX_KEY string_to_sign.tmp | awk -F ' ' '{print $2}')

# Remove temporary files
rm canonical_request.tmp string_to_sign.tmp

# HTTP Request using signature
curl -k https://a38676c2b4b6b47eeb176aeb09bb8566-2027527576.eu-west-1.elb.amazonaws.com${CANONICAL_URI}?lifecycle= \
  -X $HTTP_METHOD \
  -H "Authorization: AWS4-HMAC-SHA256 Credential=$ACCESS_KEY_ID/$DATE/$REGION/$AWS_SERVICE/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=$SIGNATURE" \
  -H "x-amz-content-sha256: $EMPTY_STRING_HASH" \
  -H "x-amz-date: $DATE_AND_TIME" 
#  -o "$OUTPUT"
