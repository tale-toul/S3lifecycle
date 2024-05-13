# Get and Set S3 lifecycle configuration using Curl and Openssl with SIGV4

These scripts can be used to get and set the lifecycle configuration in an S3 bucket.

The scripts have been tested in an [Openshift Data Foundation](https://access.redhat.com/documentation/en-us/red_hat_openshift_data_foundation/4.14), Nooba S3 environment, but it should also work with AWS S3.

## Prerequisites

- An operating system with a Bash interpreter
- The curl program to send HTTP requests
- The openssl program to generate hashes and signatures
- The necessary permissions to access an object in an S3 bucket, including the name of the bucket and the path to the object.


## Usage External

Here is how to use the scripts to get and set the lifecycle configuration:

Populate the following variables with the access key and secret access key for your S3 system, yes even Nooba/ODF uses these keys:

```
ACCESS_KEY_ID="Im6w...ztTka"
SECRET_ACCESS_KEY="YxKCLb....T0ZnTaVtOWNHQ"
```

Define the hostname for the S3 bucket.  In Openshift this is the external IP name associated the **s3** service:
```
oc get svc s3 -n openshift-storage

NAME   TYPE           CLUSTER-IP      EXTERNAL-IP                                                              PORT(S)                                                    AGE
s3     LoadBalancer   172.30.85.176   a49d691c70f984819a4df1c7a677b882-633984083.eu-west-1.elb.amazonaws.com   80:31152/TCP,443:31974/TCP,8444:30593/TCP,7004:31841/TCP   4h38m

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
In the case of setting the configuration, define the configuration in xml format. In the next example the Prefix is empty to affect the whole bucket:

```
LIFECYCLE_CONF=$(cat <<EOF
<LifecycleConfiguration>
    <Rule>
        <ID>logging-data-expire</ID>
        <Filter>
	  <Prefix></Prefix>
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

## Usage Internal 

If the script cannot be executed from outside the Openshift cluster, for example because the **s3** endpoint does not have a corresponding external IP or name.  It can be executed from a pod running inside penshift.

The ACCESS_KEY_ID and SECRET_ACCESS_KEY can be obtained from the secret associated with the object bucket claim:
````
oc extract secret/loki-bucket-odf -n openshift-logging --to -
````

Fill in the data as explained earlier, but in this case the value of HOSTNAME is the name of the s3 service:
````
HOSTNAME="s3.openshift-storage.svc"
````
Leave the REGION empty as above.

The CANONICAL URI contains the name of the bucket between forward slash characters.  This can be obtained from the config map associated with the bucket
````
oc get cm -n openshift-logging loki-bucket-odf -o yaml
````

Run a pod in interactive mode:
````
oc run -i -t ocli --image=registry.redhat.io/openshift4/ose-cli --restart=Never
````
From another shell session copy the script to the running pod
````
oc cp /home/redhat/S3lifecycle/gets3lifecycle.sh testarudo/ocli:/gets3lifecycle.sh
````
From the shell session inside pod, run the script:
````
[root@ocli /]# ./gets3lifecycle.sh
````

## Verify lifecycle configuration

If a new lifecycle configuration has been set in the S3 bucket, here is how to verify that it has been successfully applied and it is working in a Nooba/ODF provided bucket.

The S3 bucket provider does not delete any files until their expiration days have passed, for example if the expiration days is 5, no files will be deleted until they are older than 5 days.  So it may take a while before policy effects can be seen.

Get the list of all the files in the bucket.  In the example, the list is sorted by date and saved to a file.
```
s3cmd ls --recursive s3://loki-bucket-odf-4ff4f440-5128-46a5-b6ba-58d67c4b6cc4|sort >filelist.txt
```

After the expiration days have passed, the oldest files should disappear from the list.

The size of the bucket can also be checked with
```
s3cmd du -H  s3://loki-bucket-odf-4ff4f440-5128-46a5-b6ba-58d67c4b6cc4
```

Check the logs of the nooba core pod. If any files were deleted the following messages should appear:
```
oc logs noobaa-core-0 -n openshift-storage|less -R

core.server.bg_services.agent_blocks_reclaimer:: AGENT_BLOCKS_RECLAIMER: BEGIN
core.server.bg_services.objects_reclaimer:: object_reclaimer: starting batch work on objects:  index/index_19855/infrastructure/1715527765-compactor-1715464235736-1715526930765-c02c502f.tsdb.gz, index/index_19855/application/1715527765-compactor-1715465467963-1715526915661-90de4342.tsdb.gz,...
core.server.object_services.md_store:: find_object_parts_unreferenced_chunk_ids: chunk_ids 1 referenced_chunks_ids 0 unreferenced_chunks_ids 1
...
core.server.object_services.map_deleter:: delete_blocks_from_node: node 663a5fa335aa4f00263fff46 n2n://663a5fa335aa4f00263fff47 block_ids 1
core.server.object_services.map_deleter:: delete_blocks_from_node: node 663a5fa335aa4f00263fff46 n2n://663a5fa335aa4f00263fff47 succeeded_block_ids 1
core.server.object_services.md_store:: update_object_by_id: 6640e0e90337c9000de85999
core.server.bg_services.objects_reclaimer:: no objects in "unreclaimed" state. nothing to do
```

## References
* [Openshift Data Foundation documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_data_foundation/4.14)
* [s3cmd cli tool](https://github.com/s3tools)
* [Managing your storage lifecycle](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
* [Setting a lifecycle configuration on a bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/how-to-set-lifecycle-configuration-intro.html)
* [Signature Calculations for the Authorization Header: Transferring Payload in a Single Chunk (AWS Signature Version 4)](https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html)
* [Get S3 object securely using curl and openssl with SIGV4](https://blog.revolve.team/2023/01/19/s3-object-securely-curl-openssl-sigv4/)
* [Git Hub repor for "Get S3 object" blog post](https://github.com/ReyanL/get-object-s3)
