#!/bin/bash
yum install -y python3 git python3-pip
cd /home/ec2-user/workshop-ot/SCADA
python3 -m venv venv
source venv/bin/activate
pip install Flask
pip install pymodbus==2.5.3

