.PHONY: all test
TOP_DIR := $(shell pwd)/../
THIRD_PARTY := $(TOP_DIR)/src/third-party
THIRD_PARTY_PYTHON := $(TOP_DIR)/src/third-party/python
THIRD_PARTY_BIN := $(TOP_DIR)/bin/third-party
PYTHONPATH := $(TOP_DIR):$(THIRD_PARTY)/python:$(THIRD_PARTY)/python/vcf-annotator:$$PYTHONPATH
all: test;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Test to make sure everything is installed properly.                         #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
test: test_programs test_pipeline;

test_programs: test_input test_faidx test_create_sequence_dictionary test_bwa_index test_bwa_mem \
	           test_add_or_replace_read_groups test_mark_duplicates test_build_bam_index \
	           test_realigner_target_creator test_indel_realigner test_haplotype_caller \
	           test_variant_filtration;

test_input: ;
	mkdir -p test_programs
	cp data/test.fasta test_programs/test.fasta
	cp data/test.fastq.gz test_programs/test.fastq.gz

test_faidx: ;
	$(THIRD_PARTY_BIN)/samtools faidx test_programs/test.fasta || (echo "samtools faidx failed $$?"; exit 1)

test_create_sequence_dictionary: ;
	$(THIRD_PARTY_BIN)/java -Xmx8g -jar $(THIRD_PARTY_BIN)/picard.jar CreateSequenceDictionary \
	                        REFERENCE=test_programs/test.fasta OUTPUT=test_programs/test.dict \
	                        || (echo "picardtools CreateSequenceDictionary failed $$?"; exit 1)

test_bwa_index: ;
	$(THIRD_PARTY_BIN)/bwa index test_programs/test.fasta || (echo "bwa index failed $$?"; exit 1)

test_bwa_mem: ;
	$(THIRD_PARTY_BIN)/bwa mem -M -t 1 test_programs/test.fasta test_programs/test.fastq.gz > test_programs/test.sam || (echo "bwa mem failed $$?"; exit 1)

test_add_or_replace_read_groups: ;
	$(THIRD_PARTY_BIN)/java -Xmx8g -jar $(THIRD_PARTY_BIN)/picard.jar AddOrReplaceReadGroups \
	                        INPUT=test_programs/test.sam OUTPUT=test_programs/test_sorted.bam \
	                        SORT_ORDER=coordinate RGID=GATK RGLB=GATK RGPL=Illumina RGSM=GATK \
	                        RGPU=GATK VALIDATION_STRINGENCY=LENIENT || (echo "picardtools AddOrReplaceReadGroups failed $$?"; exit 1)

test_mark_duplicates: ;
	$(THIRD_PARTY_BIN)/java -Xmx8g -jar $(THIRD_PARTY_BIN)/picard.jar MarkDuplicates \
	                        INPUT=test_programs/test_sorted.bam OUTPUT=test_programs/test_deduped.bam \
	                        METRICS_FILE=test_programs/test_deduped.metrics ASSUME_SORTED=true \
	                        REMOVE_DUPLICATES=false VALIDATION_STRINGENCY=LENIENT || (echo "picardtools MarkDuplicates failed $$?"; exit 1)

test_build_bam_index: ;
	$(THIRD_PARTY_BIN)/java -Xmx8g -jar $(THIRD_PARTY_BIN)/picard.jar BuildBamIndex \
	                        INPUT=test_programs/test_deduped.bam || (echo "picardtools BuildBamIndex failed $$?"; exit 1)

test_realigner_target_creator: ;
	$(THIRD_PARTY_BIN)/java -Xmx8g -jar $(THIRD_PARTY_BIN)/GenomeAnalysisTK.jar \
	                        -T RealignerTargetCreator -R test_programs/test.fasta \
	                        -I test_programs/test_deduped.bam -o test_programs/test_deduped.intervals \
	                        || (echo "GATK RealignerTargetCreator failed $$?"; exit 1)

test_indel_realigner: ;
	$(THIRD_PARTY_BIN)/java -Xmx8g -jar $(THIRD_PARTY_BIN)/GenomeAnalysisTK.jar \
	                        -T IndelRealigner -R test_programs/test.fasta \
	                        -I test_programs/test_deduped.bam -o test_programs/test_realigned.bam \
	                        -targetIntervals test_programs/test_deduped.intervals \
	                        || (echo "GATK IndelRealigner failed $$?"; exit 1)

test_haplotype_caller: ;
	$(THIRD_PARTY_BIN)/java -Xmx8g -jar $(THIRD_PARTY_BIN)/GenomeAnalysisTK.jar \
	                        -T HaplotypeCaller -R test_programs/test.fasta \
	                        -I test_programs/test_realigned.bam -o test_programs/test.vcf \
	                        -ploidy 1 -stand_call_conf 30.0 -stand_emit_conf 10.0 -rf BadCigar \
	                        || (echo "GATK HaplotypeCaller failed $$?"; exit 1)

test_variant_filtration: ;
	$(THIRD_PARTY_BIN)/java -Xmx8g -jar $(THIRD_PARTY_BIN)/GenomeAnalysisTK.jar \
	                        -T VariantFiltration -R test_programs/test.fasta \
	                        -V test_programs/test.vcf -o test_programs/test_filtered.vcf \
	                        --clusterSize 3 --clusterWindowSize 10 --filterExpression "DP < 9 && AF < 0.7" \
	                        --filterName "Fail" --filterExpression "DP > 9 && AF >= 0.95" \
	                        --filterName "SuperPass" --filterExpression "GQ < 20" \
	                        --filterName "LowGQ" || (echo "GATK VariantFiltration failed $$?"; exit 1)

test_vcf_annotator: ;
	export PYTHONPATH=${PYTHONPATH}; \
	$(THIRD_PARTY_BIN)/vcf-annotator --gb data/test.gb --vcf test_programs/test_filtered.vcf \
	                                 > test_programs/test_annotated.vcf || (echo "vcf-annotator failed $$?"; exit 1)

test_pipeline: test_pipeline_input test_call_variants;

test_pipeline_input: ;
	mkdir -p test_pipeline
	cp data/test.fasta test_pipeline/test.fasta
	cp data/test.gb test_pipeline/test.gb
	cp data/test.fastq.gz test_pipeline/test.fastq.gz

test_call_variants: ;
	export PYTHONPATH=${PYTHONPATH}; \
	$(TOP_DIR)/bin/call_variants test_pipeline/test.fastq.gz test_pipeline/test.fasta \
	                             test_pipeline/test.gb -p 1 --log_times -r 100 -o test_pipeline \
	                              || (echo "call_variants failed $$?"; exit 1)
