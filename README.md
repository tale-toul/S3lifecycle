# Get S3 object securely using Curl and Openssl with SIGV4

This script allow you to retrieve an S3 object securely using Curl and Openssl with SIGV4

## Prerequisites

- An operating system with a Bash interpreter
- The curl program to send HTTP requests
- The openssl program to generate hashes and signatures
- Access to the EC2 instance metadata interface (http://169.254.169.254/latest/meta-data/)
- Valid IAM account credentials and a session token, accessible via the EC2 instance metadata interface.
- The necessary permissions to access an object in an S3 bucket, including the name of the bucket and the path to the object.


## Usage

Here is how to use this script
```
./get-object-s3.sh bucket_name object_path
````

where bucket_name is the name of the S3 bucket where the object is located, and object_path is the path to the object in the bucket.

For example, if you want to access the object /documents/file.txt in the my-bucket bucket, you can use the following command:
```
./get-object-s3.sh my-bucket documents/file.txt
```

The script will use the EC2 instance credentials and session token to access the object in the S3 bucket


