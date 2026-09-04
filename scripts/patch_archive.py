import json

def patch_archive():
    with open('data/archive/rea_trajectories.json', 'r') as f:
        archive = json.load(f)
        
    for record in archive:
        best_fri = -1
        for regime, outcome in record['outcomes'].items():
            if outcome['fri'] > best_fri:
                best_fri = outcome['fri']
                
        record['recoverability'] = best_fri
        
    with open('data/archive/rea_trajectories.json', 'w') as f:
        json.dump(archive, f, indent=2)
        
    print(f"✅ Patched {len(archive)} records with recoverability metric.")

if __name__ == "__main__":
    patch_archive()
