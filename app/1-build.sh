cd ./bin/hg_lua-ubuntu-x64/harfang/assetc
./assetc ../../../../assets -api GL
cd ../../../../
rm -f assets_compiled/common/image-sequences/intro-couchot-bw_seq.png
cp -v assets/common/image-sequences/intro-couchot-bw_seq.png assets_compiled/common/image-sequences/
rm -f assets_compiled/common/image-sequences/static_seq.png
cp -v assets/common/image-sequences/static_seq.png assets_compiled/common/image-sequences/
