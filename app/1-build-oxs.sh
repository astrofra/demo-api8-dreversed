cd ./bin/hg_lua-osx-arm64/harfang/assetc
./assetc ../../../../assets -api MTL
cd ../../../../
rm -f assets_compiled/common/image-sequences/intro-couchot-bw_seq.png
cp -v assets/common/image-sequences/intro-couchot-bw_seq.png assets_compiled/common/image-sequences/
