genome_fa=$1
gene_annotation_gtf=$2
cpus=8

STAR \
--runMode genomeGenerate \
--genomeDir star_reference \
--genomeFastaFiles ${genome_fa} \
--sjdbGTFfile ${gene_annotation_gtf} \
--runThreadN $cpus