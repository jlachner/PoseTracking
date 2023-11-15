import mediapipe as mp
import cv2
import numpy as np

def draw_landmarks_on_image( rgb_image, detection_result ):
    annotated_image = np.copy( rgb_image )
    if detection_result.pose_landmarks:
        mp.solutions.drawing_utils.draw_landmarks(
            annotated_image,
            detection_result.pose_landmarks,
            mp.solutions.pose.POSE_CONNECTIONS)
    return annotated_image

# Load the input image from an image file.
image_path = '/Users/johanneslachner/Documents/GIT_private/PoseTracking/images/1_raw.png' 

# Load the image using OpenCV.
image_bgr = cv2.imread( image_path )

# Check if the image is loaded properly
if image_bgr is not None:
    cv2.imshow( 'Image', image_bgr )
    key = cv2.waitKey(0)  # Wait for a key press to close
    if key == 13:         # 13 is the Enter key
        cv2.destroyAllWindows()
else:
    print("Error: Image not found or unable to load.")
    exit()

# OpenCV reads images in BGR
# Convert the image from BGR to RGB format
image_rgb = cv2.cvtColor( image_bgr, cv2.COLOR_BGR2RGB )

# MediaPipe pose processing
mp_pose = mp.solutions.pose
pose = mp_pose.Pose()

# Detect pose landmarks from the input image
# MediaPipe expects RGB
pose_results = pose.process( image_rgb )

# Annotate original image and visualize it
annotated_image = draw_landmarks_on_image( image_rgb, pose_results )
cv2.imshow('Annotated Image', cv2.cvtColor( annotated_image, cv2.COLOR_RGB2BGR ) )
cv2.waitKey(0)
cv2.destroyAllWindows()


