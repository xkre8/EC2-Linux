#!/bin/bash

# Script to uninstall database clients on AWS EC2 Linux
# This script uninstalls PostgreSQL, MySQL, Oracle, MariaDB, MSSQL, DocumentDB, DynamoDB, Aurora, and AWS CLI

echo "==================================================================="
echo "Uninstalling database clients and AWS tools from this system"
echo "==================================================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to uninstall a package if it exists
uninstall_package() {
    if rpm -qa | grep -q "$1"; then
        echo "Uninstalling $2..."
        sudo yum remove -y "$1"* 
        echo "$2 has been uninstalled."
    else
        echo "$2 package is not installed. Skipping."
    fi
}

# Check if running as root or with sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

# Detect Amazon Linux version
if grep -q "Amazon Linux 2" /etc/os-release; then
    echo "Running on Amazon Linux 2"
    AMAZON_LINUX_VERSION=2
elif grep -q "Amazon Linux 2023" /etc/os-release; then
    echo "Running on Amazon Linux 2023"
    AMAZON_LINUX_VERSION=2023
else
    echo "Warning: This script is optimized for Amazon Linux. Proceeding anyway."
    AMAZON_LINUX_VERSION=0
fi

# Uninstall PostgreSQL
echo "Checking and uninstalling PostgreSQL client..."
if command_exists psql || rpm -qa | grep -q postgresql; then
    uninstall_package "postgresql" "PostgreSQL"
    sudo rm -f /usr/bin/psql
    echo "Cleaned up PostgreSQL client files."
else
    echo "PostgreSQL client is not installed. Skipping."
fi
echo ""

# Uninstall MySQL
echo "Checking and uninstalling MySQL client..."
if command_exists mysql || rpm -qa | grep -q mysql; then
    uninstall_package "mysql" "MySQL"
    sudo rm -f /usr/bin/mysql
    echo "Cleaned up MySQL client files."
else
    echo "MySQL client is not installed. Skipping."
fi
echo ""

# Uninstall Oracle client
echo "Checking and uninstalling Oracle client..."
if [ -d "/opt/oracle" ] || [ -d "/u01/app/oracle" ] || command_exists sqlplus; then
    echo "Oracle client components found. Uninstalling..."
    
    # Remove Oracle packages if any
    if rpm -qa | grep -q oracle; then
        sudo yum remove -y $(rpm -qa | grep oracle)
    fi
    
    # Remove Oracle directories
    if [ -d "/opt/oracle" ]; then
        sudo rm -rf /opt/oracle
    fi
    
    if [ -d "/u01/app/oracle" ]; then
        sudo rm -rf /u01/app/oracle
    fi
    
    # Unset Oracle environment variables
    unset ORACLE_HOME ORACLE_SID TNS_ADMIN
    
    # Remove Oracle from profile files
    for file in /etc/profile.d/*oracle*.sh; do
        if [ -f "$file" ]; then
            sudo rm -f "$file"
        fi
    done
    
    echo "Oracle client has been uninstalled."
else
    echo "Oracle client is not installed. Skipping."
fi
echo ""

# Uninstall MariaDB
echo "Checking and uninstalling MariaDB client..."
if command_exists mariadb || rpm -qa | grep -q mariadb; then
    uninstall_package "mariadb" "MariaDB"
    sudo rm -f /usr/bin/mariadb
    echo "Cleaned up MariaDB client files."
else
    echo "MariaDB client is not installed. Skipping."
fi
echo ""

# Uninstall MSSQL Tools
echo "Checking and uninstalling MSSQL tools..."
if command_exists sqlcmd || rpm -qa | grep -q mssql-tools; then
    # Uninstall MSSQL tools
    if rpm -qa | grep -q mssql-tools; then
        sudo yum remove -y mssql-tools unixODBC-devel
    fi
    
    # Remove Microsoft repositories
    if [ -f /etc/yum.repos.d/mssql-release.repo ]; then
        sudo rm -f /etc/yum.repos.d/mssql-release.repo
    fi
    
    echo "MSSQL tools have been uninstalled."
else
    echo "MSSQL tools are not installed. Skipping."
fi
echo ""

# Handle Docker-based clients
echo "Checking for Docker-based database clients..."
if command_exists docker; then
    echo "Docker found. Checking for database containers and images..."
    
    # Stop and remove DocumentDB containers
    if docker ps -a | grep -q documentdb; then
        echo "Removing DocumentDB containers..."
        docker stop $(docker ps -a | grep documentdb | awk '{print $1}')
        docker rm $(docker ps -a | grep documentdb | awk '{print $1}')
    else
        echo "No DocumentDB containers found."
    fi
    
    # Stop and remove DynamoDB containers
    if docker ps -a | grep -q dynamodb; then
        echo "Removing DynamoDB containers..."
        docker stop $(docker ps -a | grep dynamodb | awk '{print $1}')
        docker rm $(docker ps -a | grep dynamodb | awk '{print $1}')
    else
        echo "No DynamoDB containers found."
    fi
    
    # Stop and remove Aurora containers
    if docker ps -a | grep -q aurora; then
        echo "Removing Aurora containers..."
        docker stop $(docker ps -a | grep aurora | awk '{print $1}')
        docker rm $(docker ps -a | grep aurora | awk '{print $1}')
    else
        echo "No Aurora containers found."
    fi
    
    # Remove other database containers
    for db in postgres mysql oracle mariadb mssql; do
        if docker ps -a | grep -q $db; then
            echo "Removing $db containers..."
            docker stop $(docker ps -a | grep $db | awk '{print $1}')
            docker rm $(docker ps -a | grep $db | awk '{print $1}')
        fi
    done
    
    # Remove database images
    echo "Checking for database Docker images..."
    for image in documentdb dynamodb aurora postgres mysql oracle mariadb mssql; do
        if docker images | grep -q $image; then
            echo "Removing Docker images related to $image..."
            docker rmi $(docker images | grep $image | awk '{print $3}')
        fi
    done
else
    echo "Docker is not installed. Skipping Docker-based clients cleanup."
fi
echo ""

# Uninstall AWS CLI
echo "Checking and uninstalling AWS CLI..."
if command_exists aws; then
    echo "AWS CLI is installed. Uninstalling..."
    
    # Check how AWS CLI was installed
    if [ -d "/usr/local/aws-cli" ]; then
        # Bundled installer method
        sudo rm -rf /usr/local/aws-cli
        sudo rm -f /usr/local/bin/aws
        sudo rm -f /usr/local/bin/aws_completer
    elif pip list 2>/dev/null | grep -q awscli; then
        # pip method
        sudo pip uninstall -y awscli
    elif pip3 list 2>/dev/null | grep -q awscli; then
        # pip3 method
        sudo pip3 uninstall -y awscli
    elif rpm -qa | grep -q awscli; then
        # yum/rpm method
        sudo yum remove -y awscli
    else
        # Manual cleanup
        sudo rm -f $(which aws)
        sudo rm -f $(which aws_completer)
    fi
    
    # Remove AWS configuration
    if [ -d "$HOME/.aws" ]; then
        echo "Do you want to remove AWS configuration files? (y/n)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            rm -rf "$HOME/.aws"
            echo "AWS configuration files removed."
        else
            echo "AWS configuration files preserved."
        fi
    fi
    
    echo "AWS CLI has been uninstalled."
else
    echo "AWS CLI is not installed. Skipping."
fi
echo ""

# Clean up Python packages related to AWS services
echo "Cleaning up Python packages related to AWS services..."
if command_exists pip; then
    for package in boto boto3 botocore aws-sam-cli dynamodb-local amazon-documentdb-tools; do
        if pip list 2>/dev/null | grep -q "^$package "; then
            echo "Uninstalling Python package: $package"
            sudo pip uninstall -y $package
        fi
    done
fi

if command_exists pip3; then
    for package in boto boto3 botocore aws-sam-cli dynamodb-local amazon-documentdb-tools; do
        if pip3 list 2>/dev/null | grep -q "^$package "; then
            echo "Uninstalling Python package: $package"
            sudo pip3 uninstall -y $package
        fi
    done
fi
echo ""

# Cleanup environment variables
echo "Cleaning up environment variables..."
for var in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_DEFAULT_REGION \
           PGUSER PGPASSWORD PGDATABASE PGHOST PGPORT \
           MYSQL_HOST MYSQL_TCP_PORT MYSQL_PWD \
           ORACLE_HOME ORACLE_SID TNS_ADMIN \
           MSSQL_CLI_SERVER MSSQL_CLI_USER MSSQL_CLI_PASSWORD; do
    unset $var 2>/dev/null
    if grep -q "export $var" ~/.bashrc; then
        sed -i "/export $var/d" ~/.bashrc
    fi
    if grep -q "export $var" ~/.bash_profile; then
        sed -i "/export $var/d" ~/.bash_profile
    fi
done
echo ""

echo "==================================================================="
echo "Database clients and AWS tools uninstallation complete."
echo "You may need to log out and log back in for all changes to take effect."
echo "==================================================================="
