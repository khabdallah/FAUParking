import pytest
import numpy as np
from occupancy import check_occupancy

def test_check_occupancy_basic():
    test_polygon = np.array([[100, 100], [200, 100], [200, 200], [100, 200]], np.int32)
    parking_data = [
        (test_polygon, "A1"),
    ]
    boxes = [(120, 120, 180, 180, 0.95)] 
    result = check_occupancy(boxes, parking_data, overlap_threshold=0.3)
    
    assert len(result["occupied"]) == 1
    assert result["occupied"][0]["id"] == "A1"
    assert result["occupied"][0]["confidence"] == 0.95
    assert len(result["free"]) == 0

def test_check_occupancy_threshold():
    test_polygon = np.array([[0, 0], [100, 0], [100, 100], [0, 100]], np.int32)
    parking_data = [(test_polygon, "SPOT1")]
    
    boxes_under = [(0, 0, 50, 50, 0.8)] 
    res1 = check_occupancy(boxes_under, parking_data, overlap_threshold=0.3)
    assert len(res1["occupied"]) == 0
    assert len(res1["free"]) == 1
    
    boxes_over = [(0, 0, 60, 60, 0.8)]
    res2 = check_occupancy(boxes_over, parking_data, overlap_threshold=0.3)
    assert len(res2["occupied"]) == 1
    assert len(res2["free"]) == 0

def test_multi_spot_overlap():
    p1 = np.array([[0, 0], [100, 0], [100, 100], [0, 100]], np.int32)
    p2 = np.array([[100, 0], [200, 0], [200, 100], [100, 100]], np.int32)
    parking_data = [(p1, "S1"), (p2, "S2")]
    
    boxes = [(50, 0, 150, 100, 0.9)]
    res = check_occupancy(boxes, parking_data, overlap_threshold=0.3)
    
    assert len(res["occupied"]) == 2
    ids = [d["id"] for d in res["occupied"]]
    assert "S1" in ids
    assert "S2" in ids

def test_zero_area_box_or_polygon():
    test_polygon = np.array([[0, 0], [0, 0], [0, 0], [0, 0]], np.int32)
    parking_data = [(test_polygon, "BAD_SPOT")]
    boxes = [(0, 0, 50, 50, 0.9)]
    res = check_occupancy(boxes, parking_data, overlap_threshold=0.3)
    
    assert len(res["occupied"]) == 0
    assert len(res["free"]) == 1
