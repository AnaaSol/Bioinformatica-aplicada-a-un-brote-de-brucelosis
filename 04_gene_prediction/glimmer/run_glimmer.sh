#!/bin/bash
# Script para predicción de genes con Glimmer3 en Brucella suis
# Basado en Practica8_2024.pdf

# Variables
GLIMMER_BIN="/usr/lib/tigr-glimmer"
REFERENCE="/home/ana/Desktop/Brucelosis_TP_Integrador/ncbi_dataset/ncbi_dataset/data/GCF_000007505.1/GCF_000007505.1_ASM750v1_genomic.fna"
GENOME="/home/ana/Desktop/Brucelosis_TP_Integrador/03_assembly/hybrid_assembly/scaffolds.fasta"
OUTPUT_DIR="/home/ana/Desktop/Brucelosis_TP_Integrador/04_gene_prediction/glimmer"

cd $OUTPUT_DIR

echo "=== Paso 1: Entrenar modelo con genoma de referencia de B. suis 1330 ==="
echo "Genoma de referencia: Brucella suis 1330 (3.3 MB, 2 cromosomas)"
echo ""

# Extraer genes largos del genoma de referencia para entrenamiento
echo "Extrayendo ORFs largos del genoma de referencia..."
${GLIMMER_BIN}/long-orfs -n -t 1.15 $REFERENCE training.longorfs

# Extraer secuencias de los genes largos
echo "Extrayendo secuencias de entrenamiento..."
${GLIMMER_BIN}/extract $REFERENCE training.longorfs > training.train

# Construir el modelo ICM (Interpolated Context Model)
echo "Construyendo modelo ICM..."
${GLIMMER_BIN}/build-icm -r training.icm < training.train

echo ""
echo "=== Paso 2: Predecir genes en tu scaffold ensamblado ==="
echo "Scaffold: $(basename $GENOME) (30 kb)"
echo ""

# Usar el modelo entrenado para predecir genes en tu ensamblado
# Parámetros:
# -o50: overlap máximo de 50 bp entre genes
# -g110: longitud mínima de gen 110 bp
# -t30: threshold de score 30
${GLIMMER_BIN}/glimmer3 -o50 -g110 -t30 $GENOME training.icm brucella

echo ""
echo "=== Paso 3: Análisis de resultados ==="

# Contar genes predichos
NUM_GENES=$(tail -n +2 brucella.predict | wc -l)
echo "Número de genes predichos: $NUM_GENES"

# Extraer secuencias de los genes predichos
echo ""
echo "Extrayendo secuencias de genes predichos..."
${GLIMMER_BIN}/extract -t $GENOME brucella.predict > predicted_genes.fasta

# Contar secuencias extraídas
NUM_SEQS=$(grep -c "^>" predicted_genes.fasta)
echo "Secuencias extraídas: $NUM_SEQS"

echo ""
echo "=== Archivos generados ==="
echo "- training.icm: Modelo entrenado con B. suis 1330"
echo "- brucella.predict: Coordenadas de genes predichos"
echo "- brucella.detail: Detalles de scores y frames"
echo "- predicted_genes.fasta: Secuencias nucleotídicas de genes predichos"

echo ""
echo "=== Estadísticas del modelo ==="
wc -l training.longorfs | awk '{print "ORFs de entrenamiento: " $1}'
wc -c training.train | awk '{print "Secuencias de entrenamiento: " $1 " bytes"}'
