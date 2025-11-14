#!/bin/bash
# Análisis estadístico de genes predichos por Glimmer3

PREDICT_FILE="brucella.predict"
FASTA_FILE="predicted_genes.fasta"

echo "=== Estadísticas de Genes Predichos por Glimmer3 ==="
echo ""

# Contar genes
NUM_GENES=$(tail -n +2 $PREDICT_FILE | wc -l)
echo "Total de genes predichos: $NUM_GENES"

# Genes por strand
PLUS_STRAND=$(tail -n +2 $PREDICT_FILE | awk '{if ($4 ~ /^\+/) print}' | wc -l)
MINUS_STRAND=$(tail -n +2 $PREDICT_FILE | awk '{if ($4 ~ /^-/) print}' | wc -l)
echo "Genes en strand +: $PLUS_STRAND"
echo "Genes en strand -: $MINUS_STRAND"

# Calcular tamaños
echo ""
echo "=== Longitud de genes ==="
awk 'NR>1 {
    start = $2;
    end = $3;
    len = (start > end) ? start - end + 1 : end - start + 1;
    sum += len;
    if (len > max) max = len;
    if (min == 0 || len < min) min = len;
    print len
}' $PREDICT_FILE > /tmp/gene_lengths.txt

MIN=$(sort -n /tmp/gene_lengths.txt | head -1)
MAX=$(sort -n /tmp/gene_lengths.txt | tail -1)
AVG=$(awk '{sum+=$1} END {printf "%.0f", sum/NR}' /tmp/gene_lengths.txt)
MEDIAN=$(sort -n /tmp/gene_lengths.txt | awk '{a[NR]=$1} END {print (NR%2==1)?a[(NR+1)/2]:(a[NR/2]+a[NR/2+1])/2}')

echo "Longitud mínima: $MIN bp"
echo "Longitud máxima: $MAX bp"
echo "Longitud promedio: $AVG bp"
echo "Longitud mediana: $MEDIAN bp"

# Cobertura genómica
TOTAL_CODING=$(awk '{sum+=$1} END {print sum}' /tmp/gene_lengths.txt)
GENOME_SIZE=30000
COVERAGE=$(echo "scale=2; $TOTAL_CODING * 100 / $GENOME_SIZE" | bc)
echo ""
echo "=== Cobertura genómica ==="
echo "Total de bases codificantes: $TOTAL_CODING bp"
echo "Tamaño del genoma: $GENOME_SIZE bp"
echo "Cobertura: $COVERAGE%"

# Distribución por frames
echo ""
echo "=== Distribución por frames ==="
awk 'NR>1 {print $4}' $PREDICT_FILE | sort | uniq -c | sort -rn

# Scores
echo ""
echo "=== Scores de predicción ==="
awk 'NR>1 {
    score = $5;
    sum += score;
    if (score > max) max = score;
    if (min == 0 || score < min) min = score;
}
END {
    printf "Score mínimo: %.2f\n", min;
    printf "Score máximo: %.2f\n", max;
    printf "Score promedio: %.2f\n", sum/(NR-1);
}' $PREDICT_FILE

# Densidad génica
DENSITY=$(echo "scale=2; $NUM_GENES / ($GENOME_SIZE / 1000)" | bc)
echo ""
echo "=== Densidad génica ==="
echo "Densidad: $DENSITY genes/kb"
echo "(Esperado para bacterias: ~1 gen/kb)"

rm -f /tmp/gene_lengths.txt
