# SpaceRocket Infrastructure

With SpaceRocket infrastructure, you can quickly use Infrastructure as Code to deploy a Docker container or Elixir Phoenix application hosted on Github to AWS. Next.js support coming soon!

## Features

- Builds a custom Ubuntu Amazon Machine Image (AMI) with Docker and AWS CLI preinstalled
- Deploy Docker containers or Elixir Phoenix applications hosted on Github to AWS
- Use any number of EC2 instances
- Traffic routed through Application Load Balancer (ALB)
- ALB logs are stored in an encrypted S3 bucket
- Automatic SSL through AWS Certificate Manager (ACM)
- Infrastructure as Code using Terraform and ansible
- Code ready for your CI/CD pipeline

## Prerequisites
- Ubuntu environment with Terraform, ansible, Packer installed and AWS credentials with Administrative access configured.
- SSH key

Before you can use the Terraform and Packer tools, you need to install them on your system. The installation process for each tool depends on your operating system and the method you prefer to use.

To install Terraform, you can follow the instructions at the following link:

https://learn.hashicorp.com/terraform/getting-started/install.html

To install Packer, you can follow the instructions at the following link:

https://www.packer.io/docs/install/index.html

Once you have installed the tools, you need to configure your AWS credentials so that you can access your AWS resources. You can do this by creating an IAM user in your AWS account and assigning the appropriate permissions to the user. You can then use the access key and secret access key for the user to configure your AWS credentials on your local machine with the following command:
```bash
aws configure
```

You can find more information on how to create an IAM user and configure your AWS credentials at the following link:

https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys

Alternatively, you can set up a Cloud9 instance hosted on Ubuntu. This will come with AWS credentials pre-configured and rotated regularly for extra security. See below.

#### Getting started with AWS Cloud9 (Optional)
If you don't want to go through the trouble of setting up an Ubuntu virtual machine using virtualization software or setting up a dual-boot system, you can use the Cloud9 IDE hosted on an EC2 Ubuntu server for an easy setup. Below are the steps to get started.

1. Sign in to the AWS Management Console and open the Cloud9 console at https://console.aws.amazon.com/cloud9/.

2. Create a new environment by clicking the "Create environment" button.

3. Give your environment a name and select the desired options, such as the environment type and instance type.

4. Under platform, select "Ubuntu18.04 LTS" or the latest version of Ubuntu. 

5. Click the "Create environment" button to create the environment.

6. Once the environment is ready, you will be taken to the Cloud9 IDE, which is a web-based code editor. 

7. To access the command line, click the "Terminal" button in the top menu. This will open a terminal window within the IDE.

8. From the terminal, you can run commands and interact with the environment just as you would on a local terminal.

This environment can work as a bastion server that matches the Ubuntu platform used in our IaC.


## Setup

### Prod Configuration

Rename `prod-example.tfvars` to `prod.tfvars`. Fill in the values that fit your project needs.

**Be sure this file is not commited to the repo (its already added to .gitignore).** Consider using a key vault for any of the values you see fit. 

```bash
region             = "us-east-1"
db_password        = "SecretPassword"
db_name            = "my_app_db"
db_user            = "my_app_db_user"
main_domain_name   = "example.com"
git_url            = "https://github.com/space-rocket/my_app.git"
deploy_demo_docker = false
deploy_my_app      = true
has_db             = true
```

- `region`: The AWS region to launch your infrastructure in.
- `db_password`: A password used for database authentication.
- `db_name`: The name of the database.
- `db_user`: The user of the database.
- `main_domain_name`: The main domain name of a website, ie: example.com.
- `git_url`: The Git URL of the app you wish to deploy. Note for your app to be deployed, `deploy_my_app` has to be set to `true`.
- `deploy_demo_docker`: A boolean (true/false) Set to `true` to deploy a demo Docker container.
- `deploy_my_app`: A boolean value indicating whether to deploy your app from the `git_url` provided.
- `has_db`: A boolean value indicating whether a database is present.

### Terraform Variables Configuration

Our terraform.tfvars file looks like this:
```bash
vpc_cidr            = "10.123.0.0/16"
key_name            = "devops_key"
public_key_path     = "/home/ubuntu/.ssh/devops_rsa.pub"
private_key_path    = "/home/ubuntu/.ssh/devops_rsa"
main_instance_count = 3
```

Configure how many instances you want by specifying the main_instance_count.

You can create a ssh key with the following command:
```bash
ssh-keygen -f /home/ubuntu/.ssh/devops -t rsa
```

If different name than devops, be sure to update the public_key_path and private_key_path values.

## Usuage

To see the plan, run 
```bash
terraform plan -var-file="prod.tfvars"
```

Once that looks good, go ahead run Terraform apply with --auto-approve flag.
```bash
terraform apply -auto-approve -var-file="prod.tfvars"
```

## Authors

Michael Chavez

## License

MIT

## Acknowledgments

Special thanks to morethancertified course that was used as the basis and the Terraform and Ansible community.



