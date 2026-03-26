import pytest
import numpy as np
from detect import preprocess, detect_cars

def test_preprocess_keeps_shape_and_type():
    img = np.random.randint(0, 256, (100, 100, 3), dtype=np.uint8)
    out = preprocess(img)
    
    assert out.shape == (100, 100, 3)
    assert out.dtype == np.uint8

def test_detect_cars_mocked(mocker):
    """
    Mock the Roboflow API response so we test parsing logic 
    without connecting to the internet or spending credits.
    """
    mock_rf = mocker.patch("detect.Roboflow")
    mock_model_instance = mocker.MagicMock()
    
    mock_rf.return_value.workspace.return_value.project.return_value.version.return_value.model = mock_model_instance
    
    mock_pred = mocker.MagicMock()
    mock_pred.json.return_value = {
        "predictions": [
            {
                "x": 50, 
                "y": 50, 
                "width": 20, 
                "height": 20, 
                "confidence": 0.95,
                "class": "car"
            }
        ]
    }
    mock_model_instance.predict.return_value = mock_pred
    
    dummy_img = np.ones((100, 100, 3), dtype=np.uint8) * 100
    boxes = detect_cars(dummy_img, confidence=40, overlap=30, use_preprocess=False)
    
    assert len(boxes) == 1
    x1, y1, x2, y2, conf = boxes[0]
    
    assert x1 == 40
    assert y1 == 40
    assert x2 == 60
    assert y2 == 60
    assert conf == 0.95
