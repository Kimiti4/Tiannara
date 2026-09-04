import json, sys
sys.path.append('scripts')

with open('data/archive/rea_generator_search.json') as f:
    g = json.load(f)

# Show temporal evolution of CA for each archetype
print('CA temporal profile by archetype:')
archetypes = ['Trader', 'Settler', 'Survivor', 'Explorer', 'Phoenix']
for arch in archetypes:
    entries = sorted([e for e in g if e['archetype'] == arch], key=lambda x: x['epoch'])
    print(f'\n  {arch}:')
    for e in entries:
        star = ' *** GENERATOR ***' if e['region'] == 'GENERATOR' else ''
        print(f"    ep={e['epoch']:>3}  CA={e['ca']:>8.3f}  PE={e['pe']}  "
              f"PR={e['pr']:>7.3f}  region={e['region']:<10}{star}")

print()
# Find the epoch at which Trader first goes above CA=5 (Generator threshold)
trader = sorted([e for e in g if e['archetype'] == 'Trader'], key=lambda x: x['epoch'])
first_gen = next((e for e in trader if e['ca'] >= 5 and e['pe'] >= 4 and e['pr'] >= 0), None)
print(f'Trader first Generator epoch: {first_gen["epoch"] if first_gen else "never"}')
print()

# Show OI values for a non-zero CA entry to understand what's different
nonzero = [e for e in g if e['ca'] > 10 and e['archetype'] == 'Trader']
if nonzero:
    e = nonzero[0]
    print(f'Trader CA={e["ca"]:.2f} at epoch {e["epoch"]}:')
    print(f'  OI outcomes: {e["oi_outcomes"]}')
    print(f'  best_oi={e["best_oi"]:.4f}')
