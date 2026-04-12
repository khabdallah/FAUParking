# Testing and Performance Evaluation

This document outlines the tools available for evaluating the performance, accuracy, and latency of the Drone Parking Management backend. By using these scripts, we can ensure the pipeline works consistently across different environmental conditions and runs efficiently without resource bottlenecks.

## 1. Latency & Bottleneck Tracking (`profile_pipeline.py`)

This script is meant for **diagnosing speed issues** and tracking the raw computational cost of the parsing and visualization process.

**What it tests:**
*   **Cold vs. Warm Starts:** Compares execution time when homography/SIFT keypoints are cached versus when they are processed from scratch.
*   **Detailed Function Profiling:** Uses Python's internal `cProfile` and `pstats` to print out a highly detailed stack trace showing exactly how many milliseconds are spent in every function (`cv2.warpPerspective`, `matcher.knnMatch`, `YOLO.predict`, etc).

**How to run it:**
```bash
python profile_pipeline.py
```
*(Requires a `test_lot1.png` file to exist locally in the directory. A detailed dump will be saved to `profile_results.txt`.)*

---

## 2. Model Accuracy & Pipeline Quality (`evaluate_quality.py`)

Performance is nothing without accuracy. This script is used to **batch process** an entire directory of drone images and report on the overall health of the computer vision pipeline.

**What it evaluates:**
*   **Alignment Robustness:** Checks how many RANSAC inliers and "Good Matches" are detected for each image. It identifies if images require "fallback" alignment methods (like CLAHE enhancements or ORB matching) and tabulates a success percentage. 
*   **Confidence Scoring:** Tests the Roboflow object detection model by tracking the number of vehicles found per image, along with the global average, minimum, and maximum confidence rating across the dataset. 

**How to run it:**
```bash
python evaluate_quality.py <directory_of_images> [lot_id]
```
**Example:**
```bash
python evaluate_quality.py ./test_assets/rainy_day_images 1
```

---

## 3. Future Testing Integrations (To-Do)

While performance tracking and batch quality checks are currently active, future expansions should implement the following for rigorous CI/CD:

*   **Unit Tests (`pytest`):** Scripts named `test_detect.py` or `test_align.py` to assert expected behavior for small, isolated functions (e.g., verifying bounding boxes don't return negative array constraints).
*   **Memory Profiling (`memory_profiler`):** Tagging functions with `@profile` to catch memory leaks, ensuring RAM usage stays flat over thousands of concurrent drone images.
*   **Server Load Testing:** Using `locust` or thread pools to blast the main `visualize_lot()` server wrapper with simultaneous multi-threading requests.
