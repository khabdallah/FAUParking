import cv2
import sys
from detect import detect_cars

def main():
    if len(sys.argv) < 2:
        print("Usage: python run_model.py <image_path>")
        sys.exit(1)
        
    image_path = sys.argv[1]
    confidence_threshold = int(sys.argv[2]) if len(sys.argv) > 2 else 10 # Default to 10 for debugging
    
    print(f"Loading '{image_path}'...")
    img = cv2.imread(image_path)
    
    if img is None:
        print(f"Failed to load image: {image_path}")
        sys.exit(1)
        
    print(f"Running Roboflow detection with confidence threshold {confidence_threshold}%...")
    boxes = detect_cars(img, confidence=confidence_threshold)
    
    print(f"Total detections: {len(boxes)}")
    for i, (x1, y1, x2, y2, conf) in enumerate(boxes):
        print(f"  [{i}] ({x1}, {y1}) -> ({x2}, {y2}) conf: {conf:.2f}")

    # Draw the boxes
    vis = img.copy()
    for x1, y1, x2, y2, conf in boxes:
        cv2.rectangle(vis, (x1, y1), (x2, y2), (0, 0, 255), 2)
        cv2.putText(vis, f"{conf:.2f}", (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 0, 255), 2)
        
    out_name = f"model_only_output.jpg"
    cv2.imwrite(out_name, vis)
    print(f"Saved visualization to {out_name}")

if __name__ == "__main__":
    main()
