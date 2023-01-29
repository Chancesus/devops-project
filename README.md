# Using Terraform with Jenkins to provision AWS EC2. Configuration with Ansible.

---

### Prerequisites

- AWS Account
  
- Terraform
  
- Ansible
  
- Jenkins
  
- GitHub
  

### AWS Account Setup

1. Head to IAM, Users, then "Add User". After this give the user a name, attach the policy "AmazonEC2FullAccess", and create. Once the user is created, click on it in the list of users. Click on the "Security Credentials" tab. Then scroll down to Access Keys section and generate them. This is the new way to give users Programmatic access.
  
  ![](file:///home/chance/snap/marktext/9/.config/marktext/images/2023-01-27-15-59-28-image.png?msec=1675021490742)
  
2. Next, head to EC2 in the management console and Key Pairs. Create a Key pair. The defaults are okay so just give this a name you will remember and create.
  
  ![](file:///home/chance/snap/marktext/9/.config/marktext/images/2023-01-27-16-06-34-image.png?msec=1675021490742)
  
3. Also in EC2, head to Security groups and create one. For this we need some inbound rules. Create two custom inbound rules for 15672. One is going to be "Anywhere IVP4" and the other will be "Anywhere IVP6". This port is specific to RabbitMQ, so if you want to use something else the port numbers will be different. Also be sure to add an SSH rule and select your IP as the source. Make sure to keep note of the SG-ID, we will need it while setting up terraform.
  
  ![](file:///home/chance/snap/marktext/9/.config/marktext/images/2023-01-27-16-15-33-image.png?msec=1675021490753)
  

### GitHub

1. Create a GitHub repo
  
2. Generate an SSH Key
  
  ```bash
  ssh-keygen
  ```
  
  ![](file:///home/chance/snap/marktext/9/.config/marktext/images/2023-01-27-16-29-54-image.png?msec=1675021490742)
  
  You can give this a name if you like. Copy the public version of the key. If you can't find it you can run this command.
  
  ```bash
  cat ~/.ssh/jenkins_guidekey.pub
  ```
  
3. Head here in your GitHub settings and create a New SSH Key. Paste in the public key you just copied.
  
  ![](file:///home/chance/snap/marktext/9/.config/marktext/images/2023-01-27-16-34-06-image.png?msec=1675021490742)
  

### Jenkins Setup

1. Start up Jenkins with the command `sudo service jenkins start`
  
  Head over to http://localhost:8080 and go through the set up steps.
  
  You can grab the inital password from
  
  `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
  
2. Once you are inside, head to "Manage Jenkins" > "Manage Plugins" and from the available plugins tab install "CloudBees AWS Credentials"
  
3. Going back to "Manage Jenkins" go to "Manage Credentials"> "Global Creds" and Add Credential. Pick SSH Username with private key as the kind. Fill out the other fields and copy the private version of the key we created earlier using
  
  `cat ~/.ssh/jenkins_guidekey`
  
  Paste this in and create.
  
  ![](file:///home/chance/snap/marktext/9/.config/marktext/images/2023-01-27-16-47-47-image.png?msec=1675021490743)
  
4. Add antoher credential in the same spot but this one will be of kind "AWS Credentials" instead. Enter your user's name, Access Key and Secret Key from the AWS user we created earlier.
  
5. Finally, head back to "Manage Users" again and click on your user. Click on configure then generate an API Token. Copy this and keep it, we will need it for the end.
  

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
  
2. Open up the main.tf file in your IDE
  
  ```hcl
  provider "aws" {
      region = "us-east-1"
      profile = var.profile
  }
  ```
  

resource "aws_instance" "rmq" {
 ami = "ami-07ebfd5b3428b6f4d"
 instance_type = "t2.micro"
 key_name = "Your_Key_Name"
 vpc_security_group_ids = "Your_SG_ID"

```
   tags = {
       Name = var.name
       group = var.group
```

    }
 }

````
A few things to note here. You can use whatever region you prefer. Be sure to check the "ami" because there could be an updated version of Ubuntu image. Otherwise fill in your Key Name and SG ID. 

3. Create variables.tf file

```hcl
variable "name" {
    description = "name the instance on deploy"
}

variable "group" {
    description = "Group name that ansible will use for dynamic inventory"
}

variable "profile"{
    description = "Which profile to use for IAM"
}
````

The way terraform processes files is all as one. So you could include this in the main.tf file but it is good practice to separate these.

4. Configure AWS profile and Push to Github
  
  ```bash
  aws configure --profile
  git add .
  git commit -m "initial commit with terraform scripts"
  git push
  ```
  

### Jenkins Job

1. Create a new freestyle job called "Terraform_Build". Then select "This project is parameterized". We are going to create 4 different sections here. First choose (Choice)
  
  ![](file:///home/chance/snap/marktext/9/.config/marktext/images/2023-01-27-19-01-38-image.png?msec=1675021490743)
  
  Next, create a Boolean parameter named Ansible.
  
  ![](file:///home/chance/snap/marktext/9/.config/marktext/images/2023-01-27-19-02-50-image.png?msec=1675021490743)
  
  Finally, create two string parameters. One named "Name" and the other "Group". Since I am using Rabbitmq as my example I give the values "rabbitmq" and "rmq" respectively.
  
  ![](file:///home/chance/snap/marktext/9/.config/marktext/images/2023-01-27-19-06-07-image.png?msec=1675021490743)
  
2. Select Git for Source Control Management. Paste the URL to your Repo here. Use the Jenkins credentials we created earlier here.
  
3. Under Build Environment towards the bottom, select "Use Secret text(s) or file(s)". Then use your AWS Access key and Secret key. Choose the AWS credentials we created earlier in Jenkins.
  
4. Finally, in build steps add a Shell build in the drop down. This is where we will add the Terraform commands.
  
  ```php
  if [ $Action = "apply" ]; then
      terraform -chdir=terraform/rmq init
      terraform -chdir=terraform/rmq $Action -var 'name=RMQEC2' -var 'profile=DevopsAdmin' -var 'group=$Group' -auto-approve 
  elif [ $Action = "plan" ]; then
      terraform -chdir=terraform/rmq init
      terraform -chdir=terraform/rmq $Action -var 'name=RMQEC2' -var 'profile=DevopsAdmin' -var 'group=rmq' 
  else
      terraform -chdir=terraform/rmq init
      terraform -chdir=terraform/rmq $Action -var 'name=RMQEC2' -var 'profile=DevopsAdmin' -var 'group=rmq' -auto-approve 
  fi
  ```
  

### Ansible

1. Create 2 files under ansible install, "ansible.cfg" and "group_vars/tag_group_rmq.pem"". The Ansible configure file stops ansible from prompting us to add a new host every time we run the build. The Group vars file helps apply parameters to our EC2 group tag. Here we are adding the ssh private key and user.
  
  ```bash
  printf "
  [defaults]
  host_key_checking = False" | sudo tee /etc/ansible/ansible.cfg
  
  
  sudo mkdir /etc/ansible/group_vars
  printf "
  ---
  ansible_ssh_private_key_file: /var/lib/jenkins/.ssh/YOURKEYPAIR.pem
  ansible_user: ubuntu" | sudo tee /etc/ansible/group_vars/tag_group_rmq.yaml
  ```
  
2. Then create an "aws_ec2.yaml" file under /ansible directory. This is the AWS plugin that will help with the dynamic inventory.
  
  ```yaml
  plugin: amazon.aws.aws_ec2
  boto_profile: YOURAWSPROFILE
  regions:
      - us-east-1
  strict: False
  keyed_groups:
      - prefix: tag
  key: "tags"
  compose:
      ansible_host: ip_address
  ```
  
3. Finally, lets create our Ansilbe Playbook. In our playbook, we Install RMQ, run it, then configure our users.
  
  ```yaml
  
  ---
      - name: Configure Jenkins Job
        hosts: tag_group_rmq
  
        tasks:
  
          - name: Install RMQ
            become: yes
            shell: |
              apt-get update -y
              apt-get install curl gnupg -y
              curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | apt-key add -
              apt-get install apt-transport-https
              tee /etc/apt/sources.list.d/bintray.rabbitmq.list <<EOF
              deb https://dl.bintray.com/rabbitmq-erlang/debian bionic erlang
              deb https://dl.bintray.com/rabbitmq/debian bionic main
              EOF
              apt-get update -y
              apt-get install rabbitmq-server -y --fix-missing
          
          - name: Start RMQ
            become: yes
            shell: service rabbitmq-server start
  
          - name: Enable RMQ Admin Dash
            become: yes
            shell: rabbitmq-plugins enable rabbitmq_management
  
          - name: Add initial user
            become: yes
            shell: |
              rabbitmqctl add_user YOUR_USER NEW_PASS
              rabbitmqctl set_user_tags YOUR_USER administrator
  ```
  

### Running the Job

1. Create another Jenkins job for Ansible Configuration. Set up Git for control management just like we did in our last Jenkins Job. Then add a build step with this shell script
  
  ```bash
  ansible-playbook -i /etc/ansilbe/aws_ec2.yaml ansible/rmq/rmq_playbook.yml
  ```
  
2. We also need to add a Build Trigger and check "Trigger Builds remotely" and name it.
  
  ![](file:///home/chance/snap/marktext/9/.config/marktext/images/2023-01-29-12-27-52-image.png?msec=1675024072449)
  
3. Finally, we have to add the Ansible trigger into our first Jenkins Job. Make sure to add in your username and the Token
  
  ```php
  if [ $Action = "apply" ]; then
      terraform -chdir=terraform/rmq init
      terraform -chdir=terraform/rmq $Action -var 'name=RMQEC2' -var 'profile=DevopsAdmin' -var 'group=$Group' -auto-approve 
      if [ $Ansible ]; then
          curl http://localhost:8080/job/YOUR_SECOND_JENKINS_JOB/build?token=YOUR_TOKEN_NAME
          --user YOUR_USER:YOUR_API_KEY_TOKEN
  
  elif [ $Action = "plan" ]; then
      terraform -chdir=terraform/rmq init
      terraform -chdir=terraform/rmq $Action -var 'name=RMQEC2' -var 'profile=DevopsAdmin' -var 'group=rmq' 
  else
      terraform -chdir=terraform/rmq init
      terraform -chdir=terraform/rmq $Action -var 'name=RMQEC2' -var 'profile=DevopsAdmin' -var 'group=rmq' -auto-approve 
  fi
  ```
  
4. That's it! Now head to jenkins dashboard and run the build with Ansible boolean set to "True" and Terraform action "Apply"!
