# practice-project-1
 
A practice project to deploy a web server and all necessary infrastructure on AWS using Terraform. This uses static credentials so in order to leverage this all you need is to:

a. have terraform installed and know how to do terraform init and terraform deploy and the directory where you place the main.tf file

b. have an AWS account and know how to get your access key id, access secret key, ssh key id, and ssh key (that you will deploy your EC2 with)

c. once you have those values, open main.tf, search for 'placeholder' and put in the values for the access key ID, secret key, and EC2 SSH key 
into the terraform file to run

d. once done you can access via web and use the ssh key to access via ssh

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


