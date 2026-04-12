import cv2
import numpy as np
import os
import sys

from align import align_to_master, precompute_master
from config import load_lot
from detect import detect_cars
from occupancy import check_occupancy



MASTER_CACHE = {}


def draw_visualization(image, parking_data, occupancy_result, boxes):
    """Draw parking polygons, occupancy state, and detected cars."""
    vis = image.copy()

    occupied_ids = {o["id"] for o in occupancy_result["occupied"]}

    for polygon, spot_id in parking_data:
        polygon = np.array(polygon, np.int32)

        if spot_id in occupied_ids:
            color = (0, 0, 255)  # red
        else:
            color = (0, 255, 0)  # green

        cv2.polylines(vis, [polygon], True, color, 2)

        cx = int(np.mean(polygon[:, 0]))
        cy = int(np.mean(polygon[:, 1]))
        cv2.putText(
            vis,
            spot_id,
            (cx, cy),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.5,
            color,
            2,
            cv2.LINE_AA,
        )

    for box in boxes:
        x1, y1, x2, y2 = int(box[0]), int(box[1]), int(box[2]), int(box[3])
        cv2.rectangle(vis, (x1, y1), (x2, y2), (255, 0, 0), 2)

        if len(box) > 4:
            conf = box[4]
            cv2.putText(
                vis,
                f"{conf:.2f}",
                (x1, y1 - 10),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.5,
                (255, 0, 0),
                1,
                cv2.LINE_AA,
            )

    return vis


def promote_master(lot_id, aligned_image, inliers, inlier_threshold=140):
    """Saves the current aligned frame as the new master if it matches exceptionally well.
    
    Since the image is already 'aligned', it perfectly matches the existing 
    coordinates in parking.json.
    """
    if inliers > inlier_threshold:
        lot_path = os.path.join("lots", lot_id)
        if not os.path.exists(lot_path):
            return False
            
        master_path = os.path.join(lot_path, "master.jpg")
        backup_path = os.path.join(lot_path, "master_backup.jpg")
        
        if os.path.exists(master_path) and not os.path.exists(backup_path):
            os.rename(master_path, backup_path)
            
        cv2.imwrite(master_path, aligned_image)
        print(f"🌟 Master image for lot {lot_id} PROMOTED (Inliers: {inliers})")
        
        if lot_id in MASTER_CACHE:
            del MASTER_CACHE[lot_id]
        return True
    return False


def visualize_lot(lot_id, image_path, output_path="debug_visualized.jpg"):
    """Full visualization pipeline."""
    print(f"Loading lot: {lot_id}")
    print(f"Image: {image_path}")

    master_img, parking_data, err = load_lot(lot_id)
    if err:
        print("Error:", err)
        return

    image = cv2.imread(image_path)
    if image is None:
        print("Error: Could not load image:", image_path)
        return

    print("Aligning image...")
    
   
    if lot_id not in MASTER_CACHE:
        print(f"Precomputing master features for lot {lot_id}...")
        kp, des = precompute_master(master_img)
        MASTER_CACHE[lot_id] = (kp, des)
    
    master_kp, master_des = MASTER_CACHE[lot_id]
    
    align_result = align_to_master(master_img, image, master_kp=master_kp, master_des=master_des)
    aligned = align_result["aligned"]
    inliers = align_result["inliers"]

    if align_result["homography"] is None:
        print(" Alignment failed — using original image (All fallbacks exhausted)")
        aligned = image
    else:
        fallback = align_result.get("fallback_used", "None")
        if fallback == "None":
            print(f"Alignment successful (Standard Methods). Inliers: {inliers}")
        else:
            print(f"Alignment successful via Fallback ({fallback}). Inliers: {inliers}")
        promote_master(lot_id, aligned, inliers)

    print("Running detection...")
    boxes = detect_cars(aligned)

    print(f"Detected {len(boxes)} vehicles")
    for i, box in enumerate(boxes):
        print(f"  Box {i}: {box}")

    print("Checking occupancy...")
    occ = check_occupancy(boxes, parking_data)

    print(f"Occupied: {len(occ['occupied'])}")
    print(f"Free: {len(occ['free'])}")

    print("Drawing visualization...")
    vis = draw_visualization(aligned, parking_data, occ, boxes)

    cv2.imwrite(output_path, vis)
    print("Saved:", output_path)

    return vis


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python visualize_lot.py <image_path> [lot_id]")
        sys.exit(1)

    image_path = sys.argv[1]
    lot_id = sys.argv[2] if len(sys.argv) > 2 else "1"

    # Use the full pipeline function
    visualize_lot(lot_id, image_path)