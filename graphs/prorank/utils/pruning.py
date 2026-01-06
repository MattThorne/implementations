import networkx as nx

def adjustcd_iterative(G, threshold=0.15, max_iter=100):
    nodes = list(G.nodes())
    weights = {}
    
    # Initialize weights for ALL node pairs
    for u, v in  list(G.edges()):
        w0 = 1.0
        weights[frozenset((u, v))] = w0

    for iteration in range(max_iter):
        new_weights = {}
        
        # Calculate average weight
        total = 0
        for node in nodes:
            for neighbour in G.neighbors(node):
                total += weights.get(frozenset((node, neighbour)))
        avg_w = total / len(nodes)

        for edge_key in weights.keys():
            u, v = tuple(edge_key)
            Nu = set(G.neighbors(u))
            Nv = set(G.neighbors(v))
            common_neighbors = Nu & Nv
    
            numerator = sum(
                weights.get(frozenset((x, u)),0) + weights.get(frozenset((x, v)),0)
                for x in common_neighbors
            )

            denom_u = sum(weights.get(frozenset((x, u))) for x in Nu)
            denom_v = sum(weights.get(frozenset((x, v))) for x in Nv)

            denom = max(denom_u, avg_w) + max(denom_v, avg_w)
            # denom = denom_u + denom_v
            
            if denom > 0:
                new_score = numerator / denom
            else:
                new_score = 0
                
            new_weights[edge_key] = new_score

        weights = new_weights

    # # Remove edges below threshold
    edges_to_remove = [tuple(e) for e, w in weights.items() if w < threshold]
    G.remove_edges_from(edges_to_remove)

    isolated = list(nx.isolates(G))
    G.remove_nodes_from(isolated)
    # G.clear_edges()
    # G.add_edges_from([tuple(e) for e, w in weights.items() if w >= threshold])

    # # Step 5: Remove isolated nodes
    # G.remove_nodes_from(list(nx.isolates(G)))