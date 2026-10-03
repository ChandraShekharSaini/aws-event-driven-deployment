data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}


resource "aws_instance" "web" {
  ami = data.aws_ssm_parameter.ubuntu.value

  instance_type = "t3.micro"

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.nginx.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2.name

  associate_public_ip_address = true

 user_data = <<-EOF
#!/bin/bash

set -eux

apt-get update -y

apt-get install -y nginx curl unzip

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o "/tmp/awscliv2.zip"

unzip -q /tmp/awscliv2.zip -d /tmp

/tmp/aws/install

# Verify AWS CLI
/usr/local/bin/aws --version

# Enable and start Nginx
systemctl enable nginx
systemctl start nginx

mkdir -p /var/www/html

cat > /var/www/html/index.html <<'HTML'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CloudTech Website</title>

    <style>
        body {
            margin: 0;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            text-align: center;
        }

        h1 {
            font-size: 50px;
        }

        p {
            font-size: 20px;
        }
    </style>
</head>

<body>
    <div>
        <h1>🚀 CloudTech Website</h1>
        <p>Deployed using AWS + Terraform + Ubuntu</p>
    </div>
</body>
</html>
HTML

chown -R www-data:www-data /var/www/html
chmod 644 /var/www/html/index.html

nginx -t
systemctl reload nginx

echo "Setup completed successfully"
EOF

  tags = {
    Name = "${var.project_name}-web"
  }
}