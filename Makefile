.PHONY: all clean
TOP_DIR := $(shell pwd)
THIRD_PARTY := $(TOP_DIR)/src/third-party
THIRD_PARTY_PYTHON := $(TOP_DIR)/src/third-party/python
THIRD_PARTY_BIN := $(TOP_DIR)/bin/third-party

all: mkdirs programs python;

mkdirs: ;
	mkdir -p $(THIRD_PARTY)
	mkdir -p $(THIRD_PARTY_BIN)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Clean up everything.                                                        #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
clean: ;
	rm -rf $(THIRD_PARTY)
	rm -rf $(THIRD_PARTY_BIN)
	sed -i 's#^BASE_DIR.*#BASE_DIR = "***CHANGE_ME***"#' call_variants/config.py

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Build all the programs required to run the simulations.                     #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
programs: mkdirs bwa java picardtools gatk vcfannotator;

bwa: ;
	wget -O $(THIRD_PARTY)/bwa-0.7.12.tar.gz https://github.com/lh3/bwa/archive/0.7.12.tar.gz
	tar -C $(THIRD_PARTY) -xzvf $(THIRD_PARTY)/bwa-0.7.12.tar.gz && mv $(THIRD_PARTY)/bwa-0.7.12 $(THIRD_PARTY)/bwa
	make -C $(THIRD_PARTY)/bwa
	ln -s $(THIRD_PARTY)/bwa/bwa $(THIRD_PARTY_BIN)/bwa

java: ;
	wget -O $(THIRD_PARTY)/jdk-8u60-linux-x64.tar.gz https://www.dropbox.com/s/g5y2o8x6ce685ud/jdk-8u60-linux-x64.tar.gz?dl=1
	tar -C $(THIRD_PARTY) -xzvf $(THIRD_PARTY)/jdk-8u60-linux-x64.tar.gz && mv $(THIRD_PARTY)/jdk1.8.0_60 $(THIRD_PARTY)/jdk
	ln -s $(THIRD_PARTY)/jdk/bin/java $(THIRD_PARTY_BIN)/java

picardtools: ;
	wget -P $(THIRD_PARTY) https://github.com/broadinstitute/picard/releases/download/1.140/picard-tools-1.140.zip
	unzip $(THIRD_PARTY)/picard-tools-1.140.zip -d $(THIRD_PARTY)/ && mv $(THIRD_PARTY)/picard-tools-1.140 $(THIRD_PARTY)/picardtools
	ln -s $(THIRD_PARTY)/picardtools/picard.jar $(THIRD_PARTY_BIN)/picard.jar

gatk: ;
	mkdir $(THIRD_PARTY)/gatk
	wget -O $(THIRD_PARTY)/gatk/GenomeAnalysisTK-3.4-46.tar.bz2 https://www.dropbox.com/s/97qv9ybrr3kjgzk/GenomeAnalysisTK-3.4-46.tar.bz2?dl=1
	tar -C $(THIRD_PARTY)/gatk/ -xjvf $(THIRD_PARTY)/gatk/GenomeAnalysisTK-3.4-46.tar.bz2
	ln -s $(THIRD_PARTY)/gatk/GenomeAnalysisTK.jar $(THIRD_PARTY_BIN)/GenomeAnalysisTK.jar

vcfannotator: ;
	git clone git@github.com:rpetit3/vcf-annotator.git $(THIRD_PARTY)/python/vcf-annotator
	ln -s $(THIRD_PARTY)/python/vcf-annotator/bin/vcf-annotator $(THIRD_PARTY_BIN)/vcf-annotator

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Install necessary python modules.                                           #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
python: ;
	mkdir -p $(THIRD_PARTY)/python
	export PYTHONPATH=$(TOP_DIR):$(THIRD_PARTY)/python:$(THIRD_PARTY)/python/vcf-annotator:$$PYTHONPATH
	pip install --target $(THIRD_PARTY)/python --install-option="--prefix=" -r $(TOP_DIR)/requirements.txt
	echo 'Please add the following to your PYTHONPATH.'
	echo "export PYTHONPATH=$(TOP_DIR):$(THIRD_PARTY)/python:$(THIRD_PARTY)/python/vcf-annotator:$$PYTHONPATH"