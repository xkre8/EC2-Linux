#!/bin/bash

# Script to check if database clients are installed on AWS EC2 Linux
# This script checks for PostgreSQL, MySQL, Oracle, MariaDB, MSSQL, DocumentDB, DynamoDB, Aurora, and AWS CLI

echo "==================================================================="
echo "Checking for installed database clients and AWS tools on this system"
echo "==================================================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check specific package installation
check_rpm_package() {
    if rpm -qa | grep -q "$1"; then
        echo "✓ $2 is installed"
        return 0
    else
        echo "✗ $2 is not installed"
        return 1
    fi
}

# Check OS version
echo "OS Information:"
cat /etc/os-release
echo ""

# Check PostgreSQL
echo "Checking PostgreSQL client..."
if command_exists psql; then
    echo "✓ PostgreSQL client is installed"
    psql --version
else
    check_rpm_package "postgresql" "PostgreSQL package"
fi
echo ""

# Check MySQL
echo "Checking MySQL client..."
if command_exists mysql; then
    echo "✓ MySQL client is installed"
    mysql --version
else
    check_rpm_package "mysql" "MySQL package"
fi
echo ""

# Check Oracle
echo "Checking Oracle client..."
if [ -d "/opt/oracle" ] || [ -d "/u01/app/oracle" ]; then
    echo "✓ Oracle directories found"
    if [ -n "$ORACLE_HOME" ]; then
        echo "  ORACLE_HOME is set to: $ORACLE_HOME"
    fi
    if command_exists sqlplus; then
        echo "  sqlplus is installed"
        sqlplus -v
    fi
else
    echo "✗ Oracle client directories not found"
fi
echo ""

# Check MariaDB
echo "Checking MariaDB client..."
if command_exists mariadb; then
    echo "✓ MariaDB client is installed"
    mariadb --version
else
    check_rpm_package "mariadb" "MariaDB package"
fi
echo ""

# Check MSSQL
echo "Checking MSSQL tools..."
if command_exists sqlcmd; then
    echo "✓ MSSQL sqlcmd is installed"
    sqlcmd -?
else
    check_rpm_package "mssql-tools" "MSSQL tools package"
fi
echo ""

# Check Docker for potential container-based clients
echo "Checking Docker (for DocumentDB, DynamoDB, Aurora containers)..."
if command_exists docker; then
    echo "✓ Docker is installed"
    docker --version
    
    echo "  Checking for database-related Docker containers..."
    if docker ps -a | grep -q 'documentdb\|dynamodb\|aurora\|postgres\|mysql\|mariadb\|oracle\|mssql'; then
        echo "  ✓ Database-related containers found:"
        docker ps -a | grep -E 'documentdb|dynamodb|aurora|postgres|mysql|mariadb|oracle|mssql'
    else
        echo "  ✗ No database-related containers found"
    fi
    
    echo "  Checking for database-related Docker images..."
    if docker images | grep -q 'documentdb\|dynamodb\|aurora\|postgres\|mysql\|mariadb\|oracle\|mssql'; then
        echo "  ✓ Database-related images found:"
        docker images | grep -E 'documentdb|dynamodb|aurora|postgres|mysql|mariadb|oracle|mssql'
    else
        echo "  ✗ No database-related images found"
    fi
else
    echo "✗ Docker is not installed"
fi
echo ""

# Check AWS CLI
echo "Checking AWS CLI..."
if command_exists aws; then
    echo "✓ AWS CLI is installed"
    aws --version
else
    echo "✗ AWS CLI is not installed"
fi
echo ""

# Check Python packages for AWS SDK clients
echo "Checking Python packages for AWS SDK clients..."
if command_exists pip; then
    echo "Python pip packages:"
    pip list | grep -E 'boto|aws|dynamodb|documentdb|aurora'
elif command_exists pip3; then
    echo "Python pip3 packages:"
    pip3 list | grep -E 'boto|aws|dynamodb|documentdb|aurora'
else
    echo "✗ pip/pip3 not found, cannot check Python packages"
fi
echo ""

# Check for specific AWS service configurations
echo "Checking for AWS configuration files..."
if [ -d "$HOME/.aws" ]; then
    echo "✓ AWS configuration directory found"
    ls -la $HOME/.aws
else
    echo "✗ AWS configuration directory not found"
fi
echo ""

# Summary
echo "==================================================================="
echo "Database Clients Check Summary:"
echo "==================================================================="
echo "To uninstall detected components, run the uninstall script."
echo "==================================================================="
