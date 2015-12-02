.PHONY: all clean test
TOP_DIR := $(shell pwd)
THIRD_PARTY := $(TOP_DIR)/src/third-party
THIRD_PARTY_PYTHON := $(TOP_DIR)/src/third-party/python
THIRD_PARTY_BIN := $(TOP_DIR)/bin/third-party
PYTHONPATH := $(TOP_DIR):$(THIRD_PARTY)/python:$(THIRD_PARTY)/python/vcf-annotator:$$PYTHONPATH
all: mkdirs config programs python add_to_profile;

mkdirs: ;
	mkdir -p $(THIRD_PARTY)
	mkdir -p $(THIRD_PARTY_BIN)

config: ;
	sed -i 's#^BASE_DIR.*#BASE_DIR = "$(TOP_DIR)"#' call_variants/config.py

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Clean up everything.                                                        #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
clean: ;
	rm -rf $(THIRD_PARTY)
	rm -rf $(THIRD_PARTY_BIN)
	rm -rf test/test_programs
	rm -rf test/test_pipeline
	sed -i 's#^BASE_DIR.*#BASE_DIR = CHANGE_ME"#' call_variants/config.py

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Build all the programs required to run the simulations.                     #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
programs: mkdirs bwa java picardtools gatk vcfannotator samtools;

bwa: ;
	wget -O $(THIRD_PARTY)/bwa-0.7.12.tar.gz https://github.com/lh3/bwa/archive/0.7.12.tar.gz
	tar -C $(THIRD_PARTY) -xzvf $(THIRD_PARTY)/bwa-0.7.12.tar.gz && mv $(THIRD_PARTY)/bwa-0.7.12 $(THIRD_PARTY)/bwa
	make -C $(THIRD_PARTY)/bwa
	ln -s $(THIRD_PARTY)/bwa/bwa $(THIRD_PARTY_BIN)/bwa

java: ;
	wget -O $(THIRD_PARTY)/jdk-7u79-linux-x64.tar.gz --no-cookies --no-check-certificate --header \
	     "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F;oraclelicense=accept-securebackup-cookie" \
	     "http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gz"
	tar -C $(THIRD_PARTY) -xzvf $(THIRD_PARTY)/jdk-7u79-linux-x64.tar.gz && mv $(THIRD_PARTY)/jdk1.7.0_79 $(THIRD_PARTY)/jdk
	ln -s $(THIRD_PARTY)/jdk/bin/java $(THIRD_PARTY_BIN)/java

picardtools: ;
	wget -P $(THIRD_PARTY) https://github.com/broadinstitute/picard/releases/download/1.140/picard-tools-1.140.zip
	unzip $(THIRD_PARTY)/picard-tools-1.140.zip -d $(THIRD_PARTY)/ && mv $(THIRD_PARTY)/picard-tools-1.140 $(THIRD_PARTY)/picardtools
	ln -s $(THIRD_PARTY)/picardtools/picard.jar $(THIRD_PARTY_BIN)/picard.jar

gatk: ;
	wget -O $(THIRD_PARTY)/apache-maven-3.3.3-bin.tar.gz http://mirror.cc.columbia.edu/pub/software/apache/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz
	tar -C $(THIRD_PARTY) -xzvf $(THIRD_PARTY)/apache-maven-3.3.3-bin.tar.gz
	wget -O $(THIRD_PARTY)/gatk-3.5.tar.gz https://github.com/broadgsa/gatk/archive/3.5.tar.gz
	tar -C $(THIRD_PARTY) -xzvf $(THIRD_PARTY)/gatk-3.4.tar.gz
	export JAVA_HOME=$(THIRD_PARTY)/jdk; \
	$(THIRD_PARTY)/apache-maven-3.3.3/bin/mvn -f $(THIRD_PARTY)/gatk-protected-3.4/pom.xml verify -P\!queue
	ln -s $(THIRD_PARTY)/gatk-protected-3.4/target/GenomeAnalysisTK.jar $(THIRD_PARTY_BIN)/GenomeAnalysisTK.jar

vcfannotator: ;
	git clone https://github.com/rpetit3-science/vcf-annotator.git $(THIRD_PARTY)/python/vcf-annotator
	ln -s $(THIRD_PARTY)/python/vcf-annotator/bin/vcf-annotator $(THIRD_PARTY_BIN)/vcf-annotator

samtools: ;
	wget -P $(THIRD_PARTY) https://github.com/samtools/samtools/releases/download/1.2/samtools-1.2.tar.bz2
	tar -C $(THIRD_PARTY) -xjvf $(THIRD_PARTY)/samtools-1.2.tar.bz2 && mv $(THIRD_PARTY)/samtools-1.2 $(THIRD_PARTY)/samtools
	make -C $(THIRD_PARTY)/samtools
	ln -s $(THIRD_PARTY)/samtools/samtools $(THIRD_PARTY_BIN)/samtools

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Install necessary python modules.                                           #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
python: ;
	mkdir -p $(THIRD_PARTY)/python
	pip install --target $(THIRD_PARTY)/python --install-option="--prefix=" -r $(TOP_DIR)/requirements.txt

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Test to make sure everything is installed properly.                         #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
test: test_make add_to_profile;

test_make: ;
	make -C test

add_to_profile: ;
	@echo '*******************************************************************'
	@echo '*******************************************************************'
	@echo '*******************************************************************'
	@echo 'Please add the following to your profile (.profile, .bashrc, .bash_profile, etc...).'
	@echo ''
	@echo export PYTHONPATH=${PYTHONPATH};
	@echo ''
	@echo '*******************************************************************'
	@echo '*******************************************************************'
	@echo '*******************************************************************'
