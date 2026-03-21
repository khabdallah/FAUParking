# Drone Parking Frame Processing Server

The core backend visual intelligence pipeline for the Drone Parking Management System. This Python-based application is responsible for taking raw drone imagery from above a parking lot, aligning it to a known coordinate space, and running detection algorithms to map free vs. occupied parking spots.

## Architecture & Features 

- **YOLO Detection via Roboflow (`detect.py`)**: Enhances images (LAB CLAHE, Gamma correction) and queries a fine-tuned Roboflow model to detect bounding boxes around vehicles.
- **Robust SIFT Alignment Pipeline (`align.py`)**: Uses a precomputed master image to align angled, drifted drone camera frames perfectly to the static parking spot coordinates. 
  - *Fallbacks Exhaustive pipeline*: If normal SIFT + FLANN matching fails, the system automatically falls back to relaxed Lowe's ratio matches, CLAHE Local Contrast enhancements, or an alternative ORB mathematical approach to guarantee image-to-coordinate registration.
- **Occupancy Mapping (`occupancy.py`)**: Computes IoU (Intersection over Union)/overlap logic against predefined polygonal coordinates (stored in your lot config) to determine the real-time state of each spot (Free/Occupied).
- **Visualization (`visualize_lot.py`)**: An end-to-end script that loads models, handles cache/feature precomputations, runs alignment, maps occupancy, and provides fully overlaid outputs for visual QA and debugging.
- **Dynamic Master Autopromotion**: Automatically promotes newly aligned frames with extremely high RANSAC inlier confidence as your new environmental "master" frame to stay robust against shadows and changing daylight over time.

## Requirements

You must install the packages inside `requirements.txt`:
```bash
pip install -r requirements.txt
```

*Expected Libraries:*
- `opencv-python` (cv2)
- `numpy`
- `roboflow`

### Environment Variables

You must supply your Roboflow API key to leverage the cloud model. Put this in your `.env` or run profile:
```bash
export ROBOFLOW_API_KEY="your_api_key_here"
```

## Usage

You can test the entire pipeline by giving it an image to process:
```bash
python visualize_lot.py test_lot1.png 1
```

*(Where `1` is the Lot ID referencing your config files).*
This will spit out `debug_visualized.jpg` showing bounding boxes over vehicles and properly categorized Green/Red parking lot polygon shapes.

## Testing Core Alignment
To test the robust alignment fallbacks separated from the Roboflow pipeline:
```bash
python align.py <master_image> <test_image>
```

## System Workflow Summary

1. **Load Image & Fetch Cache**: Caches SIFT descriptors of your parking lot master frame.
2. **Align**: Wraps `cv2.findHomography` and `cv2.warpPerspective` to match the exact dimensions/perspective of the master layout.
3. **Detect**: Applies sharpening and contrast filters before grabbing YOLO bounding boxes.
4. **Determine Occupancy**: Evaluates bounding box overlap against standard Spot IDs.
5. **Report**: (Hooks to Cloudflare D1 REST API / iOS Application in parent scopes).
