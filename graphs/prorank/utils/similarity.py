import pandas as pd
import networkx as nx
import itertools
import numpy as np

# Get the fasta sequences

def get_fasta_sequences_for_ppi(G, biogrid_ppi_dataset_path, fasta_dataset_path, ppi_fasta_sequences_path):

    # Load the full BioGRID file to create mapping
    biogrid_full = pd.read_csv(biogrid_ppi_dataset_path,sep='\t')

    # Create mapping from Systematic Name to Swiss-Prot Accession
    systematic_to_swissprot = {}

    for _, row in biogrid_full.iterrows():
        sys_name_a = row['Systematic Name Interactor A']
        swissprot_a = row['SWISS-PROT Accessions Interactor A']
        if pd.notna(sys_name_a) and pd.notna(swissprot_a):
            systematic_to_swissprot[sys_name_a] = swissprot_a
        
        sys_name_b = row['Systematic Name Interactor B']
        swissprot_b = row['SWISS-PROT Accessions Interactor B']
        if pd.notna(sys_name_b) and pd.notna(swissprot_b):
            systematic_to_swissprot[sys_name_b] = swissprot_b

    print(f"Created mapping for {len(systematic_to_swissprot)} proteins")

    # Parse FASTA file to get sequences by Swiss-Prot Accession
    swissprot_to_sequence = {}

    with open(fasta_dataset_path, 'r') as f:
        current_id = None
        current_seq = []
        
        for line in f:
            line = line.strip()
            if line.startswith('>'):
                # Save previous sequence if exists
                if current_id is not None and current_seq:
                    swissprot_to_sequence[current_id] = ''.join(current_seq)
                
                # Parse header line: >sp|Q6GZX4|001R_FRG3G ...
                parts = line.split('|')
                if len(parts) >= 2:
                    current_id = parts[1]  # Get 'Q6GZX4' part (the UniProt/Swiss-Prot ID)
                    current_seq = []
                else:
                    current_id = None
            elif current_id is not None:
                current_seq.append(line)
        
        # Save last sequence
        if current_id is not None and current_seq:
            swissprot_to_sequence[current_id] = ''.join(current_seq)

    print(f"Loaded {len(swissprot_to_sequence)} sequences from FASTA")

    # Write FASTA file with proteins from graph G
    output_fasta_path = ppi_fasta_sequences_path 
    proteins_written = 0
    proteins_not_found = 0

    with open(output_fasta_path, 'w') as f:
        for node in G.nodes():
            swissprot_id = systematic_to_swissprot.get(node)
            
            # If Swiss-Prot ID contains multiple IDs separated by |, take the first one
            if swissprot_id and '|' in swissprot_id:
                swissprot_id = swissprot_id.split('|')[0]
            
            sequence = swissprot_to_sequence.get(swissprot_id) if swissprot_id else None
            
            if sequence:
                # Write in FASTA format
                f.write(f">{swissprot_id}|{node}\n")
                # Write sequence in lines of 60 characters
                for i in range(0, len(sequence), 60):
                    f.write(sequence[i:i+60] + '\n')
                proteins_written += 1
            else:
                proteins_not_found += 1

    print(f"\nWrote {proteins_written} protein sequences to {output_fasta_path}")
    print(f"Proteins without sequences: {proteins_not_found}")



def create_similarity_graph(G, fasta_output_path):
    """Parse BLAST tabular format (-m 8CB) output"""
    blast_scores = {}
    
    with open(fasta_output_path, 'r') as f:
        for line in f:
            # Skip comment lines
            if line.startswith('#'):
                continue
            
            parts = line.strip().split('\t')
            if len(parts) < 12:
                continue
            
            # Extract relevant fields
            query_id = parts[0]      # e.g., P32605|YBR119W
            subject_id = parts[1]    # e.g., P32605|YBR119W
            bit_score = float(parts[11])  # Column 12 (0-indexed 11)
            
            # Extract systematic names from the IDs (after the |)
            query_name = query_id.split('|')[1] if '|' in query_id else query_id
            subject_name = subject_id.split('|')[1] if '|' in subject_id else subject_id
            
            # Store in nested dict
            if query_name not in blast_scores:
                blast_scores[query_name] = {}
            blast_scores[query_name][subject_name] = bit_score

    print(f"Parsed scores for {len(blast_scores)} query proteins")

    # Get list of all proteins in the graph
    all_proteins = sorted(G.nodes())
    print(f"Creating similarity matrix for {len(all_proteins)} proteins")
    

    # Create similarity matrix DataFrame initialized with zeros
    similarity_matrix = pd.DataFrame(0.0, index=all_proteins, columns=all_proteins)

    # Fill the matrix with bit scores
    filled_count = 0
    for query_protein in all_proteins:
        if query_protein in blast_scores:
            for subject_protein in all_proteins:
                if subject_protein in blast_scores[query_protein]:
                    similarity_matrix.loc[query_protein, subject_protein] = blast_scores[query_protein][subject_protein]
                    filled_count += 1

    print(f"\nFilled {filled_count} similarity scores")
    print(f"Matrix coverage: {(filled_count / (len(all_proteins) ** 2)) * 100:.2f}%")
    print(f"\nNon-zero scores: {(similarity_matrix > 0).sum().sum()}")
    print(f"Score range: {similarity_matrix[similarity_matrix > 0].min().min():.1f} to {similarity_matrix.max().max():.1f}")
    print(f"\nSample of similarity matrix:")
    print(similarity_matrix.iloc[:5, :5])


    similarity_matrix_normalized = similarity_matrix / similarity_matrix.sum(axis=0)
    similarity_matrix_normalized.head()

    # Create a directed graph from the similarity matrix
    G_similarity = nx.DiGraph()

    # Add all nodes
    G_similarity.add_nodes_from(similarity_matrix_normalized.index)

    # Add weighted edges based on similarity scores
    for source in similarity_matrix_normalized.index:
        for target in similarity_matrix_normalized.columns:
            weight = similarity_matrix_normalized.loc[source, target]
            if weight > 0:  # Only add edges with non-zero weights
                G_similarity.add_edge(source, target, weight=weight)

    print(f"Created directed graph with {len(G_similarity.nodes)} nodes and {len(G_similarity.edges)} edges")
    return G_similarity