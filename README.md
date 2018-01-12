# mongo-s3-backup

A Docker container to backup a MongoDB deployment to S3 and list or restore those backups.

## Usage

### Backup

The simplest backup you can do is by only providing the S3 config and a `MONGO_HOST` value.  `MONGO_HOST` can be in any form that is supported by the `mongodump` or `mongorestore` `--host` flag.  See more detail on that in [the docs](https://docs.mongodb.com/manual/reference/program/mongodump/).  Specifically, note that you can provide a single Mongo host or a comma-separated list of replica set hosts.  For a replica set, be sure to supply the replica set name before the hosts. The formats are as follows:

```sh
# single host
export MONGO_HOST="mymongo.com:27017"

# replica set (where the replica set name is "rs0")
export MONGO_HOST="rs0/one.mymongo.com:27017,two.mymongo.com:27017,three.mymongo.com:27017"
```

Now run a backup...

```sh
docker run --rm \
  -e AWS_ACCESS_KEY_ID=<key> \
  -e AWS_SECRET_ACCESS_KEY=<secret> \
  -e S3_BUCKET=<bucket> \
  -e MONGO_HOST=$MONGO_HOST \
  reactioncommerce/mongo-s3-backup
```

To link to a running Mongo container (named `mongo`) and run a backup, just ensure the link resolves to the name `mongo` inside the container. You can do that with `--link` flag. The format is `--link your-mongo-name:mongo`

```sh
docker run --rm \
  --link your-mongo-name:mongo \
  -e AWS_ACCESS_KEY_ID=<key> \
  -e AWS_SECRET_ACCESS_KEY=<secret> \
  -e S3_BUCKET=<bucket> \
  reactioncommerce/mongo-s3-backup
```

You can optionally provide any supported mongodump flags with the `$MONGODUMP_FLAGS` variable. For example, to provide a specific database:

```sh
docker run --rm \
  -e AWS_ACCESS_KEY_ID=<key> \
  -e AWS_SECRET_ACCESS_KEY=<secret> \
  -e S3_BUCKET=<bucket> \
  -e MONGO_HOST=$MONGO_HOST \
  -e MONGODUMP_FLAGS="--db mydatabase" \
  reactioncommerce/mongo-s3-backup
```

Or any amount of additional flags...

```sh
docker run --rm \
  -e AWS_ACCESS_KEY_ID=<key> \
  -e AWS_SECRET_ACCESS_KEY=<secret> \
  -e S3_BUCKET=<bucket> \
  -e MONGO_HOST=$MONGO_HOST \
  -e MONGODUMP_FLAGS="--db mydatabase --username <myuser> --password <pass123> --oplog" \
  reactioncommerce/mongo-s3-backup
```

#### Custom backup names

The file names of backups can be customized with the following environment variables:
- `FILE_PREFIX` add a file name prefix to a backup's name. Default: blank.
- `DATE_FORMAT` accepts a Unix date format. Default: `%Y%m%d_%H%M%S`

To create a file with a name like `mydb.2018-01-07_13-10-43.tar.gz` you would do this:

```sh
docker run --rm \
  -e FILE_PREFIX=mydb. \
  -e DATE_FORMAT=%Y-%m-%d_%H-%M-%S \
  -e AWS_ACCESS_KEY_ID=<key> \
  -e AWS_SECRET_ACCESS_KEY=<secret> \
  -e S3_BUCKET=<bucket> \
  -e MONGO_HOST=$MONGO_HOST \
  reactioncommerce/mongo-s3-backup
```

### List

To list the backups on S3:

```
docker run --rm \
  -e AWS_ACCESS_KEY_ID=<key> \
  -e AWS_SECRET_ACCESS_KEY=<secret> \
  -e S3_BUCKET=<bucket> \
  reactioncommerce/mongo-s3-backup list
```

### Restore Latest

To restore the latest backup on S3:
```sh
docker run --rm \
  -e AWS_ACCESS_KEY_ID=<key> \
  -e AWS_SECRET_ACCESS_KEY=<secret> \
  -e S3_BUCKET=<bucket> \
  -e MONGO_HOST=$MONGO_HOST \
  reactioncommerce/mongo-s3-backup restore latest
```

A sort is used to determine the latest backup. If a `FILE_PREFIX` is defined, this will filter the bucket list results by the `FILE_PREFIX` that was originally used. If you are using a custom `DATE_FORMAT`, you will need to set that variable as well to ensure the sort order will still list the correct date order.

## Restore

To restore a specific backup, provide the name of the backup within the S3 bucket:

```sh
docker run --rm \
  -e AWS_ACCESS_KEY_ID=<key> \
  -e AWS_SECRET_ACCESS_KEY=<secret> \
  -e S3_BUCKET=<bucket> \
  -e MONGO_HOST=$MONGO_HOST \
  reactioncommerce/mongo-s3-backup restore <file>
```

You can optionally provide any supported `mongorestore` flags with the `$MONGORESTORE_FLAGS` variable. For example, to a backup that came from a replica set dump that used the `--oplog` flag, you can replay the oplog for the restore like this:

```sh
docker run --rm \
  -e AWS_ACCESS_KEY_ID=<key> \
  -e AWS_SECRET_ACCESS_KEY=<secret> \
  -e S3_BUCKET=<bucket> \
  -e MONGO_HOST=$MONGO_HOST \
  -e MONGORESTORE_FLAGS="--oplogReplay" \
  reactioncommerce/mongo-s3-backup restore <file>
```

See [the `mongorestore` docs](https://docs.mongodb.com/manual/reference/program/mongorestore/) for all available flags.
