# Install and Configure Docker-Ce
- 1 - sudo su - --> Login as root user
- 2 - hostnamectl set-hostname 'docker-server' --> Change hostname
- 3 - yum install -y yum-utils device-mapper-persistent-data lvm2 --> Set up stable repository
- 4 - yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo --> Add docker-ce (community edition) to yum repo
- 5 - yum repolist --> Verify docker-ce repo
- 6 - yum install -y docker-ce --> Install docker-ce to Docker-Server
- 7 - usermod -aG docker centos --> Add centos user to docker group
- 8 - reboot --> Reboot Docker-Server to apply changes
- 9 - sudo systemctl start
- 10 - sudo systemctl enable

# Install Docker Compose
- 1 - sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
- 2 - chmod +x /usr/local/bin/docker-compose
 
 
 ---------------------------------------------------------------------------------------------------
# Create Jenkins and Centos7 Docker Container with Docker Compose
- 1 - mkdir jenkins-data --> Create jenkins-data directory on centos user home directory
- 2 - cd jenkins-data
- 3 - mkdir jenkins_home --> Create jenkins_home directory to persistent jenkins data.
- 4 - vim docker-compose.yml --> Create docker-compose file.
- 5 - mkdir Centos7
- 6 - cd Centos7
- 7 - ssh-keygen -f remote-key --> Create ssh key for passportless connection
- 8 - vim Dockerfile --> Create Dockerfile
- 9 - docker-compose up -d --> Create and run docker containers on detach mode.

-----------------------------------------------------------------------------------------------------
- 1 - docker exec -it jenkins bash --> connect to jenkins container
- 2 - ssh remote_user@remote_host --> SSH to remote_host container from Jenkins container
- 3 - docker cp remote-key jenkins:/tmp/remote-key --> Copy ssh key from Docker-Server Centos7 folder to Jenkins container
- 4 - docker exec -it jenkins bash --> connect to jenkins container
- 5 - ssh -i /tmp/remote-key remote_user@remote_host --> SSH from jenkins container to remote_host container with ssh key, wihtout password

-------------------------------------------------------------------------------------------------------
# Test and Configure the Jenkins
- 1 - Go to your browser and hit jenkins container ip address and port
- 2 - Set up jenkins configuration
- 3 - Go to Manage Plugins and install SSH plugin
- 4 - Manage Credentials
  - Kind : SSH Username with private key
  - Username : remote_user
  - Private Key : copy and paste remote-key file content from Docker-Server Centos7 directory

------------------------------------------------------------------------------------------------
# Create MySQL Container
- 1 - Add MySQL container specification to docker-compose.yml
- 2 - mkdir db_data --> Create db_data folder on Docker-Server in jenkins-data folder to persistent db data
- 3 - docker-compose up -d
- 4 - docker-exec -it db bash
- 5 - mysql -u root -p --> Connect to DB
  - system clear; --> to clear screen outputs
  - show databases --> list the databases that our database server has.

---------------------------------------------------------------------------------------------------
# Backup Docker Container SQL Database to AWS S3 Bucket
- 1 - We need to install MySQL client and AWS cli(Command Line Input) in Remote-Server container. In order to automate we have to edit existing dockerfile(Remote-Server docker file because we are going to use our Remote-Server container as our MySQL GUI)
    - yum install -y mysql
    - curl -O https://bootstrap.pypa.io/get-pip.py
    - python get-pip.py
    - pip install awscli --upgrade
- 2 - docker-compose build --> Build iamge with mysql client and aws cli.
- 3 - docker-compose up -d --> Create or update containers.
- 4 - docker exec -it Remote-Server bash --> connect to remote_host
    - mysql -u(user) root -h(host) db_host -p (password) --> Connect to database server (db_host) from Remote-Server(remote_host)
    - create database testdb; --> Create a test Database
    - use testdb; --> Switch database
    - create table info (name varchar(20), lastname(20), age(3)); --> Create table on testdb.
    - insert into info ('Test', 'Test1', 1); --> Populate data to info table.
    - Go to aws console web page and create S3 bucket with default specs.
    - Create AWS User with programatic access to give full access to S3 bucket that we create.
    - mysqldump -u root -h db_host -p testdb > /tmp/db.sql --> Backup testdb database to Remote-Server inside /tmp/db.sql
    - cat /tmp/db.sql --> Verify bakcup to Remote-Server
    - aws configure
    - aws s3 cp /tmp/db.sql s3://mysql-docker-backup/db.sql --> Copy db.sql file from Remote-Server to back it up AWS S3 bucket.

# Automate Backup Process
- 1 - Create shell script with step that we done for backup.
- 2 - Create Credentials from Jenkins for AWS Secret key
      - Manage Jenkins
      - Manage Credentials
      - Add Crendtials
        - Kind : Secret text
        - Secret : Copy Paste AWS Secret Access Key
        - ID : AWS_SECRET
- 3 - Create Credentials from Jenkins for mysql password
      - Manage Jenkins
      - Manage Credentials
      - Add Crendtials
        - Kind : Secret text
        - Secret : 1234
        - ID : MYSQL_SECRET
- 4 - Build new Jenkins project
    - This project is parameterized
    - Add String Parameter for script.sh parameters
    - Build Environment and add AWS_SECRET and MYSQL_SECRET
    - Build Execute shell script on remote host using ssh
    - Execute shell script on remote host using ssh
      - Pre build script
      - /tmp/aws-s3-backup.sh $DB_HOST $DB_PASSWORD $DB_NAME $AWS_SECRET $BUCKET_NAME

# Ansible
- 1 - mkdir -p jenkins-ansible --> Create jenkins-ansible folder inside jenkins-data
- 2 - vim Dockerfile --> Create Dockerfile inside jenkins-ansible folder to automate ansible installation
- 3 - docker-compose build --> To build new docker image for Jenkins container
- 4 - cd jenkins_home
- 5 - mkdir ansible
- 6 - cp /centos7/remote-key /jenkins_home/ansible/ --> Copy remote-key to ansible folder to share with other containers
- 7 - docker exec -it Jenkins bash --> Login to Jenkins container
- 8 - cd jenkins_home/ansible --> Verify if remote-key copied
- 9 - Create ansible hosts and playbook files in jenkins-ansible folder
    - vim hosts
    - vim play.yml
- 10 - cp hosts /jenkins_home/ansible --> Copy hosts file to Jenkins container
- 11 - vim /jenkins-data/jenkins_home/.ssh/known_hosts --> Delete content of known_hosts file
- 12 - Login Jenkins container
- 13 - ansible-playbook -i hosts play.yml --> Test if ansible works
- 14 - Install ansible plugin to Jenkins GUI

# Nginx
- 1 - mkdir web --> Create web folder inside jenkins-ansible
- 2 - mkdir bin conf --> Create bin and conf folder inside web
- 3 - Create nginx.conf and nginx.repo file inside conf folder
- 4 - Create Dockerfile inside web folder for web server container
- 5 - Edit docker-compose.yml to add web server container
- 6 - docker-compose build --> To build web server image
- 7 - docker-compose up -d --> To create and run web server container
- 8 - docker exec -it web bash
- 9 - cd /var/www/html
- 10 - vim index.php --> create index page for Nginx web server