import time
import cProfile
import pstats
import io
import os

from visualize_lot import visualize_lot, MASTER_CACHE

def measure_pipeline_latency(lot_id, image_path):
    print(f"\n{'='*50}")
    print(f"PROFILING RUN FOR IMAGE: {image_path}")
    print(f"{'='*50}\n")
    
    print("--- RUN 1: COLD START (Cache Empty) ---")
    start_time = time.time()
    visualize_lot(lot_id, image_path, "profile_output_run1.jpg")
    cold_time = time.time() - start_time
    print(f"-> Total Cold Start Time: {cold_time:.3f}s\n")
    
    print("--- RUN 2: WARM START (Master Keypoints Cached) ---")
    start_time = time.time()
    visualize_lot(lot_id, image_path, "profile_output_run2.jpg")
    warm_time = time.time() - start_time
    print(f"-> Total Warm Start Time: {warm_time:.3f}s\n")
    
    print(f"⏱ CACHE SPEEDUP: {cold_time - warm_time:.3f}s time saved by Master Caching.\n")

def detailed_cprofile(lot_id, image_path):
    print(f"{'='*50}")
    print("RUNNING IN-DEPTH CPROFILE FOR FUNCTION BOTTLENECKS")
    print(f"{'='*50}\n")
    
    pr = cProfile.Profile()
    pr.enable()
    
    visualize_lot(lot_id, image_path, "profile_output_run3.jpg")
    
    pr.disable()
    
    s = io.StringIO()
    sortby = 'tottime' 
    ps = pstats.Stats(pr, stream=s).sort_stats(sortby)
    ps.print_stats(15) 
    print(s.getvalue())
    
    with open("profile_results.txt", "w") as f:
        ps = pstats.Stats(pr, stream=f).sort_stats('cumtime') 
        ps.print_stats()
        
    print(" Full execution trace saved to 'profile_results.txt'")


if __name__ == "__main__":
    if not os.path.exists("test_lot1.png"):
        print("Error: test_lot1.png not found for profiling. Provide a valid image.")
        exit(1)
        
    measure_pipeline_latency("1", "test_lot1.png")
    
    MASTER_CACHE.clear()
    detailed_cprofile("1", "test_lot1.png")
