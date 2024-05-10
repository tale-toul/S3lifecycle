# Get and Set S3 lifecycle configuration using Curl and Openssl with SIGV4

These scripts can be used to get and set the lifecycle configuration in an S3 bucket.

The scripts have been tested in an [Openshift Data Foundation](https://access.redhat.com/documentation/en-us/red_hat_openshift_data_foundation/4.14), Nooba S3 environment, but it should also work with AWS S3.

## Prerequisites

- An operating system with a Bash interpreter
- The curl program to send HTTP requests
- The openssl program to generate hashes and signatures
- The necessary permissions to access an object in an S3 bucket, including the name of the bucket and the path to the object.


## Usage

Here is how to use the scripts to get and set the lifecycle configuration:

Populate the following variables with the access key and secret access key for your S3 system, yes even Nooba/ODF uses these keys:

```
ACCESS_KEY_ID="Im6w...ztTka"
SECRET_ACCESS_KEY="YxKCLb....T0ZnTaVtOWNHQ"
```

Define the hostname for the S3 bucket:
```
HOSTNAME="a38676c2b4b6b47eeb176aeb09bb8566-2027527576.eu-west-1.elb.amazonaws.com"
```

Define the region in the following variable, in case of Nooba, the region is empty:
```
REGION=""
```
Set the name of the bucket to get or set the lifecycle configuration:
```
CANONICAL_URI="/loki-bucket-odf-4ff4f440-5128-46a5-b6ba-58d67c4b6cc4/"
```
In the case of setting the configuration, define the configuration in xml format:

```
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
```
Get the lifecycle configuration with the following command:

```
./gets3lifecycle.sh
````

Set the lifecycle configuration with the following command:
````
./sets3lifecycle.sh
````

## References
[Openshift Data Foundation documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_data_foundation/4.14)
[s3cmd cli tool](https://github.com/s3tools)
[Managing your storage lifecycle](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
[Setting a lifecycle configuration on a bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/how-to-set-lifecycle-configuration-intro.html)
[Signature Calculations for the Authorization Header: Transferring Payload in a Single Chunk (AWS Signature Version 4)](https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html)
[Get S3 object securely using curl and openssl with SIGV4](https://blog.revolve.team/2023/01/19/s3-object-securely-curl-openssl-sigv4/)
[Git Hub repor for "Get S3 object" blog post](https://github.com/ReyanL/get-object-s3)
