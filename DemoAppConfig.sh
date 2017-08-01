# Update system
sudo apt-get update

# Install node.js & NPM
sudo apt-get install npm -y
sudo apt-get install nodejs-legacy -y

# Clone Git repo for demo app
git clone https://github.com/benc-uk/nodejs-demoapp.git
cd nodejs-demoapp/
sudo npm install
npm start
