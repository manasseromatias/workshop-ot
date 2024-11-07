#!/bin/bash

# Update the package index
sudo yum update -y

# Install Python 3 and pip
sudo yum install -y python3
sudo yum install -y python3-pip

# Navigate to the project directory
cd /home/ec2-user/workshop-ot/SCADA

# Set up the virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required Python packages
pip install Flask pymodbus

# Confirm installations
echo "Installed Flask version:" $(python -c "import flask; print(flask.__version__)")
echo "Installed pymodbus version:" $(python -c "import pymodbus; print(pymodbus.__version__)")

echo "Setup complete! Your virtual environment is ready and packages are installed."
