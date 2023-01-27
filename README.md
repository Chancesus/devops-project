# Using Terraform with Jenkins to provision AWS EC2. Configuration with Ansible.

---

#### The following is a broad overview of the steps involved and not an in-depth guide.

### Prerequisites

- AWS Account
  
- Terraform
  
- Ansible
  
- Jenkins
  
- GitHub
  

### AWS Account Setup

1. Create an IAM Role
  
2. Create EC2 Key pair to SSH
  
3. EC2 Security Group
  

### GitHub

1. Create a GitHub repo
  
2. Generate an SSH Key
  
3. Add SSH Key to GitHub in profile settings
  

### Jenkins Setup

1. Start up Jenkins and add CloudBees AWS Credentials plugin
  
2. Add credentials for AWS and the generated GitHub key
  
3. Under Manage Users, add an API Key under your user
  

### Terraform

1. Set up file structure
  
  ```apacheconf
  .
  ├── ansible
  │   └── rmq
  │       └── rmq_playbook.yml
  └── terraform
      └── rmq
          ├── main.tf
          └── variables.tf
  ```
  
2. Create main.tf file
  
3. Create variables.tf file
  
4. Push to Github
  

### Jenkins Job

1. Create a new freestyle job
  
2. Set up Job parameters
  
3. Set up Source code management
  
4. Set AWS credentials in Build environment
  
5. Add Terraform commands to Build steps using Shell script
  

### Ansible

1. Create 2 files under ansible install, "ansible.cfg" and "aws_ec2.yaml"
  
2. Create a file under ansible/group_vars containing key pair
  
3. Create a file for the ansible playbook.
  

### Running the Job

1. Create another Jenkins job for Ansible Configuration
  
2. Add a trigger to the Jenkins build Job
  
3. Start build in Jenkins
