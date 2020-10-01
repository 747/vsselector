#!/bin/sh
./catjs.sh
mv www/chars chars-temp
mv www/images/te te-temp
mv www/utils utils-temp
yarn harp compile
mv chars-temp www/chars
mv te-temp www/images/te
mv utils-temp www/utils
