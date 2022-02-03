#!/bin/sh
./catjs.sh
mv www/chars chars-temp
mv www/images/te te-temp
mv www/images/ne ne-temp
mv www/utils utils-temp
yarn harp ./public ./www
mv chars-temp www/chars
mv te-temp www/images/te
mv ne-temp www/images/ne
mv utils-temp www/utils
