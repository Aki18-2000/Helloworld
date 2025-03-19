provider "aws" {
  region = "us-east-1"  # Change to your preferred AWS region
}

# Security Group to allow HTTP traffic on port 80
resource "aws_security_group" "docker_sg" {
  name        = "docker_sg"
  description = "Allow HTTP traffic on port 80"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from anywhere (you can limit this to specific IPs)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }

  tags = {
    Name = "docker_sg"
  }
}

# EC2 instance running Docker
resource "aws_instance" "docker_instance" {
  ami           = "ami-08b5b3a93ed654d19"  # Amazon Linux 2 AMI (ensure this is valid for your region)
  instance_type = "t2.micro"  # Instance type (you can change it if needed)
  
  
  # Attach the security group to the EC2 instance
  security_groups = [aws_security_group.docker_sg.name]

  # User data script to install Docker, run Nginx container, and create the HTML page
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

              # Log Docker container status for troubleshooting
              docker ps -a > /home/ec2-user/docker_ps.log
              docker port webserver > /home/ec2-user/docker_port.log

              # Output logs to help troubleshoot
              cat /home/ec2-user/docker_ps.log
              cat /home/ec2-user/docker_port.log
              EOF

  # Optional: Assign a public IP address
  associate_public_ip_address = true

  tags = {
    Name = "docker-instance"
  }
}

# Output the public IP of the EC2 instance
output "instance_ip" {
  value = aws_instance.docker_instance.public_ip
}
