def find_complexes(G, pagerank_scores, bridge_proteins):

    from collections import defaultdict
    
    # Sort proteins by PageRank score (highest first)
    sorted_proteins = sorted(pagerank_scores.items(), key=lambda x: x[1], reverse=True)
    
    # Greedy complex assignment
    complexes = defaultdict(list)
    protein_to_complex = {}
    used_proteins = set()
    complex_id = 0
    
    for protein, rank_score in sorted_proteins:
        # Skip if already assigned to a complex
        if protein in used_proteins:
            continue
        
        # Skip bridge proteins (they connect different network components)
        if protein in bridge_proteins:
            continue
        
        # Create a new complex with this protein as the core
        complex_id += 1
        complexes[complex_id].append(protein)
        protein_to_complex[protein] = complex_id
        used_proteins.add(protein)
        
        # Add all direct neighbors to this complex
        for neighbor in G.neighbors(protein):
            # Skip neighbors already assigned to another complex
            if neighbor in used_proteins:
                continue
            
            complexes[complex_id].append(neighbor)
            protein_to_complex[neighbor] = complex_id
            used_proteins.add(neighbor)
    
    print(f"Detected {len(complexes)} complexes from {len(used_proteins)} proteins")
    print(f"Excluded {len(bridge_proteins)} bridge proteins")
    
    # return dict(complexes), protein_to_complex
    return dict(complexes)

def merge_similar_complexes(complexes, similarity_threshold=0.5):
    """
    Merge complexes that share more than similarity_threshold of their proteins.
    
    Parameters:
    - complexes: dict of complex_id -> list of protein_ids
    - similarity_threshold: float, merge if overlap > this fraction (default 0.5 = 50%)
    
    Returns:
    - merged_complexes: dict of new_complex_id -> list of protein_ids
    """
    
    # Convert to sets for easier comparison
    complex_sets = {cid: set(proteins) for cid, proteins in complexes.items()}
    complex_ids = list(complex_sets.keys())
    
    # Track which complexes have been merged
    merged_into = {}  # maps complex_id -> final_complex_id
    
    # Compare all pairs of complexes
    for i in range(len(complex_ids)):
        cid1 = complex_ids[i]
        
        # Skip if already merged
        if cid1 in merged_into:
            continue
            
        for j in range(i + 1, len(complex_ids)):
            cid2 = complex_ids[j]
            
            # Skip if already merged
            if cid2 in merged_into:
                continue
            
            set1 = complex_sets[cid1]
            set2 = complex_sets[cid2]
            
            # Calculate overlap as fraction of smaller complex
            overlap = len(set1 & set2)
            min_size = min(len(set1), len(set2))
            
            if min_size > 0:
                similarity = overlap / min_size
                
                # Merge if similarity exceeds threshold
                if similarity > similarity_threshold:
                    # Merge cid2 into cid1
                    complex_sets[cid1] = set1 | set2
                    merged_into[cid2] = cid1
    
    # Build final complexes
    merged_complexes = {}
    new_id = 1
    
    for cid in complex_ids:
        # Skip if this was merged into another
        if cid in merged_into:
            continue
        
        merged_complexes[new_id] = sorted(list(complex_sets[cid]))
        new_id += 1
    
    print(f"Merged {len(complexes)} complexes into {len(merged_complexes)} complexes")
    print(f"Merged {len(merged_into)} complexes")
    
    return merged_complexes

