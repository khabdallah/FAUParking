
from fastapi import FastAPI, File, UploadFile
from roboflow import Roboflow
import cv2
import numpy as np
import pickle
import os

app = FastAPI()


# Initialize Roboflow
rf = Roboflow(api_key="crcxvzrMUhqJYcyMcpW8")
project = rf.workspace("drone-parking-management-system").project("drone-parking-detection")
model = project.version(3).model

# Load Parking Data
MASTER_IMAGE_PATH = "master_lot.JPG"
PARKING_DATA_PATH = "parking_data.pkl"

master_img = cv2.imread(MASTER_IMAGE_PATH)
if master_img is None:
    raise RuntimeError(f"Failed to load master image: {MASTER_IMAGE_PATH}")

master_gray = cv2.cvtColor(master_img, cv2.COLOR_BGR2GRAY)

orb = cv2.ORB_create(5000)
kp_master, des_master = orb.detectAndCompute(master_gray, None)

with open(PARKING_DATA_PATH, "rb") as f:
    parking_data = pickle.load(f)


def align_to_master(input_img):
    gray1 = cv2.cvtColor(master_img, cv2.COLOR_BGR2GRAY)
    gray2 = cv2.cvtColor(input_img, cv2.COLOR_BGR2GRAY)

    orb = cv2.ORB_create(5000)
    kp1, des1 = orb.detectAndCompute(gray1, None)
    kp2, des2 = orb.detectAndCompute(gray2, None)

    matcher = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
    matches = matcher.match(des1, des2)
    matches = sorted(matches, key=lambda x: x.distance)[:200]

    pts1 = np.float32([kp1[m.queryIdx].pt for m in matches])
    pts2 = np.float32([kp2[m.trainIdx].pt for m in matches])

    H, _ = cv2.findHomography(pts2, pts1, cv2.RANSAC)

    aligned = cv2.warpPerspective(input_img, H,
                                  (master_img.shape[1], master_img.shape[0]))

    return aligned, H


@app.post("/detect")
async def detect_parking(file: UploadFile = File(...)):
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if image is None:
        return {"error": "Image decode failed"}

    # Align to master
    aligned_img, H = align_to_master(image)

    # Save aligned image for Roboflow
    cv2.imwrite("aligned.jpg", aligned_img)

    # Run detection on aligned image
    rf_pred = model.predict("aligned.jpg", confidence=40, overlap=30).json()
    predictions = rf_pred["predictions"]

    boxes = []
    for p in predictions:
        x, y, w, h = p["x"], p["y"], p["width"], p["height"]
        x1, y1 = int(x - w/2), int(y - h/2)
        x2, y2 = int(x + w/2), int(y + h/2)
        boxes.append([x1, y1, x2, y2])

    occupied = []
    free = []
    vis = aligned_img.copy()

    # Compare in MASTER coordinate space
    for spot in parking_data:
        polygon = np.array(spot[0], np.int32)
        spot_id = spot[1]
        is_occ = False

        for box in boxes:
            cx = int((box[0]+box[2])/2)
            cy = int((box[1]+box[3])/2)

            if cv2.pointPolygonTest(polygon, (cx,cy), False) >= 0:
                is_occ = True
                break

        if is_occ:
            occupied.append(spot_id)
            cv2.polylines(vis, [polygon], isClosed=True, color=(0, 0, 255), thickness=2)
        else:
            free.append(spot_id)
            cv2.polylines(vis, [polygon], isClosed=True, color=(0, 255, 0), thickness=2)

    for box in boxes:
        cv2.rectangle(vis, (box[0], box[1]), (box[2], box[3]), (255, 0, 0), 2)
    cv2.imwrite("debug_labeled.jpg", vis)
    return {
        "occupied": occupied,
        "free": free,
        "total_detected": len(boxes),
        "debug_image": "debug_labeled.jpg"
    }
# To run this: python -m uvicorn main:app --reload
