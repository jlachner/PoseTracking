import numpy as np
import cv2
import glob

# Checkerboard dimensions
CHECKERBOARD = (6,9)  # Adjust based on your checkerboard (corners, not squares)
square_size = 9.6  # Checker size in centimeters

# Termination criteria for corner refinement
criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)

# Prepare object points
objp = np.zeros((CHECKERBOARD[0] * CHECKERBOARD[1], 3), np.float32)
objp[:, :2] = np.mgrid[0:CHECKERBOARD[0], 0:CHECKERBOARD[1]].T.reshape(-1, 2) * square_size

# Arrays to store object points and image points
objpoints = []  # 3d points in real world space
imgpoints = []  # 2d points in image plane

# Capture video -> CHANGE INDEX OF VIDEO!
input_video_path = '/Users/johanneslachner/Documents/GIT_private/PoseTracking/videos/intrinsic_1.mp4' 
cap = cv2.VideoCapture(input_video_path)  # Change to 'video2.mp4' for the second camera

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # Find the chess board corners
    ret, corners = cv2.findChessboardCorners(gray, CHECKERBOARD, None)

    # If found, add object points, image points
    if ret == True:
        objpoints.append(objp)

        corners2 = cv2.cornerSubPix(gray, corners, (11, 11), (-1, -1), criteria)
        imgpoints.append(corners2)

        # Draw and display the corners
        frame = cv2.drawChessboardCorners(frame, CHECKERBOARD, corners2, ret)
        cv2.imshow('Frame', frame)
        cv2.waitKey(1)

# Calibration
ret, mtx, dist, rvecs, tvecs = cv2.calibrateCamera(objpoints, imgpoints, gray.shape[::-1], None, None)

# Save the calibration results -> CHANGE INDEX!
np.savez('calibration_output_camera1.npz', mtx=mtx, dist=dist, rvecs=rvecs, tvecs=tvecs)

cap.release()
cv2.destroyAllWindows()

print("Calibration is done. Camera matrix and distortion coefficients are saved.")
