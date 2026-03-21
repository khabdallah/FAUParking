# FAUParking - Drone Parking Backend

This directory contains the complete backend infrastructure for the Drone Parking Management System. It's composed of computer vision services and serverless data layers that calculate parking spot availability from drone imagery and serve it to the iOS mobile app.

## Architecture

The backend consists of three main services:

### 1. `frame processing server` (Python, OpenCV, Roboflow)
The visual intelligence core that takes raw, skewed drone imagery and analyzes it:
- Unwarps and aligns drone frames to a perfectly top-down coordinate space.
- Implements robust homography fallbacks (SIFT, CLAHE enhancements, ORB).
- Calls fine-tuned YOLO object detection models to locate vehicles.
- Calculates polygon overlap to map which spots are Free vs. Occupied.

*(See `frame processing server/README.md` for python environment and model setup).*

### 2. `general-parking-worker` (Cloudflare D1 REST API)
A high-performance serverless REST API that acts as the database layer for the entire system:
- Exposes standard CRUD operations against the Cloudflare D1 SQL database.
- Stores historical tracking metrics, lot definitions, and live spot statuses.
- Incredibly fast response times (~0.22s, 3x faster than official D1 API wrappers).

*(See `general-parking-worker/README.md` for deployment details and curl examples).*

### 3. `parking-bridge-worker` 
The bridge layer that sits between the Python processing node and the iOS frontend. It allows for securely funneling API updates, potentially bundling batch spot updates or issuing instant status streams down to mobile clients.

## System Flow

1. The simulated (or live) drone captures an image and drops it in the designated pipeline.
2. The `frame processing server` pulls the image, aligns it via keypoints, and detects cars using Roboflow.
3. The spots mapped "Occupied" are compared against previous states.
4. Changed states are pushed to the Cloudflare D1 Database via the worker REST API endpoints.
5. The iOS SwiftUI App calls the worker via HTTP (e.g. `SpotsViewModel.swift`) to pull the latest Free/Occupied statuses and draw the UI.
