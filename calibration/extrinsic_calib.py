import cv2
import numpy as np

# Load intrinsic parameters
calib_file_path_1 = '/Users/johanneslachner/Documents/GIT_private/PoseTracking/calibration/calibration_output_camera1.npz'
calib_file_path_2 = '/Users/johanneslachner/Documents/GIT_private/PoseTracking/calibration/calibration_output_camera2.npz'
with np.load(calib_file_path_1) as X:
    mtx1, dist1 = [X[i] for i in ('mtx', 'dist')]
with np.load(calib_file_path_2) as X:
    mtx2, dist2 = [X[i] for i in ('mtx', 'dist')]

# Checkerboard dimensions
CHECKERBOARD = (6, 9)  # Adjust based on your checkerboard
square_size = 9.6  # Checker size in centimeters

# Termination criteria for corner refinement
criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)

# Prepare object points
objp = np.zeros((CHECKERBOARD[0] * CHECKERBOARD[1], 3), np.float32)
objp[:, :2] = np.mgrid[0:CHECKERBOARD[0], 0:CHECKERBOARD[1]].T.reshape(-1, 2) * square_size

# Arrays to store object points and image points from all images
objpoints = []  # 3d points in real world space
imgpoints1 = []  # 2d points in image plane from camera 1
imgpoints2 = []  # 2d points in image plane from camera 2

# Open both videos
input_video_path_1 = '/Users/johanneslachner/Documents/GIT_private/PoseTracking/videos/extrinsic_1.mp4' 
input_video_path_2 = '/Users/johanneslachner/Documents/GIT_private/PoseTracking/videos/extrinsic_2.mp4' 
cap1 = cv2.VideoCapture(input_video_path_1)
cap2 = cv2.VideoCapture(input_video_path_2)

while True:
    # Read frames from both videos
    ret1, frame1 = cap1.read()
    ret2, frame2 = cap2.read()

    # Break out of the loop if at least one frame is not read correctly
    if not ret1 or not ret2:
        break

    gray1 = cv2.cvtColor(frame1, cv2.COLOR_BGR2GRAY)
    gray2 = cv2.cvtColor(frame2, cv2.COLOR_BGR2GRAY)

    # Find the chess board corners
    ret1, corners1 = cv2.findChessboardCorners(gray1, CHECKERBOARD, None)
    ret2, corners2 = cv2.findChessboardCorners(gray2, CHECKERBOARD, None)

    # If found in both images, add object points, image points
    if ret1 and ret2:
        objpoints.append(objp)

        # Refining pixel coordinates for given 2d points.
        corners1 = cv2.cornerSubPix(gray1, corners1, (11, 11), (-1, -1), criteria)
        imgpoints1.append(corners1)

        corners2 = cv2.cornerSubPix(gray2, corners2, (11, 11), (-1, -1), criteria)
        imgpoints2.append(corners2)

# Extrinsic calibration
retval, cameraMatrix1, distCoeffs1, cameraMatrix2, distCoeffs2, R, T, E, F = cv2.stereoCalibrate(
    objpoints, imgpoints1, imgpoints2, mtx1, dist1, mtx2, dist2, gray1.shape[::-1],
    criteria=criteria, flags=cv2.CALIB_FIX_INTRINSIC
)

# Print rotation and translation matrices
print("Rotation Matrix (R):\n", R)
print("Translation Vector (T):\n", T)

# Save the extrinsic parameters
np.savez('extrinsic_params.npz', R=R, T=T, E=E, F=F)

# Stereo Rectification
R1, R2, P1, P2, Q, _, _ = cv2.stereoRectify(
    mtx1, dist1, mtx2, dist2, gray1.shape[::-1], R, T, alpha=1
)
np.savez('stereo_rectify_params.npz', R1=R1, R2=R2, P1=P1, P2=P2, Q=Q)

# Display rectified images (Optional, for verification)
map1_x, map1_y = cv2.initUndistortRectifyMap(mtx1, dist1, R1, P1, gray1.shape[::-1], cv2.CV_32FC1)
map2_x, map2_y = cv2.initUndistortRectifyMap(mtx2, dist2, R2, P2, gray2.shape[::-1], cv2.CV_32FC1)

cap1 = cv2.VideoCapture(input_video_path_1)
cap2 = cv2.VideoCapture(input_video_path_2)

while True:
    ret1, frame1 = cap1.read()
    ret2, frame2 = cap2.read()
    
    if not ret1 or not ret2:
        break
    
    rectified1 = cv2.remap(frame1, map1_x, map1_y, cv2.INTER_LINEAR)
    rectified2 = cv2.remap(frame2, map2_x, map2_y, cv2.INTER_LINEAR)

    cv2.imshow('Rectified Camera 1', rectified1)
    cv2.imshow('Rectified Camera 2', rectified2)
    
    # Press ‘q’ to close the rectified video windows
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap1.release()
cap2.release()
cv2.destroyAllWindows()

# Verification: Calculate and print reprojection error
total_error = 0
for i in range(len(objpoints)):
    imgpoints1_proj, _ = cv2.projectPoints(objpoints[i], R, T, mtx1, dist1)
    imgpoints2_proj, _ = cv2.projectPoints(objpoints[i], np.eye(3), np.zeros((3, 1)), mtx2, dist2)
    error1 = cv2.norm(imgpoints1[i], imgpoints1_proj, cv2.NORM_L2) / len(imgpoints1_proj)
    error2 = cv2.norm(imgpoints2[i], imgpoints2_proj, cv2.NORM_L2) / len(imgpoints2_proj)
    total_error += error1 + error2
print("Reprojection Error:", total_error / len(objpoints)) # Goal: reprojection error < 0.5 pixels