#!/bin/bash
# finds all tarballs and extracts in the appropriate directory
find . -name "session*tar.gz" -execdir sh -c 'echo $0; mkdir `basename "$0" .tar.gz`; tar -xzvf $0 -C `basename "$0" .tar.gz`' {} \;
