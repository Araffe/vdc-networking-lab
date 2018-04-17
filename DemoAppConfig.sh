# Update system
sudo apt-get update

# Install node.js & NPM
sudo apt-get install npm -y
curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash --
sudo apt-get install -y nodejs

# Clone Git repo for demo app
sudo apt-get install git -y
git clone https://github.com/araffe/nodejs-demoapp.git
cd nodejs-demoapp/
sudo npm install forever -g
sudo npm install
forever start ./bin/www