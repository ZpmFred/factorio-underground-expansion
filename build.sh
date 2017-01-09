#!/bin/bash

BUILD_NAME="$(python getFolderName.py)"

rm -r build

mkdir build
mkdir build/$BUILD_NAME

cp *.lua build/$BUILD_NAME/
cp info.json build/$BUILD_NAME/
cp -R prototypes build/$BUILD_NAME/
cp -R graphics build/$BUILD_NAME

cd build
zip -r $BUILD_NAME.zip $BUILD_NAME

rm -r $BUILD_NAME