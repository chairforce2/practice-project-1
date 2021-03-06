/* 
Steps involved:
1. Create VPC
2. Create Internet Gateway
3. Create Custom Route Table
4. Create a Subnet
5. Associate subnet with Route Table
6. Create Security Group to allow ports 22, 80, 443
7. Create network interface with an IP, place in subnet from step 4
8. Asign elastic IP to network interface from step 7
9. Create Ubuntu server and install+enable apache2

*/

#Step 0:
#defining the AWS provider and credentials

provider "aws" {
  region  = "us-east-1"
  #statically typed credentials
  #placeholder values for access key Id and secret key respectively
  access_key = "my_access_key"
  secret_key = "my_secret_key"
}

#Step 1: 
#Creating an AWS VPC
resource "aws_vpc" "example-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Example-VPC"
  }
}

#Step 2:
#Creating an Internet Gateway
resource "aws_internet_gateway" "example-vpc-internet-gateway" {
    #referencing the vpc_id from the VPC definition in Step 1
  vpc_id = aws_vpc.example-vpc.id
  tags = {
    Name = "example"
  }
}

#Step 3:
#Create Custom Route Table
resource "aws_route_table" "example-vpc-route-table" {
  #referencing the vpc_id from the VPC definition in Step 1
  vpc_id = aws_vpc.example-vpc.id

#referencing the Internet Gateway from the definition in Step 2
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example-vpc-internet-gateway.id
  }

#referencing the Internet Gatewaay from the definition in Step 2
  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.example-vpc-internet-gateway.id
  }

  tags = {
    Name = "example"
  }
}

#Step 4:
#defining subnet in the example-vpc from Step 1
resource "aws_subnet" "example-subnet"{
  vpc_id = aws_vpc.example-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public-subnet"
  }
}

#Step 5:
#Associating Route table from step 3 with subnet from step 4
resource "aws_route_table_association" "example-route-table-to-example-subnet-association" {
  subnet_id      = aws_subnet.example-subnet.id
  route_table_id = aws_route_table.example-vpc-route-table.id
}

#Step 6:
#Create Security Group to allow ports 22, 80, 443
resource "aws_security_group" "allow_ssh_http_https_inbound" {
  name        = "allow_ssh_http_https_from_inbound"
  description = "Allow inbound traffic ports 22, 80, 443"
  vpc_id = aws_vpc.example-vpc.id

  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_http_https"
  }
}

#Step 7
#Create network interface with an IP, place in subnet from step 4
resource "aws_network_interface" "ubuntu-test-interface" {
  subnet_id       = aws_subnet.example-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_ssh_http_https_inbound.id]

  /* this is a possible way to attach the nic to an instance within the definition of the nic. commenting this out as we have instead
  decided to do this in the definition of the EC2 instance in step 9 
    
    attachment {
    instance     = aws_instance.Ubuntu_Web_Server.id
    device_index = 1
  }*/
}

#Step 8 
#Asign elastic IP to network interface from step 7

resource "aws_eip" "one" {
    #sets it to true if the EIP is in a VPC
  vpc                       = true
  network_interface         = aws_network_interface.ubuntu-test-interface.id
  associate_with_private_ip = "10.0.0.50"
  #sets an explicit dependency that the eip be created after the IGW. If it tried to create the EIP before the IGW it breaks things. Terraform may handle this
  #appropriately or may not so we're setting it explicitly to be sure
  depends_on  = [aws_internet_gateway.example-vpc-internet-gateway]
}

#Step 9
#Create Ubuntu server and install+enable apache2
resource "aws_instance" "Ubuntu_Web_Server" {
    #ami image ID pulled from AWS Marketplace for US-East-1 on Sept 11 2020
    ami = "ami-06b263d6ceff0b3dd"
    #defining size/type of the EC2, in this case attempting to stay in free tier
    instance_type = "t2.micro"
    #placeholder for the SSH key to deploy the instance with
    key_name = "my_key"

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.ubuntu-test-interface.id
    }
    user_data     = <<-EOF
                  #!/bin/bash
                  sudo apt update -y
                  sudo apt install apache2 -y
                  sudo systemctl start apache2
                  sudo bash -c 'echo your first web server > var/www/html/index.html'
                  EOF
}