
from fastapi import FastAPI, File, UploadFile
from roboflow import Roboflow
import cv2
import numpy as np
import pickle
import os

app = FastAPI()
print("LOADING NEW MAIN.PY")

# Initialize Roboflow
rf = Roboflow(api_key="crcxvzrMUhqJYcyMcpW8")
project = rf.workspace("drone-parking-management-system").project("drone-parking-detection")
model = project.version(3).model

# Load Parking Data
LOT_DIR = "lots"

def load_lot(lot_id):
    lot_path = os.path.join(LOT_DIR, lot_id)
    master_path = os.path.join(lot_path, "master.jpg")
    parking_path = os.path.join(lot_path, "parking.pkl")

    if not os.path.exists(master_path):
        return None, None, f"Master image missing for {lot_id}"

    if not os.path.exists(parking_path):
        return None, None, f"Parking data missing for {lot_id}"

    master_img = cv2.imread(master_path)

    with open(parking_path, "rb") as f:
        parking_data = pickle.load(f)

    return master_img, parking_data, None


def align_to_master(master, new_img):
    gray1 = cv2.cvtColor(master, cv2.COLOR_BGR2GRAY)
    gray2 = cv2.cvtColor(new_img, cv2.COLOR_BGR2GRAY)

    orb = cv2.ORB_create(5000)
    kp1, des1 = orb.detectAndCompute(gray1, None)
    kp2, des2 = orb.detectAndCompute(gray2, None)

    if des1 is None or des2 is None:
        return new_img, None

    matcher = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
    matches = matcher.match(des1, des2)

    matches = sorted(matches, key=lambda x: x.distance)
    matches = matches[:200]

    pts1 = np.float32([kp1[m.queryIdx].pt for m in matches])
    pts2 = np.float32([kp2[m.trainIdx].pt for m in matches])

    H, _ = cv2.findHomography(pts2, pts1, cv2.RANSAC)

    if H is None:
        return new_img, None

    aligned = cv2.warpPerspective(new_img, H, (master.shape[1], master.shape[0]))
    return aligned, H


@app.post("/detect/{lot_id}")
async def detect_parking(lot_id: str, file: UploadFile = File(...)):

    # ---- Load lot config ----
    master_img, parking_data, err = load_lot(lot_id)
    if err:
        return {"error": err}

    # ---- Read uploaded image ----
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if image is None:
        return {"error": "Image decode failed"}

    # Save raw debug
    os.makedirs("debug", exist_ok=True)
    cv2.imwrite("debug/raw.jpg", image)

    # ---- Align to master ----
    aligned, H = align_to_master(master_img, image)

    # ---- Roboflow detection ----
    cv2.imwrite("debug/aligned.jpg", aligned)
    pred = model.predict("debug/aligned.jpg", confidence=40, overlap=30).json()
    detections = pred["predictions"]

    boxes = []
    for d in detections:
        x, y, w, h = d["x"], d["y"], d["width"], d["height"]
        x1, y1 = int(x - w/2), int(y - h/2)
        x2, y2 = int(x + w/2), int(y + h/2)
        boxes.append((x1, y1, x2, y2))

    # ---- Occupancy ----
    occupied = []
    free = []

    vis = aligned.copy()

    for spot in parking_data:
        polygon = np.array(spot[0], np.int32)
        spot_id = spot[1]

        is_occ = False
        for box in boxes:
            cx = int((box[0] + box[2]) / 2)
            cy = int((box[1] + box[3]) / 2)
            if cv2.pointPolygonTest(polygon, (cx, cy), False) >= 0:
                is_occ = True
                break

        if is_occ:
            occupied.append(spot_id)
            color = (0,0,255)
        else:
            free.append(spot_id)
            color = (0,255,0)

        cv2.polylines(vis, [polygon], True, color, 2)
        cx = int(np.mean(polygon[:,0]))
        cy = int(np.mean(polygon[:,1]))
        cv2.putText(vis, spot_id, (cx,cy),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)

    # Draw car boxes
    for box in boxes:
        cv2.rectangle(vis, (box[0],box[1]), (box[2],box[3]), (255,0,0), 2)

    cv2.imwrite("debug/labeled.jpg", vis)

    return {
        "lot": lot_id,
        "occupied": occupied,
        "free": free,
        "total_detected": len(boxes),
        "debug_image": "debug/labeled.jpg"
    }
# To run this: python -m uvicorn main:app --reload
