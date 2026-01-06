import networkx as nx

def identify_bridge_proteins(G):
    to_filter = []
    for node in list(G.nodes()):
        neighbors = list(G.neighbors(node))
        
        # Skip nodes with less than 2 neighbors
        if len(neighbors) < 2:
            continue
            
        # Build subgraph of neighbors
        subgraph = G.subgraph(neighbors)
        Nn = len(neighbors)
        
        # Check if any neighbor has less than 20% connectivity
        flag_not_connected = False
        for neighbor in neighbors:
            neighbor_degree_in_subgraph = subgraph.degree(neighbor)
            connectivity_ratio = neighbor_degree_in_subgraph / Nn 
            if connectivity_ratio < 0.2:
                flag_not_connected = True
                break
        
        # If no neighbor is weakly connected, check if subgraph is connected
        if not flag_not_connected:
            if not nx.is_connected(subgraph):
                to_filter.append(node)
    
    print(f'Found: {len(to_filter)} bridge nodes ')
    return to_filter

def identify_fjord_proteins(G, fjord_threshold=0.4):
    to_filter = []
    for node in list(G.nodes()):
        neighbors = list(G.neighbors(node))
        if len(neighbors) < 2:
            continue
        subgraph = G.subgraph(neighbors)
        degrees = [deg for _, deg in subgraph.degree()]
        avg_deg = sum(degrees) / len(degrees)
        if avg_deg / (len(neighbors) - 1) < fjord_threshold:
            to_filter.append(node)
    print(f'Found: {len(to_filter)} fjord nodes ')
    return to_filter

def identify_shore_proteins(G, shore_threshold=0.12):
    to_filter = []
    for node in list(G.nodes()):
        neighbors = list(G.neighbors(node))
        if len(neighbors) < 2:
            continue
        subgraph = G.subgraph(neighbors)
        for neighbor in neighbors:
            neigh_degree = subgraph.degree(neighbor)
            if len(subgraph) > 1 and (neigh_degree / (len(neighbors) - 1)) < shore_threshold:
                to_filter.append(node)
                break
    print(f'Found: {len(to_filter)} shore nodes ')
    return to_filter
