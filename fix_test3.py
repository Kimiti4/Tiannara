import sys

path = 'C:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/test/tiannara/os/layer6_5c_competitive_recovery_test.exs'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_code = '''        updated_program = update_program_metrics(consumed_program, candidates, validated)
        
        new_programs = Map.put(acc_state.research_programs, updated_program.id, updated_program)
        %{acc_state | research_programs: new_programs}'''

new_code = '''        latest_program = Map.get(acc_state.research_programs, program.id, consumed_program)
        updated_program = update_program_metrics(latest_program, candidates, validated)
        
        new_programs = Map.put(acc_state.research_programs, updated_program.id, updated_program)
        %{acc_state | research_programs: new_programs}'''

text = text.replace(old_code, new_code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print('Fixed!')
