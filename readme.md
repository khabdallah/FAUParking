
#  FAUParking – Drone-Based Parking Detection System
Group members: **Lance Van**,
**Khalid Abdallah**,
**Oliver Si**,
**Bryan Gatto**,
**Gabriel Fusaro**

Sponsor: Dr. Arsan Munir

Advisor: Dr. Zhen Ni

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
  * Allows users to select a lot and interact with it in many ways

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
├── frontend/                # iOS application
│   ├── Parking/             # Conatains all files related to App
│
├── backend/
│   ├── api/                 # FastAPI backend
│   ├── frame-processing/    # Computer vision pipeline
│   └── workers/             # Background workers
│
├── hardware/
│   ├── notebooks/           # jpynb for drone control hardware
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
3. Drone uploads captured images to server to be processed
4. Frame processing service:

   * Corrects perspective (top-down transformation)
   * Detects vehicles using YOLO
5. System checks overlap between cars and parking spot regions
6. Backend API returns availability data
7. Mobile app displays results

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

## Database:

### Frame processing server

### Requirements

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

### Usage

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

### System Workflow Summary

1. **Load Image & Fetch Cache**: Caches SIFT descriptors of your parking lot master frame.
2. **Align**: Wraps `cv2.findHomography` and `cv2.warpPerspective` to match the exact dimensions/perspective of the master layout.
3. **Detect**: Applies sharpening and contrast filters before grabbing YOLO bounding boxes.
4. **Determine Occupancy**: Evaluates bounding box overlap against standard Spot IDs.
5. **Report**: (Hooks to Cloudflare D1 REST API / iOS Application in parent scopes).

## general parking worker

### Prerequisites
- [Node.js](https://nodejs.org/) (v18+)
- A [Cloudflare](https://dash.cloudflare.com/) account
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/install-and-update/) (`npm i -g wrangler`)

### Installation
```bash
cd general-parking-worker
npm install
```

### Local Development
Start a local dev server with Wrangler:
```bash
npm run dev
```
The worker will be available at `http://localhost:8787`. Local dev uses Wrangler's simulation of D1, R2, Queues, and Secrets Store bindings.

### Generate Types
If you modify bindings in `wrangler.jsonc`, regenerate the TypeScript types:
```bash
npm run cf-typegen
```

### Deployment
Deploy the worker to Cloudflare:
```bash
npm run deploy
```
> **Note:** Ensure you are authenticated with Wrangler (`wrangler login`) and that the D1 database, R2 bucket, Secrets Store secret, and Queue referenced in `wrangler.jsonc` already exist in your Cloudflare account.

### Environment & Bindings
The worker relies on the following bindings configured in `wrangler.jsonc`:

| Binding | Type | Purpose |
|---------|------|---------|
| `DB` | D1 Database | Stores parking lot and space data |
| `r2_parking` | R2 Bucket | Stores uploaded camera frames |
| `SECRET` | Secrets Store | Holds the Bearer token used for authentication |
| `FRAME_JOBS` | Queue (Producer) | Publishes frame-processing jobs for the bridge worker |

### Key Endpoints

| Endpoint | Auth | Description |
|----------|------|-------------|
| `GET /api/health` | No | Health check |
| `GET /api/lot` | No | List all parking lots |
| `GET /api/space` | No | List all parking spaces |
| `GET /api/space/:lot_id` | No | Spaces for a specific lot |
| `POST /api/upload-frame` | No | Upload a camera frame (multipart or binary) and enqueue a processing job |
| `GET /api/get-frame/*` | No | Retrieve a stored frame from R2 |
| `GET /api/list-days` | No | List date-folders in R2 |
| `GET /api/list-frames/:day` | No | List all frames for a given day |
| `GET/POST/PATCH/DELETE /rest/{table}` | **Yes** | Generic CRUD operations on any D1 table |
| `POST /query` | **Yes** | Execute a raw SQL query |
| `POST /batch-query` | **Yes** | Execute multiple SQL queries in a batch |

## Parking bridge worker

### How to Use

### Prerequisites
- [Node.js](https://nodejs.org/) (v18+)
- A [Cloudflare](https://dash.cloudflare.com/) account
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/install-and-update/) (`npm i -g wrangler`)

### Installation
```bash
cd parking-bridge-worker
npm install
```

### Local Development
Start a local dev server with Wrangler:
```bash
npm run dev
```
> **Note:** Queue consumers cannot be triggered locally via HTTP. Use `wrangler dev --remote` or deploy to test queue consumption end-to-end.

### Running Tests
The project uses Vitest with the Cloudflare Workers pool for unit testing:
```bash
npm test
```

### Generate Types
If you modify bindings in `wrangler.jsonc`, regenerate the TypeScript types:
```bash
npm run cf-typegen
```

### Deployment
Deploy the worker to Cloudflare:
```bash
npm run deploy
```
> **Note:** Ensure the `frame-jobs` queue and its dead-letter queue `frame-jobs-dlq` already exist in your Cloudflare account before deploying.

### Environment & Bindings
The worker relies on the following bindings configured in `wrangler.jsonc`:

| Binding | Type | Purpose |
|---------|------|---------|
| `frame-jobs` | Queue (Consumer) | Receives frame-processing job messages |
| `frame-jobs-dlq` | Queue (Dead Letter) | Catches messages that fail all retry attempts |

### Queue Configuration

| Setting | Value | Description |
|---------|-------|-------------|
| `max_batch_size` | 5 | Process up to 5 messages per invocation |
| `max_batch_timeout` | 1 second | Wait up to 1 second to fill a batch |
| `max_retries` | 5 | Retry failed messages up to 5 times |

### Expected Message Format
The worker expects each queue message body to contain:
```json
{
  "key": "frames/05_02_2026/1746200000000-abc12345-frame.jpg",
  "lot_id": "1",
  "uploaded_at": 1746200000000,
  "content_type": "image/jpeg"
}
```
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


