import sys
import re

path = 'C:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/test/tiannara/os/layer6_5c_competitive_recovery_test.exs'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

func_regex = re.compile(r'defp create_discovery_records\(state, program, count, current_tick\) do\n.*?end\n    end\)\n  end', re.DOTALL)
match = func_regex.search(text)
if not match:
    print('Function not found')
    sys.exit(1)

old_func = match.group(0)

new_func = '''defp create_discovery_records(state, program_id, count, current_tick) do
    Enum.reduce(1..min(count, 5), state, fn i, acc_state ->
      program = Map.get(acc_state.research_programs, program_id)
      disc_id = "disc_#{program.id}_#{current_tick}_#{i}"
      
      if Map.has_key?(acc_state.discoveries, disc_id) do
        acc_state
      else
        new_discovery = %TiannaraOS.Discovery{
          id: disc_id,
          source_world: program.world_id,
          origin_program_id: program.id,
          origin_institution_id: program.institution_id,
          status: :validated,
          validation_level: :l2,
          evidence_score: program.metrics.conversion_rate,
          evidence_ids: Map.get(program, :evidence_ids, []) |> Enum.take(3),
          confidence: 0.8 + (:rand.uniform() * 0.2),
          metadata: %{
            created_at: current_tick,
            strategy_genome: program.strategy_genome,
            conversion_context: %{
              candidates_produced: program.metrics.candidates_produced,
              validation_method: :simulation
            }
          }
        }
        
        new_discoveries = Map.put(acc_state.discoveries, disc_id, new_discovery)
        
        final_discoveries = if length(program.discoveries) >= 100 do
          dropped_id = Enum.at(program.discoveries, 99)
          Map.delete(new_discoveries, dropped_id)
        else
          new_discoveries
        end
        
        program_discoveries = [disc_id | program.discoveries] |> Enum.take(100)
        updated_program = %ResearchProgram{program | discoveries: program_discoveries}
        new_programs = Map.put(acc_state.research_programs, program.id, updated_program)
        
        %{acc_state | discoveries: final_discoveries, research_programs: new_programs}
      end
    end)
  end'''

text = text.replace(old_func, new_func)
text = text.replace('create_discovery_records(acc_state, consumed_program, validated, current_tick)', 'create_discovery_records(acc_state, consumed_program.id, validated, current_tick)')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print('Fixed!')
