# Update system
sudo apt-get Update

# Install node.js & NPM
sudo apt-get install npm -y
sudo apt-get install nodejs-legacy -y

# Clone Git repo for demo app
git clone https://github.com/benc-uk/nodejs-demoapp.git
cd nodejs-demoapp/
npm install package.json
npm start
