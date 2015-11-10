# call_variants
A ruffus pipeline to call variants.


# Prerequisites
I assume git, make, gcc, etc are already installed.

### Ubuntu
```
sudo apt-get install python-dev
sudo apt-get install python-pip
sudo apt-get install python-numpy
sudo pip install pysqlite
```

## Installation
```
git clone git@github.com:rpetit3-science/call_variants.git
cd call_variants
make
make test
```

Something like to the following will be produced at the end of the make output. Be sure to add this to your profile (.bashrc for example). 
```
*******************************************************************
*******************************************************************
*******************************************************************
Please add the following to your profile (.profile, .bashrc, .bash_profile, etc...).

export PYTHONPATH=/home/rpetit/call_variants:/home/rpetit/call_variants/src/third-party/python:/home/rpetit/call_variants/src/third-party/python/vcf-annotator:/home/rpetit/call_variants:/home/rpetit/call_variants/src/third-party/python:/home/rpetit/call_variants/src/third-party/python/vcf-annotator:$PYTHONPATH

*******************************************************************
*******************************************************************
*******************************************************************
```

