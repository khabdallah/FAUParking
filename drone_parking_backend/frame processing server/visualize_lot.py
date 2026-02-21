import cv2
import numpy as np
import os
import sys

from align import align_to_master
from config import load_lot
from detect import detect_cars
from occupancy import check_occupancy


def draw_visualization(image, parking_data, occupancy_result, boxes):
    """Draw parking polygons, occupancy state, and detected cars."""
    vis = image.copy()

    occupied_ids = {o["id"] for o in occupancy_result["occupied"]}

    # Draw parking spots
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

    # Draw detected cars
    for box in boxes:
        x1, y1, x2, y2 = int(box[0]), int(box[1]), int(box[2]), int(box[3])
        cv2.rectangle(vis, (x1, y1), (x2, y2), (255, 0, 0), 2)

    return vis


def visualize_lot(lot_id, image_path, output_path="debug_visualized.jpg"):
    """Full visualization pipeline."""
    print(f"Loading lot: {lot_id}")

    master_img, parking_data, err = load_lot(lot_id)
    if err:
        print("Error:", err)
        return

    image = cv2.imread(image_path)
    if image is None:
        print("Error: Could not load image:", image_path)
        return

    print("Aligning image...")
    align_result = align_to_master(master_img, image)
    aligned = align_result["aligned"]

    if align_result["homography"] is None:
        print("⚠️ Alignment failed — using original image")
        aligned = image

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
        print("Usage: python vizualize_lot.py <image_path> [lot_id]")
        sys.exit(1)

    image_path = sys.argv[1]

    # Default lot = "1"
    lot_id = sys.argv[2] if len(sys.argv) > 2 else "1"

    print(f"Using lot: {lot_id}")
    print(f"Image: {image_path}")

    # Load lot config
    master_img, parking_data, err = load_lot(lot_id)
    if err:
        print(err)
        sys.exit(1)

    image = cv2.imread(image_path)
    if image is None:
        print(f"Could not load image: {image_path}")
        sys.exit(1)

    # Align
    align_result = align_to_master(master_img, image)
    aligned = align_result["aligned"]

    # Detect
    boxes = detect_cars(aligned)
    print(f"Detected {len(boxes)} vehicles")
    for i, box in enumerate(boxes):
        print(f"  Box {i}: {box}")

    # Occupancy
    occupancy_result = check_occupancy(boxes, parking_data)
    print("Occupied spots:")
    for spot in occupancy_result["occupied"]:
        print(f"  {spot['id']} (conf: {spot['confidence']:.2f})")

    # Draw
    vis = draw_visualization(aligned, parking_data, occupancy_result, boxes)

    out_path = "debug_visualized.jpg"
    cv2.imwrite(out_path, vis)
    print(f"Saved: {out_path}")