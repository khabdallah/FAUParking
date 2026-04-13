import os
import sys
import glob
import cv2
import numpy as np
from align import align_to_master, precompute_master
from detect import detect_cars
from config import load_lot

def evaluate_alignment_quality(lot_id, test_images_dir):
    """
    Evaluates how well a set of images aligns with the master image.
    Logs RANSAC inliers, good matches, and any fallbacks used.
    """
    print(f"\n{'='*50}")
    print(f"ALIGNMENT QUALITY EVALUATION FOR LOT: {lot_id}")
    print(f"{'='*50}")

    master_img, parking_data, err = load_lot(lot_id)
    if err:
        print("Error loading lot:", err)
        return

    print("Precomputing master image SIFT features...")
    master_kp, master_des = precompute_master(master_img)

    image_paths = glob.glob(os.path.join(test_images_dir, "*.jpg")) + glob.glob(os.path.join(test_images_dir, "*.png"))
    
    if not image_paths:
        print(f"No test images found in {test_images_dir}!")
        return

    results = []
    failed_count = 0

    for img_path in image_paths:
        img_name = os.path.basename(img_path)
        test_img = cv2.imread(img_path)
        if test_img is None:
            continue

        align_res = align_to_master(master_img, test_img, master_kp=master_kp, master_des=master_des)
        
        inliers = align_res["inliers"]
        matches = align_res["good_matches"]
        fallback = align_res.get("fallback_used", "None")

        success = "PASS" if align_res["homography"] is not None else "FAIL"
        if success == "FAIL":
            failed_count += 1

        results.append({
            "image": img_name,
            "status": success,
            "inliers": inliers,
            "matches": matches,
            "fallback": fallback
        })

        print(f"[{success}] {img_name} -> Inliers: {inliers:4d} | Matches: {matches:4d} | Fallback: {fallback}")

    success_rate = ((len(image_paths) - failed_count) / len(image_paths)) * 100
    print(f"\n--- Alignment Summary ---")
    print(f"Total Images: {len(image_paths)}")
    print(f"Success Rate: {success_rate:.1f}%")
    
    successful_inliers = [r["inliers"] for r in results if r["status"] == "PASS"]
    if successful_inliers:
        avg_inliers = sum(successful_inliers) / len(successful_inliers)
        print(f"Average Inliers (Successes): {avg_inliers:.1f}")
    else:
        print("Average Inliers (Successes): N/A")

def evaluate_detection_confidence(test_images_dir):
    """
    Evaluates detection confidence across test images.
    """
    print(f"\n{'='*50}")
    print(f"DETECTION CONFIDENCE EVALUATION")
    print(f"{'='*50}")

    image_paths = glob.glob(os.path.join(test_images_dir, "*.jpg")) + glob.glob(os.path.join(test_images_dir, "*.png"))
    
    if not image_paths:
        print(f"No test images found in {test_images_dir}!")
        return

    total_cars_detected = 0
    all_confidences = []

    for img_path in image_paths:
        img_name = os.path.basename(img_path)
        test_img = cv2.imread(img_path)
        if test_img is None:
            continue
            
        print(f"Processing {img_name}...")
        try:
            boxes = detect_cars(test_img)
            
            num_cars = len(boxes)
            total_cars_detected += num_cars
            
            if num_cars > 0:
                confidences = [b[4] for b in boxes if len(b) > 4]
                all_confidences.extend(confidences)
                avg_conf = sum(confidences) / len(confidences)
                
                print(f"  -> Cars Detected: {num_cars:3d} | Avg Confidence: {avg_conf:.3f}")
            else:
                print(f"  -> Cars Detected:   0")
        except Exception as e:
            print(f"  -> Error detecting: {e}")

    print(f"\n--- Detection Summary ---")
    print(f"Total Images: {len(image_paths)}")
    print(f"Total Cars Detected: {total_cars_detected}")
    if all_confidences:
        global_avg_conf = sum(all_confidences) / len(all_confidences)
        print(f"Global Average Confidence: {global_avg_conf:.3f}")
        print(f"Min Confidence Found: {min(all_confidences):.3f}")
        print(f"Max Confidence Found: {max(all_confidences):.3f}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python evaluate_quality.py <test_images_directory> [lot_id]")
        print("Example: python evaluate_quality.py ./test_images 1")
        sys.exit(1)

    test_dir = sys.argv[1]
    lot_id = sys.argv[2] if len(sys.argv) > 2 else "1"

    if not os.path.isdir(test_dir):
        print(f"Error: {test_dir} is not a valid directory.")
        sys.exit(1)

    evaluate_alignment_quality(lot_id, test_dir)
    evaluate_detection_confidence(test_dir)
