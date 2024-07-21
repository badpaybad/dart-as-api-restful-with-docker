dart create -t console cli

# android

./install.sh

# desktop linuxx64

sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt-get update
sudo apt-get install gcc-7 g++-7

sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 70
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 70

sudo update-alternatives --config gcc
sudo update-alternatives --config g++

wget https://github.com/bazelbuild/bazel/releases/download/4.2.1/bazel-4.2.1-installer-linux-x86_64.sh
chmod +x bazel-4.2.1-installer-linux-x86_64.sh
./bazel-4.2.1-installer-linux-x86_64.sh --user


sudo apt install bazel-4.2.1

export PATH="$PATH:$HOME/bin"

git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
git checkout v2.8.0

./configure

bazel build //tensorflow:libtensorflow.so
 to: bazel-bin/tensorflow/libtensorflow.so

