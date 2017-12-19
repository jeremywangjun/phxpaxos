
set -e  # exit immediately on error
set -x  # display all commands

cd third_party;

if [ ! -f protobuf/bin/protoc ] || [ ! -f protobuf/lib/libprotobuf.a ]; then
	if [ ! -d protobuf-jeremy ]; then
	    git clone https://github.com/jeremywangjun/protobuf.git protobuf-jeremy
	else
	    git pull origin master:protobuf-jeremy
	fi

	cd protobuf-jeremy
	./autogen.sh
	./configure --prefix=`pwd`/../protobuf
	make check
	make -j2
	make install

	cd ../
fi

if [ ! -f leveldb/lib/libleveldb.a ]; then
	if [ ! -d leveldb-jeremy ]; then
	    git clone https://github.com/jeremywangjun/leveldb.git leveldb-jeremy
	else
	    git pull origin master:leveldb-jeremy
	fi

	cd leveldb-jeremy
	make -j2

    mkdir -p ../leveldb/lib
	rm -f ../leveldb/lib/libleveldb.a
	ln -s `pwd`/out-static/libleveldb.a  ../leveldb/lib/libleveldb.a

    rm -f ../leveldb/include
    ln -s `pwd`/include ../leveldb

	cd ../
fi

if [ ! -f glog/lib/libglog.a ]; then
    if [ ! -d glog-jeremy ]; then
        git clone https://github.com/jeremywangjun/glog.git glog-jeremy
    else
        git pull origin master:glog-jeremy
    fi

    cd glog-jeremy

    #link gflags into glog
    mkdir -p third_party
    cd third_party
    if [ ! -d gflags-jeremy ]; then
        git clone https://github.com/jeremywangjun/gflags.git gflags-jeremy
    else
        git pull origin master:gflags-jeremy
    fi

    cd ../
    mkdir -p mybuild
    cd mybuild
    cmake -DCMAKE_INSTALL_PREFIX=`pwd`/../../glog ../
    make -j2
    make install

    cd ../../
fi

if [ ! -f gmock/lib/libgmock.a ] || [ ! -f gmock/lib/libgmock_main.a ] ||
   [ ! -f gtest/lib/libgtest.a ]; then
    if [ ! -d gtest-jeremy ]; then
        git clone https://github.com/jeremywangjun/googletest.git gtest-jeremy
    else
        git pull origin master:gtest-jeremy
    fi

    cd gtest-jeremy
    mkdir -p mybuild
    cd mybuild
    cmake -Dgtest_build_samples=ON ../
    make

    mkdir -p ../../gmock/lib
    mkdir -p ../../gtest/lib
    rm -f ../../gmock/lib/libgmock.a
    rm -f ../../gmock/lib/libgmock_main.a
    rm -f ../../gtest/lib/libgtest.a
    ln -s `pwd`/googlemock/libgmock.a ../../gmock/lib/libgmock.a
    ln -s `pwd`/googlemock/libgmock_main.a ../../gmock/lib/libgmock_main.a
    ln -s `pwd`/googlemock/gtest/libgtest.a ../../gtest/lib/libgtest.a

    rm -f ../../gmock/include
    rm -f ../../gtest/include
    ln -s `pwd`/../googlemock/include ../../gmock
    ln -s `pwd`/../googletest/include ../../gtest

    cd ../../
fi

if [ ! -f grpc/bin/grpc_cpp_plugin ] || [ ! -f grpc/lib/libgrpc.a ] ||
   [ ! -f grpc/lib/libgrpc++_unsecure.a ]; then
    if [ ! -d grpc-jeremy ]; then
        git clone https://github.com/jeremywangjun/grpc.git grpc-jeremy
    else
        git pull origin master:grpc-jeremy
    fi

    cd grpc-jeremy

    #git submodule update --init 1>&2
    if git submodule update --init; then
        echo ""
    else
        #workaround: git clone https://boringssl.googlesource.com/boringssl not work
        echo "workaround: git clone https://boringssl.googlesource.com/boringssl boringssl-with-bazel"
        cd third_party
        if [ ! -d boringssl-with-bazel ]; then
            git clone https://github.com/jeremywangjun/boringssl.git boringssl-with-bazel
        else
            git pull origin master:boringssl-with-bazel
        fi
        #contiue git clone other dependencies
        git submodule update --init
        cd ../
    fi

    make -j2
    mkdir -p ../grpc/lib
    rm -f ../grpc/lib/libgrpc.a
    rm -f ../grpc/lib/libgrpc++_unsecure.a
    ln -s `pwd`/libs/opt/libgrpc.a ../grpc/lib/libgrpc.a
    ln -s `pwd`/libs/opt/libgrpc++_unsecure.a ../grpc/lib/libgrpc++_unsecure.a

    rm -f ../grpc/include
    ln -s `pwd`/include ../grpc

    mkdir -p ../grpc/bin
    ln -s `pwd`/bins/opt/grpc_cpp_plugin ../grpc/bin/grpc_cpp_plugin

    cd ../
fi

cd ..

./autoinstall.sh

make

cd plugin
make
cd ../

rm -f lib
ln -s `pwd`/.lib/extlib lib

cd sample
make

cd ../

