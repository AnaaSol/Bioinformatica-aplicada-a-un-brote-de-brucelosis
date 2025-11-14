#!/usr/bin/env python3
"""
Generador de tabla consolidada de anotación genética
Compatible con BLASTp con 8 columnas (formato por defecto)
"""

import csv

# Leer BLAST (8 columnas)
blast_hits = {}
with open("blast_vs_brucella.txt") as f:
    for line in f:
        if not line.strip():
            continue
        parts = line.strip().split("\t")
        
        if len(parts) < 8:
            continue  # ignora líneas raras
        
        qseqid, sseqid, pident, length, mismatch, gapopen, evalue, bitscore = parts
        
        blast_hits[qseqid] = {
            "hit_id": sseqid,
            "pident": float(pident),
            "conserved": float(pident) == 100.0
        }

# Leer anotación de Prokka
genes = []
with open("prokka/prokka_annotation/brucella_suis.tsv") as f:
    reader = csv.DictReader(f, delimiter="\t")
    
    for row in reader:
        if row["ftype"] != "CDS":
            continue
        
        locus = row["locus_tag"]
        product = row["product"]
        
        # Clasificación por defecto
        validation = "Annotated"
        blast_info = "-"
        
        if "hypothetical" in product.lower():
            if locus in blast_hits:
                hit = blast_hits[locus]
                
                if hit["conserved"]:
                    validation = "Validated"
                    blast_info = f"Conserved in B. suis ({hit['hit_id']})"
                else:
                    validation = "Partial"
                    blast_info = f"Partial homology ({hit['pident']:.1f}%)"
            else:
                validation = "Dubious"
                blast_info = "No homologs found"
        
        genes.append({
            "Locus_Tag": locus,
            "Gene": row["gene"] if row["gene"] else "-",
            "Product": product,
            "Length_bp": row["length_bp"],
            "EC_Number": row["EC_number"] if row["EC_number"] else "-",
            "COG": row["COG"] if row["COG"] else "-",
            "Validation": validation,
            "BLAST_Refinement": blast_info
        })

# Guardar TSV consolidado
with open("gene_annotation_table.tsv", "w") as f:
    fieldnames = ["Locus_Tag", "Gene", "Product", "Length_bp", "EC_Number", "COG", "Validation", "BLAST_Refinement"]
    writer = csv.DictWriter(f, fieldnames=fieldnames, delimiter="\t")
    writer.writeheader()
    writer.writerows(genes)

print("✓ Tabla generada: gene_annotation_table.tsv")
print(f"  Total genes: {len(genes)}")

# Estadísticas
annotated = sum(1 for g in genes if "hypothetical" not in g["Product"].lower())
validated = sum(1 for g in genes if g["Validation"] == "Validated")
dubious = sum(1 for g in genes if g["Validation"] == "Dubious")

print("\nEstadísticas:")
print(f"  Con función conocida: {annotated} ({annotated/len(genes)*100:.1f}%)")
print(f"  Hipotéticas validadas por BLAST: {validated}")
print(f"  Hipotéticas dudosas: {dubious}")

