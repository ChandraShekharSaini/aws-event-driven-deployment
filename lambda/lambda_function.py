import boto3
import os
import urllib.parse
import shlex

ssm = boto3.client("ssm")

INSTANCE_ID = os.environ["INSTANCE_ID"]


def lambda_handler(event, context):

    print("Received event:")
    print(event)

    results = []

    for record in event.get("Records", []):

        bucket = record["s3"]["bucket"]["name"]

        key = urllib.parse.unquote_plus(
            record["s3"]["object"]["key"]
        )

        print(f"Bucket: {bucket}")
        print(f"Key: {key}")

        # Deploy only index.html
        if key != "index.html":
            print(f"Skipping object: {key}")
            continue

        safe_bucket = shlex.quote(bucket)
        safe_key = shlex.quote(key)

        commands = [
            # Download index.html from S3
            f"aws s3 cp s3://{safe_bucket}/{safe_key} /tmp/index.html",

            # Deploy to Ubuntu Nginx web directory
            "sudo install -o root -g root -m 0644 /tmp/index.html /var/www/html/index.html",

            # Reload Nginx
            "sudo systemctl reload nginx"
        ]

        response = ssm.send_command(
            InstanceIds=[INSTANCE_ID],

            DocumentName="AWS-RunShellScript",

            Parameters={
                "commands": commands
            },

            Comment="Deploy website index.html to Ubuntu Nginx"
        )

        command_id = response["Command"]["CommandId"]

        print(f"SSM Command ID: {command_id}")

        results.append({
            "bucket": bucket,
            "key": key,
            "command_id": command_id
        })

    return {
        "statusCode": 200,
        "deployments": results
    }