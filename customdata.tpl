echo "** Updating package lists..."
sudo apt-get update -y &&

echo "** Installing dependencies..."
sudo apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common &&

echo "** Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - &&

echo "** Adding Docker repository..."
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian bullseye stable" &&

echo "** Updating package lists again..."
sudo apt-get update -y &&

echo "** Installing Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io -y &&

sudo usermod -aG docker ubuntu
echo "** Docker installation complete!"