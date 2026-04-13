
#  FAUParking – Drone-Based Parking Detection System

##  Overview

FAUParking is an intelligent parking management system that uses **drone imagery + computer vision** to detect real-time parking availability.

The system processes aerial images, identifies vehicles using deep learning models, and maps occupancy to predefined parking spots, delivering results to a mobile application.

---

##  System Architecture

The platform is composed of three main components:

```
Frontend (iOS App)
        ↓
Backend API (FastAPI)
        ↓
Frame Processing Service (YOLO + OpenCV)
        ↓
Parking Availability Results
```

### Components

* ** Frontend (iOS App)**

  * Displays parking availability to users
  * Visualizes parking spots and occupancy

* ** Backend API**

  * Built with FastAPI
  * Handles requests from the mobile app
  * Communicates with processing services and database

* ** Frame Processing Service**

  * Aligns drone images to top-down view
  * Detects vehicles using YOLOv8
  * Determines occupancy using polygon overlap logic

* ** Workers**

  * Handle asynchronous processing tasks
  * Manage data flow between services

---

## Project Structure

```
FAUParking/
│
├── frontend/                 # iOS application
│
├── backend/
│   ├── api/                 # FastAPI backend
│   ├── frame-processing/    # Computer vision pipeline
│   └── workers/             # Background workers
│
├── hardware/
│   ├── notebooks/           # jpynb for drone control hardware
│
├── docs/                    # Diagrams and documentation
│
└── README.md
```

---

##  Features

* Real-time parking detection from drone imagery
* YOLO-based vehicle detection
* Image alignment using homography
* Parking spot mapping using polygon overlap
* Scalable backend architecture
* Mobile app integration

---

##  Tech Stack

**Computer Vision**

* YOLOv8 (Ultralytics)
* OpenCV

**Backend**

* FastAPI
* Python

**Frontend**

* iOS (Swift / Xcode)

**Infrastructure**

* Google Colab (training)
* Roboflow (dataset + deployment)

---

##  How It Works

1. Drone captures aerial parking lot images
2. Frame processing service:

   * Corrects perspective (top-down transformation)
   * Detects vehicles using YOLO
3. System checks overlap between cars and parking spot regions
4. Backend API returns availability data
5. Mobile app displays results

---

##  Model Details

* Model: YOLOv8
* Task: Object Detection (Vehicles)
* Training Data: PKLot / custom datasets
* Output: Bounding boxes of detected vehicles

---


##  Author

**Lance Van**
---


