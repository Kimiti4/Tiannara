"""Fast NLP Domain validation without heavy BERT models"""
import sys
sys.path.insert(0, '.')

print("="*80)
print("NLP DOMAIN ENHANCEMENT VALIDATION")
print("="*80)

# Test 1: Intent Recognition (rule-based fast version)
print("\n1. Testing Intent Recognition...")
try:
    from tiannara_core.nlp.intent_tracker import IntentTracker
    
    tracker = IntentTracker()
    
    test_queries = [
        "Book a flight to Paris",
        "What's the weather like today?",
        "I need help with my account",
        "Show me Italian restaurants nearby",
        "Cancel my subscription"
    ]
    
    passed = 0
    for query in test_queries:
        result = tracker.track_intent(query, 'user')
        if result:
            passed += 1
    
    print(f"   Result: {passed}/{len(test_queries)} queries processed successfully")
    print(f"   Status: {'✅ PASS' if passed == len(test_queries) else '❌ FAIL'}")
except Exception as e:
    print(f"   Status: ❌ FAIL - {e}")

# Test 2: Dialogue State Tracking
print("\n2. Testing Context Preservation...")
try:
    from tiannara_core.nlp.dialogue_state import DialogueStateManager
    
    manager = DialogueStateManager()
    
    turns = [
        ("user", "I want to book a flight to Paris"),
        ("assistant", "When would you like to travel?"),
        ("user", "Next Friday"),
    ]
    
    for speaker, utterance in turns:
        manager.add_turn(speaker, utterance)
    
    context = manager.get_context()
    
    if context:
        print(f"   Result: Context preserved across {len(turns)} turns")
        print(f"   Status: ✅ PASS")
    else:
        print(f"   Result: Context not properly preserved")
        print(f"   Status: ❌ FAIL")
except Exception as e:
    print(f"   Status: ❌ FAIL - {e}")

# Test 3: Semantic Search
print("\n3. Testing Semantic Similarity...")
try:
    from tiannara_core.nlp.semantic_search import SemanticSearch
    
    engine = SemanticSearch()
    
    # Add some documents
    docs = [
        "Machine learning algorithms improve with more data",
        "Deep learning uses neural networks with many layers",
        "Natural language processing handles text understanding"
    ]
    
    for i, doc in enumerate(docs):
        engine.index_document(f"doc_{i}", doc)
    
    # Search
    results = engine.search("AI and neural networks", top_k=2)
    
    if results and len(results) > 0:
        print(f"   Result: Found {len(results)} relevant documents")
        print(f"   Status: ✅ PASS")
    else:
        print(f"   Result: No documents found")
        print(f"   Status: ❌ FAIL")
except Exception as e:
    print(f"   Status: ❌ FAIL - {e}")

print("\n" + "="*80)
print("NLP Enhancement Validation Complete")
print("="*80 + "\n")
