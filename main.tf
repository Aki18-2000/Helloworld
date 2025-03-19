provider "aws" {
  region = "us-east-1"  # Change to your preferred AWS region
}

resource "aws_instance" "docker_instance" {
  ami           = "ami-0c55b159cbfafe1f0"  # Replace with the appropriate Amazon Linux 2 AMI ID for your region
  instance_type = "t2.micro"  # You can choose other instance types as needed
  key_name      = "your-key-pair"  # Replace with your EC2 Key Pair name for SSH access

  # Install Docker and run a simple web server with Docker
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker
              service docker start
              usermod -a -G docker ec2-user

              # Create a simple HTML file
              echo "<html><body><h1>Hello, World!</h1></body></html>" > /home/ec2-user/hello.html

              # Run Nginx in Docker to serve the Hello World page
              docker run -d -p 80:80 --name webserver -v /home/ec2-user/hello.html:/usr/share/nginx/html/index.html nginx
              EOF

  tags = {
    Name = "docker-instance"
  }

  # Allow SSH access (Port 22) and HTTP access (Port 80)
  security_groups = ["default"]

  # Optional: Assign a public IP address
  associate_public_ip_address = true
}

output "instance_ip" {
  value = aws_instance.docker_instance.public_ip
}
