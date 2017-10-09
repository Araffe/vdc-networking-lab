# Update system
sudo apt-get update

# Install node.js & NPM
sudo apt-get install npm -y
sudo apt-get install nodejs-legacy -y

# Clone Git repo for demo app
sudo apt-get install git -y
git clone https://github.com/araffe/nodejs-demoapp.git
cd nodejs-demoapp/
sudo npm install forever -g
sudo npm install
forever start ./bin/www