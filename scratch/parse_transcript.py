import json

def main():
    transcript_path = 'C:/Users/user/.gemini/antigravity-ide/brain/7336b2bf-c449-4ba4-b443-1ee8f4823b64/.system_generated/logs/transcript.jsonl'
    
    import os
    if not os.path.exists(transcript_path):
        print(f"Log not found at {transcript_path}")
        return
        
    print("Parsing transcript...")
    user_inputs = []
    with open(transcript_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                data = json.loads(line)
                if data.get('type') == 'USER_INPUT':
                    user_inputs.append(data.get('content'))
            except Exception as e:
                pass
                
    print(f"Found {len(user_inputs)} user inputs in history:")
    for i, ui in enumerate(user_inputs):
        safe_ui = ui.strip().encode('ascii', 'ignore').decode('ascii')
        print(f"{i+1}: {safe_ui[:300]}")

if __name__ == '__main__':
    main()
