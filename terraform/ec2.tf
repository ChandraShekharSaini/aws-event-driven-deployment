data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}



resource "aws_instance" "web" {
  ami = data.aws_ssm_parameter.al2023.value

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

              apt-get install -y nginx awscli

              systemctl enable nginx
              systemctl start nginx

              mkdir -p /usr/share/nginx/html

              cat > /usr/share/nginx/html/index.html <<'HTML'
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
                          margin-bottom: 15px;
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

              systemctl reload nginx
              EOF

  tags = {
    Name = "${var.project_name}-web"
  }
}