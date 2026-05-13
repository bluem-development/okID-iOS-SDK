# YOLO Model Setup for iOS

## Overview
The document camera functionality uses a YOLO model for real-time document detection. The model detects ID cards, passports, MRZ zones, and portrait photos.

## Required Model
- **Model Name**: `document_detection_320`
- **Input Size**: 320x320 pixels
- **Classes**: portrait, idcard, mrz, passport
- **Format**: CoreML (.mlmodel or .mlpackage)

## Converting TensorFlow Lite to CoreML

If you have a TensorFlow Lite model (`document_detection_320.tflite`), convert it to CoreML:

### Option 1: Using coremltools (Python)

```bash
pip install coremltools tensorflow

python3 << EOF
import coremltools as ct
import tensorflow as tf

# Load TFLite model
tflite_model_path = 'document_detection_320.tflite'
mlmodel = ct.converters.convert(
    tflite_model_path,
    source='tensorflow',
    convert_to='mlprogram'  # or 'neuralnetwork' for older iOS versions
)

# Save CoreML model
mlmodel.save('document_detection_320.mlpackage')
EOF
```

### Option 2: Using Ultralytics YOLO Export

If you have access to the original YOLO model:

```python
from ultralytics import YOLO

# Load your model
model = YOLO('document_detection_320.pt')

# Export to CoreML
model.export(format='coreml', imgsz=320)
```

## Adding Model to Xcode Project

1. **Locate the Model File**:
   - Find `document_detection_320.mlmodel` or `document_detection_320.mlpackage`

2. **Add to Xcode**:
   - Open your Xcode project
   - Drag and drop the model file into the project navigator
   - Ensure "Copy items if needed" is checked
   - Select your target in "Add to targets"
   - Click "Finish"

3. **Verify Model Properties**:
   - Click on the model file in Xcode
   - Check that:
     - Input: Image (Color 320x320)
     - Output: Coordinates, confidence, classLabel
     - Target Membership is selected

4. **Compile**:
   - Xcode will automatically compile the model to `.mlmodelc` format
   - The compiled model will be bundled with your app

## Model Configuration

The model uses these thresholds (defined in `YOLOConfig`):

```swift
confidenceThreshold: 0.25  // 25% - initial detection
requiredConfidenceThreshold: 0.5  // 50% - for auto-capture
iouThreshold: 0.4
edgeMarginPixels: 2.0
```

## Valid Document Classes

The detector recognizes these classes:
- `portrait` - Portrait photo on ID
- `idcard` - ID card
- `mrz` - Machine Readable Zone
- `passport` - Passport

## Fallback Behavior

If the YOLO model is not found or fails to load:
- The app will log: `[YOLO] Model file not found: document_detection_320`
- Detection will fall back to basic rectangle detection using Vision framework
- Auto-capture will still work based on image quality and composition

## Testing

To verify the model is working:

1. Run the app and open the document camera
2. Point at an ID card or passport
3. Check Xcode console for:
   ```
   [YOLO] Model loaded successfully
   [YOLO] Found X detections
   [YOLO] Detection: idcard at 85.3%
   ```

## Troubleshooting

### Model Not Found
```
[YOLO] Model file not found: document_detection_320
```
**Solution**: Ensure the model is added to the Xcode project with target membership selected.

### Wrong Input Size
```
[YOLO] Prediction error: Expected input image of size (320, 320)
```
**Solution**: Verify your model expects 320x320 input. Re-export if needed.

### No Detections
```
[YOLO] Found 0 detections
```
**Solutions**:
- Ensure the model was trained on document detection
- Check that class names match: portrait, idcard, mrz, passport
- Verify confidence threshold isn't too high

### Low Confidence Scores
```
[YOLO] Detection: idcard at 15.2%
```
**Solution**: Lower the `confidenceThreshold` in `YOLOConfig` if needed.

## Model Performance

Expected performance on iPhone 12 and newer:
- Inference time: 50-100ms per frame
- Frame rate: 1 check per second (configurable via timer interval)
- Memory usage: ~50MB for model

For older devices, consider:
- Increasing timer interval to 1.5-2 seconds
- Using a smaller model (e.g., 224x224)
- Reducing image resolution before inference

## Alternative: Vision Framework Fallback

The current implementation includes Vision framework rectangle detection as a fallback. If you don't have a YOLO model, the system will:
- Use `VNDetectRectanglesRequest` for basic document detection
- Still provide auto-capture based on:
  - Rectangle detected (confidence > 60%)
  - Rectangle within guide area
  - Image sharpness above threshold

This provides basic functionality without YOLO, though with less accuracy in document classification.

