# Load CYC2008 reference complexes
def load_reference_complexes(file_path):
    reference_complexes = {}
    current_complex = []
    complex_counter = 1
    
    with open(file_path, 'r') as f:
        # Skip header line
        next(f)
        
        for line in f:
            line = line.strip()
            
            # Blank line indicates end of a complex block
            if not line:
                if current_complex:
                    reference_complexes[complex_counter] = current_complex
                    current_complex = []
                    complex_counter += 1
                continue
            
            # Extract only the first column (protein ID)
            protein_id = line.split('\t')[0].strip()
            current_complex.append(protein_id)
        
        # Don't forget the last complex if file doesn't end with blank line
        if current_complex:
            reference_complexes[complex_counter] = current_complex
    
    return reference_complexes


def jaccard_index(set_K, set_P):
    """
    Calculate Jaccard index (accuracy) between two protein sets.
    
    Acc(K, P) = |K ∩ P| / |K ∪ P|
    
    Parameters:
    - set_K: set of proteins in known complex
    - set_P: set of proteins in predicted complex
    
    Returns:
    - float: Jaccard index between 0 and 1
    """
    intersection = len(set_K & set_P)
    union = len(set_K | set_P)
    
    if union == 0:
        return 0.0
    
    return intersection / union


def evaluate_complexes(reference_complexes, predicted_complexes, match_threshold=0.5):
    """
    Evaluate predicted complexes against reference complexes using Jaccard index.
    
    A predicted complex P matches a known complex K if Acc(K, P) >= match_threshold.
    
    Parameters:
    - reference_complexes: dict of complex_id -> list of proteins
    - predicted_complexes: dict of complex_id -> list of proteins
    - match_threshold: minimum Jaccard index for a match (default 0.5)
    
    Returns:
    - dict with evaluation metrics
    """
    # Convert both dictionaries to lists of sets for comparison
    ref_keys = list(reference_complexes.keys())
    pred_keys = list(predicted_complexes.keys())
    
    ref_sets = [set(reference_complexes[k]) for k in ref_keys]
    pred_sets = [set(predicted_complexes[k]) for k in pred_keys]
    
    # Track matches
    matched_reference = set()
    matched_predicted = set()
    best_matches = []  # Store (ref_key, pred_key, jaccard_score)
    
    # For each predicted complex, find best matching reference complex
    for pred_idx, pred_complex in enumerate(pred_sets):
        best_score = 0
        best_ref_idx = None
        
        for ref_idx, ref_complex in enumerate(ref_sets):
            score = jaccard_index(ref_complex, pred_complex)
            
            if score > best_score:
                best_score = score
                best_ref_idx = ref_idx
        
        # If best score meets threshold, it's a match
        if best_score >= match_threshold:
            matched_predicted.add(pred_idx)
            matched_reference.add(best_ref_idx)
            best_matches.append((ref_keys[best_ref_idx], pred_keys[pred_idx], best_score))
    
    # Calculate metrics
    num_reference = len(ref_sets)
    num_predicted = len(pred_sets)
    num_matched_ref = len(matched_reference)
    num_matched_pred = len(matched_predicted)
    
    # Sensitivity (recall): fraction of reference complexes that are matched
    sensitivity = num_matched_ref / num_reference if num_reference > 0 else 0
    
    # Positive Predictive Value (precision): fraction of predicted complexes that match
    ppv = num_matched_pred / num_predicted if num_predicted > 0 else 0
    
    # F1 score (harmonic mean of precision and recall)
    f1_score = 2 * (ppv * sensitivity) / (ppv + sensitivity) if (ppv + sensitivity) > 0 else 0
    
    results = {
        'num_reference_complexes': num_reference,
        'num_predicted_complexes': num_predicted,
        'num_matched_reference': num_matched_ref,
        'num_matched_predicted': num_matched_pred,
        'sensitivity': sensitivity,
        'ppv': ppv,
        'f1_score': f1_score,
        'best_matches': best_matches
    }
    
    return results


