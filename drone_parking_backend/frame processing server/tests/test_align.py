import pytest
import cv2
import numpy as np
from align import align_to_master

def test_align_to_master_synthetic():
    master = np.zeros((200, 200, 3), dtype=np.uint8)
    
    cv2.rectangle(master, (20, 20), (80, 80), (255, 255, 255), -1)
    cv2.circle(master, (150, 50), 20, (200, 100, 50), -1)
    cv2.fillPoly(master, [np.array([[50, 150], [100, 190], [10, 190]])], (100, 255, 100))
    cv2.line(master, (120, 150), (180, 180), (100, 100, 255), 5)

    rows, cols = master.shape[:2]
    M = cv2.getRotationMatrix2D((cols/2, rows/2), 5, 1) 
    M[0, 2] += 10 
    M[1, 2] -= 5  
    
    drone_img = cv2.warpAffine(master, M, (cols, rows))
    
    result = align_to_master(master, drone_img)
    
    assert result["homography"] is not None, "Failed to compute Homography matrix"
    assert result["inliers"] >= 10, "Not enough RANSAC inliers calculated"
    assert result["aligned"].shape == master.shape

def test_align_fail_gracefully():
    master = np.zeros((200, 200, 3), dtype=np.uint8)
    drone_img = np.zeros((200, 200, 3), dtype=np.uint8)

    result = align_to_master(master, drone_img)
    
    assert result["homography"] is None
    assert result["inliers"] < 10
    assert result["aligned"].shape == drone_img.shape
