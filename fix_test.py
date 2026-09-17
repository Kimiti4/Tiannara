import sys

path = 'C:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/test/tiannara/os/layer6_5c_competitive_recovery_test.exs'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Fix the missing top 10 logic
fix = '''
    # Discovery Half-life
    avg_half_life = if evolution_data.imported_ages_count > 0 do
      evolution_data.imported_ages_sum / evolution_data.imported_ages_count
    else
      0.0
    end
    IO.puts("Discovery Half-life:")
    IO.puts("  Average migration age: #{Float.round(avg_half_life, 1)} ticks\\n")
    
    active_sorted_by_val = Enum.sort_by(active_programs, & &1.metrics.candidates_validated, :desc)
    top_10_count = max(1, trunc(length(active_sorted_by_val) * 0.1))
    top_10_programs = Enum.take(active_sorted_by_val, top_10_count)
    
    top_10_validated = Enum.sum(Enum.map(top_10_programs, & &1.metrics.candidates_validated))
'''

# Find the spot to insert
text = text.replace('    total_val = max(1, total_validated)\n    knowledge_concentration = top_10_validated / total_val', fix + '    total_val = max(1, total_validated)\n    knowledge_concentration = top_10_validated / total_val')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print('Done!')
