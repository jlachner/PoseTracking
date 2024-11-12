import numpy as np
import cv2
import glob

# Checkerboard dimensions
CHECKERBOARD = (6,9)  # Number of inner corners
square_size = 9.6  # Checker size in centimeters

# Termination criteria for corner refinement: 30 iterations, 0.001 pixels
criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)

# Prepare object points by scaling by square_size
objp = np.zeros((CHECKERBOARD[0] * CHECKERBOARD[1], 3), np.float32)
objp[:, :2] = np.mgrid[0:CHECKERBOARD[0], 0:CHECKERBOARD[1]].T.reshape(-1, 2) * square_size

# Arrays to store object points and image points
objpoints = []  # 3d points in real world space
imgpoints = []  # 2d points in image plane

# Capture video -> Change to 'intrinsic_2.mp4' for the second camera
input_video_path = '/Users/johanneslachner/Documents/GIT_private/PoseTracking/videos/intrinsic_1.mp4' 
cap = cv2.VideoCapture(input_video_path)  

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

# Verify the calibration by undistorting an image
# Read an image from the video or capture a new frame
cap = cv2.VideoCapture(input_video_path)
ret, frame = cap.read()  # Read a single frame

if ret:
    h, w = frame.shape[:2]
    # Compute the optimal new camera matrix
    new_camera_mtx, roi = cv2.getOptimalNewCameraMatrix(mtx, dist, (w, h), 1, (w, h))

    # Undistort the image
    undistorted_frame = cv2.undistort(frame, mtx, dist, None, new_camera_mtx)

    # Crop the image if necessary
    x, y, w, h = roi
    undistorted_frame = undistorted_frame[y:y+h, x:x+w]

    # Display the original and undistorted images
    cv2.imshow('Original Frame', frame)
    cv2.imshow('Undistorted Frame', undistorted_frame)
    cv2.waitKey(0)
    cv2.destroyAllWindows()
else:
    print("Error: Could not read frame from video.")

# Clean-up
cap.release()
cv2.destroyAllWindows()

print("Calibration is done. Camera matrix and distortion coefficients are saved.")
