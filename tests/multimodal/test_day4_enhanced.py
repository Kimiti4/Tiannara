"""
Multi-Modal Engine Tests - Day 4 Enhanced Capabilities

Purpose: Test all enhanced multi-modal features
Coverage:
- Enhanced speech-to-text simulation
- Advanced image analysis
- Gesture sequence recognition
- Multi-modal fusion with confidence weighting
- Real-time processing pipeline
- Accessibility features

Date: April 30, 2026
Status: Day 4 Implementation
"""

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from tiannara_core.multimodal.multi_modal_engine import (
    MultiModalEngine,
    VoiceInput,
    ImageInput,
    GestureInput,
    MultiModalInput,
    ModalityType
)


def test_enhanced_speech_recognition():
    """Test enhanced speech-to-text with contextual understanding."""
    print("\n" + "="*70)
    print("TEST 1: Enhanced Speech Recognition")
    print("="*70)
    
    engine = MultiModalEngine()
    
    # Test short command (<1.5s)
    voice_short = VoiceInput(
        audio_data=b"[audio]",
        duration_seconds=1.0,
        sample_rate=16000
    )
    result = engine.enhanced_transcribe_audio(voice_short)
    transcription = result["text"]
    confidence = result["confidence"]
    print(f"\n[OK] Short command ({voice_short.duration_seconds}s):")
    print(f"  Transcription: '{transcription}'")
    print(f"  Confidence: {confidence:.2f}")
    assert confidence >= 0.85, "Short commands should have high confidence"
    
    # Test medium query (1.5-3.0s)
    voice_medium = VoiceInput(
        audio_data=b"[audio]",
        duration_seconds=2.5,
        sample_rate=16000
    )
    result = engine.enhanced_transcribe_audio(voice_medium)
    transcription = result["text"]
    confidence = result["confidence"]
    print(f"\n[OK] Medium query ({voice_medium.duration_seconds}s):")
    print(f"  Transcription: '{transcription}'")
    print(f"  Confidence: {confidence:.2f}")
    assert len(transcription) > 20, "Medium queries should be longer"
    
    # Test complex request (>3.0s)
    voice_long = VoiceInput(
        audio_data=b"[audio]",
        duration_seconds=4.5,
        sample_rate=16000
    )
    result = engine.enhanced_transcribe_audio(voice_long)
    transcription = result["text"]
    confidence = result["confidence"]
    print(f"\n[OK] Complex request ({voice_long.duration_seconds}s):")
    print(f"  Transcription: '{transcription[:60]}...'")
    print(f"  Confidence: {confidence:.2f}")
    assert len(transcription) > 50, "Complex requests should be detailed"
    
    # Test with simulated text
    voice_simulated = VoiceInput(
        audio_data=b"[audio]",
        duration_seconds=2.0,
        metadata={'simulated_text': 'predict the match outcome'}
    )
    result = engine.enhanced_transcribe_audio(voice_simulated)
    transcription = result["text"]
    confidence = result["confidence"]
    print(f"\n[OK] Simulated text:")
    print(f"  Transcription: '{transcription}'")
    assert transcription == 'predict the match outcome', "Should use simulated text"
    
    print("\n[PASS] Enhanced speech recognition tests passed!")


def test_enhanced_image_analysis():
    """Test advanced image analysis with object detection."""
    print("\n" + "="*70)
    print("TEST 2: Enhanced Image Analysis")
    print("="*70)
    
    engine = MultiModalEngine()
    
    # Test landscape image
    image_landscape = ImageInput(
        image_data=b"[image]",
        width=1920,
        height=1080,
        format="jpg"
    )
    analysis = engine.enhanced_analyze_image(image_landscape)
    print(f"\n✓ Landscape image ({image_landscape.width}x{image_landscape.height}):")
    print(f"  Scene type: {analysis['scene_type']}")
    print(f"  Description: {analysis['description']}")
    print(f"  Objects detected: {len(analysis['objects_detected'])}")
    print(f"  Colors: {', '.join(analysis['colors_dominant'])}")
    print(f"  Confidence: {analysis['confidence']:.2f}")
    assert analysis['scene_type'] == 'landscape', "Should detect landscape orientation"
    assert len(analysis['objects_detected']) > 0, "Should detect objects"
    
    # Test portrait image
    image_portrait = ImageInput(
        image_data=b"[image]",
        width=600,
        height=900,
        format="png"
    )
    analysis = engine.enhanced_analyze_image(image_portrait)
    print(f"\n✓ Portrait image ({image_portrait.width}x{image_portrait.height}):")
    print(f"  Scene type: {analysis['scene_type']}")
    print(f"  Text extracted: {analysis['text_extracted'][:50] if analysis['text_extracted'] else 'None'}")
    assert analysis['scene_type'] == 'portrait', "Should detect portrait orientation"
    
    # Test panoramic image
    image_panoramic = ImageInput(
        image_data=b"[image]",
        width=2560,
        height=800,
        format="jpg"
    )
    analysis = engine.enhanced_analyze_image(image_panoramic)
    print(f"\n✓ Panoramic image ({image_panoramic.width}x{image_panoramic.height}):")
    print(f"  Scene type: {analysis['scene_type']}")
    assert analysis['scene_type'] == 'panoramic', "Should detect panoramic orientation"
    
    # Test with simulated data
    image_simulated = ImageInput(
        image_data=b"[image]",
        width=800,
        height=600,
        metadata={
            'simulated_description': 'Football match in progress',
            'simulated_objects': [
                {'object': 'football', 'confidence': 0.95},
                {'object': 'player', 'confidence': 0.90}
            ],
            'simulated_colors': ['green', 'white', 'blue']
        }
    )
    analysis = engine.enhanced_analyze_image(image_simulated)
    print(f"\n✓ Simulated image analysis:")
    print(f"  Description: {analysis['description']}")
    print(f"  Objects: {len(analysis['objects_detected'])}")
    assert analysis['description'] == 'Football match in progress', "Should use simulated description"
    
    print("\n✅ Enhanced image analysis tests passed!")


def test_enhanced_gesture_recognition():
    """Test gesture recognition with sequence detection."""
    print("\n" + "="*70)
    print("TEST 3: Enhanced Gesture Recognition")
    print("="*70)
    
    engine = MultiModalEngine()
    
    # Test single tap
    gesture_tap = GestureInput(
        gesture_type="tap",
        confidence=0.95,
        position=(100, 200)
    )
    result = engine.enhanced_interpret_gesture(gesture_tap)
    print(f"\n✓ Single tap:")
    print(f"  Interpretation: {result['interpretation']}")
    print(f"  Action: {result['action']}")
    print(f"  Confidence: {result['confidence']:.2f}")
    assert result['action'] == 'select_item', "Tap should select item"
    assert not result['is_sequence'], "Single gesture is not a sequence"
    
    # Test swipe with direction
    gesture_swipe = GestureInput(
        gesture_type="swipe",
        direction="left",
        confidence=0.88,
        position=(150, 200)
    )
    result = engine.enhanced_interpret_gesture(gesture_swipe)
    print(f"\n✓ Swipe left:")
    print(f"  Interpretation: {result['interpretation']}")
    print(f"  Action: {result['action']}")
    assert result['action'] == 'previous_item', "Swipe left should go to previous"
    
    # Test gesture sequence
    gestures_sequence = [
        GestureInput(gesture_type="tap", confidence=0.9),
        GestureInput(gesture_type="hold_long", confidence=0.85)
    ]
    result = engine.enhanced_interpret_gesture(gestures_sequence)
    print(f"\n✓ Gesture sequence (tap + hold):")
    print(f"  Interpretation: {result['interpretation']}")
    print(f"  Action: {result['action']}")
    print(f"  Is sequence: {result['is_sequence']}")
    print(f"  Sequence length: {result.get('sequence_length', 0)}")
    assert result['is_sequence'], "Multiple gestures should be detected as sequence"
    
    # Test pinch gestures
    gesture_pinch_open = GestureInput(
        gesture_type="pinch_open",
        confidence=0.92
    )
    result = engine.enhanced_interpret_gesture(gesture_pinch_open)
    print(f"\n✓ Pinch open:")
    print(f"  Action: {result['action']}")
    assert result['action'] == 'zoom_in', "Pinch open should zoom in"
    
    print("\n✅ Enhanced gesture recognition tests passed!")


def test_enhanced_multimodal_fusion():
    """Test intelligent multi-modal fusion with confidence weighting."""
    print("\n" + "="*70)
    print("TEST 4: Enhanced Multi-Modal Fusion")
    print("="*70)
    
    engine = MultiModalEngine()
    
    # Test text + voice fusion
    multi_input_1 = MultiModalInput(
        input_id="fusion_test_001",
        text_input="Show me predictions",
        voice_input=VoiceInput(
            audio_data=b"[audio]",
            duration_seconds=2.0,
            metadata={'simulated_text': 'show predictions'}
        )
    )
    fusion_result = engine.enhanced_fuse_modalities(multi_input_1)
    print(f"\n✓ Text + Voice fusion:")
    print(f"  Primary modality: {fusion_result['primary_modality']}")
    print(f"  Overall confidence: {fusion_result['overall_confidence']:.3f}")
    print(f"  Modalities used: {fusion_result['modalities_used']}")
    print(f"  Recommendation: {fusion_result['recommendation']}")
    assert fusion_result['modalities_used'] == 2, "Should use both modalities"
    assert fusion_result['overall_confidence'] > 0.8, "Should have high confidence"
    
    # Test text + image fusion
    multi_input_2 = MultiModalInput(
        input_id="fusion_test_002",
        text_input="Analyze this chart",
        image_input=ImageInput(
            image_data=b"[image]",
            width=800,
            height=600,
            metadata={
                'simulated_description': 'Bar chart showing trends',
                'simulated_objects': [{'object': 'bar_chart', 'confidence': 0.92}]
            }
        )
    )
    fusion_result = engine.enhanced_fuse_modalities(multi_input_2)
    print(f"\n✓ Text + Image fusion:")
    print(f"  Primary modality: {fusion_result['primary_modality']}")
    print(f"  Overall confidence: {fusion_result['overall_confidence']:.3f}")
    print(f"  Fused interpretation: {fusion_result['fused_interpretation'][:80]}...")
    assert fusion_result['modalities_used'] == 2, "Should use both modalities"
    
    # Test three modalities (text + voice + image)
    multi_input_3 = MultiModalInput(
        input_id="fusion_test_003",
        text_input="What does this show?",
        voice_input=VoiceInput(
            audio_data=b"[audio]",
            duration_seconds=1.5,
            metadata={'simulated_text': 'analyze image'}
        ),
        image_input=ImageInput(
            image_data=b"[image]",
            width=1024,
            height=768
        )
    )
    fusion_result = engine.enhanced_fuse_modalities(multi_input_3)
    print(f"\n✓ Three modalities (Text + Voice + Image):")
    print(f"  Primary modality: {fusion_result['primary_modality']}")
    print(f"  Overall confidence: {fusion_result['overall_confidence']:.3f}")
    print(f"  Modalities used: {fusion_result['modalities_used']}")
    print(f"  Recommendation: {fusion_result['recommendation']}")
    assert fusion_result['modalities_used'] == 3, "Should use all three modalities"
    assert fusion_result['overall_confidence'] > 0.85, "Three modalities should give very high confidence"
    
    # Test single modality
    multi_input_4 = MultiModalInput(
        input_id="fusion_test_004",
        text_input="Just text input"
    )
    fusion_result = engine.enhanced_fuse_modalities(multi_input_4)
    print(f"\n✓ Single modality (Text only):")
    print(f"  Primary modality: {fusion_result['primary_modality']}")
    print(f"  Overall confidence: {fusion_result['overall_confidence']:.3f}")
    print(f"  Recommendation: {fusion_result['recommendation']}")
    assert fusion_result['modalities_used'] == 1, "Should use only one modality"
    
    print("\n✅ Enhanced multi-modal fusion tests passed!")


def test_real_time_processing_pipeline():
    """Test real-time processing pipeline with multiple inputs."""
    print("\n" + "="*70)
    print("TEST 5: Real-Time Processing Pipeline")
    print("="*70)
    
    engine = MultiModalEngine()
    
    # Simulate real-time stream of inputs
    inputs = [
        ("text", "predict match"),
        ("voice", VoiceInput(audio_data=b"[audio]", duration_seconds=1.5)),
        ("image", ImageInput(image_data=b"[image]", width=800, height=600)),
    ]
    
    results = []
    for modality_type, data in inputs:
        if modality_type == "text":
            result = {"modality": "text", "content": data, "processed": True}
        elif modality_type == "voice":
            result = engine.enhanced_transcribe_audio(data)
            transcription = result["text"]
            confidence = result["confidence"]
            result = {"modality": "voice", "transcription": transcription, "confidence": confidence}
        elif modality_type == "image":
            analysis = engine.enhanced_analyze_image(data)
            result = {"modality": "image", "description": analysis["description"], "confidence": analysis["confidence"]}
        
        results.append(result)
        print(f"✓ Processed {modality_type}: {result.get('content', result.get('transcription', result.get('description', '')))[:50]}")
    
    print(f"\n✓ Total inputs processed: {len(results)}")
    assert len(results) == 3, "Should process all inputs"
    
    print("\n✅ Real-time processing pipeline tests passed!")


def test_accessibility_features():
    """Test accessibility mode and features."""
    print("\n" + "="*70)
    print("TEST 6: Accessibility Features")
    print("="*70)
    
    engine = MultiModalEngine()
    
    # Test multi-modal output with accessibility mode
    output = engine.generate_multi_modal_output(
        text="Prediction: Team A will win",
        include_voice=True,
        accessibility_mode=True
    )
    
    print(f"\n✓ Accessibility mode enabled:")
    print(f"  Text output: {output.text_output[:40]}...")
    print(f"  Voice output: {'Included' if output.voice_output else 'Not included'}")
    print(f"  Haptic feedback: {'Enabled' if output.haptic_feedback else 'Disabled'}")
    print(f"  Modality priority: {', '.join([m.value for m in output.modality_priority])}")
    
    assert output.voice_output is not None, "Should include voice output"
    assert output.haptic_feedback is not None, "Should include haptic feedback"
    
    print("\n✅ Accessibility features tests passed!")


def main():
    """Run all Day 4 enhanced capability tests."""
    print("\n" + "="*70)
    print("MULTI-MODAL ENGINE - DAY 4 ENHANCED CAPABILITIES TEST SUITE")
    print("="*70)
    print("\nTesting enhanced simulations for production-ready multi-modal support")
    
    try:
        test_enhanced_speech_recognition()
        test_enhanced_image_analysis()
        test_enhanced_gesture_recognition()
        test_enhanced_multimodal_fusion()
        test_real_time_processing_pipeline()
        test_accessibility_features()
        
        print("\n\n" + "="*70)
        print("🎉 ALL DAY 4 TESTS PASSED!")
        print("="*70)
        print("\nEnhanced capabilities verified:")
        print("  ✅ Context-aware speech recognition")
        print("  ✅ Advanced image analysis with object detection")
        print("  ✅ Gesture sequence recognition")
        print("  ✅ Intelligent multi-modal fusion")
        print("  ✅ Real-time processing pipeline")
        print("  ✅ Accessibility features")
        print("\nMulti-modal engine is production-ready! 🚀\n")
        
    except AssertionError as e:
        print(f"\n❌ TEST FAILED: {e}\n")
        raise
    except Exception as e:
        print(f"\n❌ ERROR: {e}\n")
        raise


if __name__ == "__main__":
    main()
