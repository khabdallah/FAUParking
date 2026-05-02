
#  FAUParking – Drone-Based Parking Detection System
Group members: **Lance Van**
**Khalid Abdallah**
**Oliver Si**
**Bryan Gatto**
**Gabriel Fusaro**

##  Overview

FAUParking is an intelligent parking management system that uses **drone imagery + computer vision** to detect real-time parking availability.

The system processes aerial images, identifies vehicles using deep learning models, and maps occupancy to predefined parking spots, delivering results to a mobile application.

---

##  System Architecture

The platform is composed of five main components:

```
Drone Control and Imagery
        ↓
Backend API (FastAPI)
        ↓
Frame Processing Service (YOLO + OpenCV)
        ↓
Frontend (iOS App)
        ↓
Parking Availability Results
```

### Components

* ** Drone Control and Imagery
  
   * Reads and adjusts GPS coordinates of drone
   * Follows a set of checkpoints
   * Automates Image Capture and Server Upload
  
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

**Drone Control and Imaging**
* Python
---

##  How It Works

1. Run Drone Flight Path
2. Drone captures aerial parking lot images
3. Frame processing service:

   * Corrects perspective (top-down transformation)
   * Detects vehicles using YOLO
4. System checks overlap between cars and parking spot regions
5. Backend API returns availability data
6. Mobile app displays results

---
## App features

* Splash screen when the app is opened
* Dashboard that displays the data from the database
* Lot selector
* Interactable 2D model of lot layout with space status visible
* spots lists and details screens
* map screen that shows the user what lots have the system implemented and their addresses.
---

## How to Run

Drone Control: Open and run the Python Drone Control Code while then switching to the emulated drone control app. Turn on
any android debugging bridge setting available. Make sure that the Drone has GPS calibrated with two network connections 
(Internet for server upload and the Drone WIFI itself). **Important: Point the front of drone towards North!

Mobile app: Open the Parking folder in Xcode on a Mac computer and run the project on an IOS simulator tht supports IOS 26 or higher.

---

##  Model Details

* Model: YOLOv8
* Task: Object Detection (Vehicles)
* Training Data: PKLot / custom datasets
* Output: Bounding boxes of detected vehicles

---


##  Author

**Lance Van**
**Khalid Abdallah**
**Oliver Si**
**Bryan Gatto**
**Gabriel Fusaro**
---


