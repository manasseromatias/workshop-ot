#!/bin/bash
yum install -y python3 git python3-pip
pip install Flask
pip install pymodbus==2.5.3
python3 -m venv venv
source venv/bin/activate
