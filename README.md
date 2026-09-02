# 🚀 Event-Driven Website Auto-Deployment

This project demonstrates an automated website deployment workflow using **AWS S3, AWS Lambda, AWS Systems Manager (SSM), EC2, and Nginx**.

Whenever `index.html` is updated in an S3 bucket, an S3 event automatically triggers a Lambda function. Lambda uses **AWS Systems Manager Run Command** to update the `index.html` file inside the Nginx web directory on an EC2 instance.

---

## 🏗️ Architecture

```text
                    Developer
                       │
                       │ Upload / Update
                       ▼
                ┌───────────────┐
                │   AWS S3      │
                │   Bucket      │
                └───────┬───────┘
                        │
                  ObjectCreated
                        │
                        ▼
                ┌───────────────┐
                │    Lambda     │
                │   Function    │
                └───────┬───────┘
                        │
                  ssm:SendCommand
                        │
                        ▼
                ┌───────────────┐
                │      EC2      │
                │   Instance    │
                └───────┬───────┘
                        │
                  SSM Run Command
                        │
                        ▼
          /usr/share/nginx/html/index.html
                        │
                        ▼
                ┌───────────────┐
                │     Nginx     │
                │ Web Server    │
                └───────┬───────┘
                        │
                        ▼
                  🌐 Website
```

---

# 📌 Project Objective

The objective is to automatically deploy changes made to `index.html`.

### Without automation

```text
Developer
   ↓
Upload index.html
   ↓
Login to EC2
   ↓
Download file
   ↓
Copy file to Nginx
```

### With this project

```text
Developer
   ↓
Upload index.html to S3
   ↓
S3 Event
   ↓
Lambda
   ↓
SSM
   ↓
EC2
   ↓
Nginx
   ↓
Website Updated Automatically
```

---

# 🛠️ AWS Services Used

| Service             | Purpose                    |
| ------------------- | -------------------------- |
| Amazon S3           | Stores website files       |
| AWS Lambda          | Processes S3 events        |
| Amazon EC2          | Hosts the website          |
| AWS Systems Manager | Executes commands on EC2   |
| IAM                 | Provides permissions       |
| Nginx               | Web server                 |
| CloudWatch          | Lambda logs and monitoring |

---

# 📁 Project Structure

```text
s3-lambda-ec2-nginx/
│
├── README.md
│
└── index.html
```

---

# 🔧 Prerequisites

Before starting, make sure you have:

* AWS Account
* AWS CLI installed
* EC2 instance
* Nginx installed on EC2
* S3 bucket
* IAM permissions
* SSM Agent installed/running on EC2
* Python Lambda runtime

---

# 1️⃣ Create S3 Bucket

Create an S3 bucket.

Example:

```text
my-nginx-website
```

Upload:

```text
index.html
```

The object will be:

```text
s3://my-nginx-website/index.html
```

---

# 2️⃣ Configure EC2

Launch an EC2 instance.

Install Nginx:

```bash
sudo yum update -y
sudo yum install nginx -y
```

Start Nginx:

```bash
sudo systemctl start nginx
```

Enable Nginx at boot:

```bash
sudo systemctl enable nginx
```

Check status:

```bash
sudo systemctl status nginx
```

Expected:

```text
Active: active (running)
```

---

# 3️⃣ Check SSM Agent

Check whether the SSM Agent is running:

```bash
sudo systemctl status amazon-ssm-agent
```

Expected:

```text
Active: active (running)
```

SSM allows Lambda to execute commands on the EC2 instance without requiring SSH.

---

# 4️⃣ Create EC2 IAM Role

Create an IAM role for the EC2 instance.

Attach:

```text
AmazonSSMManagedInstanceCore
```

This allows the EC2 instance to communicate with AWS Systems Manager.

---

# 5️⃣ Give EC2 S3 Permission

The EC2 instance needs permission to download `index.html` from S3.

Attach an inline policy to the EC2 role:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::my-nginx-website/index.html"
        }
    ]
}
```

Now EC2 can execute:

```bash
aws s3 cp s3://my-nginx-website/index.html /tmp/index.html
```

---

# 6️⃣ Test S3 Access From EC2

Run:

```bash
aws s3 cp s3://my-nginx-website/index.html /tmp/index.html
```

Check:

```bash
cat /tmp/index.html
```

If the file is downloaded successfully, S3 permissions are working.

---

# 7️⃣ Create Lambda IAM Role

Go to:

```text
AWS Console
→ IAM
→ Roles
→ Create Role
```

Select:

```text
Trusted entity:
AWS Service

Use case:
Lambda
```

Attach:

```text
AWSLambdaBasicExecutionRole
```

Create the role:

```text
lambda-s3-to-ec2-role
```

---

# 8️⃣ Add SSM Permission to Lambda

Add an inline policy to the Lambda role:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:SendCommand"
            ],
            "Resource": "*"
        }
    ]
}
```

The important permission is:

```text
ssm:SendCommand
```

This allows:

```text
Lambda
   │
   │ SendCommand
   ▼
SSM
   │
   ▼
EC2
```

---

# 9️⃣ Create Lambda Function

Go to:

```text
AWS Console
→ Lambda
→ Create function
```

Select:

```text
Author from scratch
```

Function name:

```text
s3-index-html-update
```

Runtime:

```text
Python 3.x
```

Select:

```text
Use an existing role
```

Choose:

```text
lambda-s3-to-ec2-role
```

Create the function.

---

# 🔟 Lambda Function Code

Replace the Lambda code with:

```python
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
```

---

# ⚠️ Important

Change:

```python
INSTANCE_ID = "i-xxxxxxxxxxxxxxxxx"
```

to your actual EC2 instance ID.

Example:

```python
INSTANCE_ID = "i-0123456789abcdef0"
```

Do **not** use an AMI ID.

❌ Incorrect:

```text
ami-0123456789abcdef0
```

✅ Correct:

```text
i-0123456789abcdef0
```

---

# 1️⃣1️⃣ Test Lambda

Click:

```text
Deploy
```

Then:

```text
Test
```

Create a test event:

```json
{
    "test": "hello"
}
```

Run the test.

Lambda will execute:

```bash
aws s3 cp s3://my-nginx-website/index.html /tmp/index.html
```

Then:

```bash
sudo cp /tmp/index.html /usr/share/nginx/html/index.html
```

Then:

```bash
sudo systemctl reload nginx
```

---

# 1️⃣2️⃣ Verify EC2

Connect to EC2 using SSH or SSM.

Check:

```bash
cat /usr/share/nginx/html/index.html
```

The file should contain the same content as the S3 `index.html`.

Test Nginx:

```bash
curl http://localhost
```

---

# 1️⃣3️⃣ Configure S3 → Lambda Trigger

Go to:

```text
AWS Console
→ Lambda
→ s3-index-html-update
→ Add Trigger
```

Select:

```text
Source:
S3
```

Choose your bucket:

```text
my-nginx-website
```

Event type:

```text
All object create events
```

Configure the trigger so it applies only to:

```text
index.html
```

If using a suffix filter:

```text
.html
```

Click:

```text
Add
```

---

# 1️⃣4️⃣ Test Automatic Deployment

Modify your local `index.html`.

For example:

```html
<h1>Welcome to My Music Website</h1>
```

Upload it:

```bash
aws s3 cp index.html s3://my-nginx-website/index.html
```

The workflow starts automatically:

```text
S3 Upload
   ↓
ObjectCreated Event
   ↓
Lambda Triggered
   ↓
SSM SendCommand
   ↓
EC2 Downloads index.html
   ↓
File copied to Nginx
   ↓
Nginx Reloaded
   ↓
Website Updated
```

---

# 1️⃣5️⃣ Verify the Website

Find the public IP of the EC2 instance:

```bash
curl http://<EC2-PUBLIC-IP>
```

Or open:

```text
http://<EC2-PUBLIC-IP>
```

You should see the updated website.

---

# 🔍 Useful Commands

### Check Nginx

```bash
sudo systemctl status nginx
```

### Start Nginx

```bash
sudo systemctl start nginx
```

### Restart Nginx

```bash
sudo systemctl restart nginx
```

### Reload Nginx

```bash
sudo systemctl reload nginx
```

### Check website files

```bash
ls -l /usr/share/nginx/html/
```

### Check index.html

```bash
cat /usr/share/nginx/html/index.html
```

### Test website locally

```bash
curl http://localhost
```

### Test S3 download

```bash
aws s3 cp s3://my-nginx-website/index.html /tmp/index.html
```

---

# 🧪 Troubleshooting

## Lambda cannot send command

Check Lambda IAM role.

It must have:

```text
ssm:SendCommand
```

---

## EC2 is not visible in SSM

Check:

```bash
sudo systemctl status amazon-ssm-agent
```

Also verify that the EC2 instance has:

```text
AmazonSSMManagedInstanceCore
```

---

## S3 download fails

Check the EC2 IAM role.

It needs:

```text
s3:GetObject
```

for:

```text
arn:aws:s3:::my-nginx-website/index.html
```

---

## Website does not update

Check the file:

```bash
cat /usr/share/nginx/html/index.html
```

Then check Lambda logs in:

```text
CloudWatch
→ Log groups
→ /aws/lambda/s3-index-html-update
```

Also check the SSM command execution status.

---

## Permission denied while copying

Make sure the Lambda command uses:

```bash
sudo cp
```

Example:

```bash
sudo cp /tmp/index.html /usr/share/nginx/html/index.html
```

---

# 🔐 Security Improvements

For a production environment, avoid using:

```json
"Resource": "*"
```

for SSM permissions.

Restrict Lambda permissions to the required:

* EC2 instance
* SSM document
* S3 bucket/object

Also consider:

* S3 Block Public Access
* IAM least privilege
* CloudWatch monitoring
* CloudTrail
* S3 versioning
* HTTPS with SSL/TLS
* Route 53 custom domain
* Application Load Balancer
* Automatic rollback/versioning

---

# 📊 Monitoring

Lambda execution logs are available in:

```text
CloudWatch
→ Log groups
→ /aws/lambda/s3-index-html-update
```

You can monitor:

```text
Lambda Invocations
Lambda Errors
Lambda Duration
SSM Command Status
EC2 Status
Nginx Status
```

---

# 🎯 Final Result

The project provides a simple CI/CD-style deployment mechanism:

```text
             ┌──────────────┐
             │   Developer  │
             └──────┬───────┘
                    │
               Upload HTML
                    │
                    ▼
             ┌──────────────┐
             │      S3      │
             └──────┬───────┘
                    │
             S3 Event Trigger
                    │
                    ▼
             ┌──────────────┐
             │    Lambda    │
             └──────┬───────┘
                    │
              SSM SendCommand
                    │
                    ▼
             ┌──────────────┐
             │     EC2      │
             └──────┬───────┘
                    │
             Download from S3
                    │
                    ▼
       /usr/share/nginx/html/
                    │
                    ▼
             ┌──────────────┐
             │    Nginx     │
             └──────┬───────┘
                    │
                    ▼
             🌐 Live Website
```

## 🏆 Technologies

```text
AWS S3
AWS Lambda
AWS EC2
AWS IAM
AWS Systems Manager
AWS CloudWatch
Nginx
Python
HTML
CSS
```

---

## 👨‍💻 Learning Outcomes

By completing this project, you learn:

* S3 Event Notifications
* Lambda functions
* Lambda IAM roles
* EC2 IAM roles
* IAM least privilege
* AWS Systems Manager
* SSM Run Command
* Automated deployment
* Nginx web hosting
* CloudWatch logging
* Event-driven AWS architecture
* Basic AWS CI/CD concepts

```

You can save the above directly as **`README.md`** in your GitHub repository.
```
