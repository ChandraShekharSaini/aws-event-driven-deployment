import boto3

ssm = boto3.client("ssm")

INSTANCE_ID = "i-xxxxxxxxxxxxxxxxx"
BUCKET = "my-nginx-website"
KEY = "index.html"


def lambda_handler(event, context):

    commands = [
        f"aws s3 cp s3://{BUCKET}/{KEY} /tmp/index.html",
        "sudo cp /tmp/index.html /usr/share/nginx/html/index.html",
        "sudo systemctl reload nginx"
    ]

    response = ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName="AWS-RunShellScript",
        Parameters={
            "commands": commands
        }
    )

    command_id = response["Command"]["CommandId"]

    print("SSM Command ID:", command_id)

    return {
        "statusCode": 200,
        "message": "index.html updated successfully",
        "command_id": command_id
    }