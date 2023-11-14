import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
from mediapipe import solutions
from mediapipe.framework.formats import landmark_pb2
import numpy as np
import cv2

def draw_landmarks_on_image(rgb_image, detection_result):
    pose_landmarks_list = detection_result.pose_landmarks
    annotated_image = np.copy(rgb_image)

    # Loop through the detected poses to visualize.
    for idx in range(len(pose_landmarks_list)):
        pose_landmarks = pose_landmarks_list[idx]

        # Draw the pose landmarks.
        pose_landmarks_proto = landmark_pb2.NormalizedLandmarkList()
        pose_landmarks_proto.landmark.extend([
            landmark_pb2.NormalizedLandmark(x=landmark.x, y=landmark.y, z=landmark.z) for landmark in pose_landmarks
        ])
        solutions.drawing_utils.draw_landmarks(
            annotated_image,
            pose_landmarks_proto,
            solutions.pose.POSE_CONNECTIONS,
            solutions.drawing_styles.get_default_pose_landmarks_style())
    return annotated_image




# Load the input image from an image file.
image_path = '/Users/johanneslachner/Documents/GIT_private/PoseTracking/images/1_raw.png' 

# Load the image using OpenCV.
image_bgr = cv2.imread(image_path)

# Check if the image is loaded properly
if image_bgr is not None:
    cv2.imshow('Image', image_bgr)
    key = cv2.waitKey(0)              # Wait for a key press to close
    if key == 13:                     # 13 is the Enter key
        cv2.destroyAllWindows()
else:
    print("Error: Image not found or unable to load.")
    exit()

# Convert the image from BGR to RGB format.
image_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)

# Define path to model data
model_path = '/Users/johanneslachner/Documents/GIT_private/PoseTracking/mediaPipe/pose_landmarker_heavy.task'

# Configure the task
BaseOptions = mp.tasks.BaseOptions
PoseLandmarker = mp.tasks.vision.PoseLandmarker
PoseLandmarkerOptions = mp.tasks.vision.PoseLandmarkerOptions
VisionRunningMode = mp.tasks.vision.RunningMode

# Create an PoseLandmarker object.
base_options = python.BaseOptions(model_asset_path=model_path)
options = vision.PoseLandmarkerOptions(
    base_options=base_options,
    output_segmentation_masks=True)
detector = vision.PoseLandmarker.create_from_options(options)

# Detect pose landmarks from the input image.
detection_result = detector.detect(image_rgb)

# Annotate original image and visualize it
annotated_image = draw_landmarks_on_image(image_rgb.numpy_view(), detection_result)
cv2.imshow('Annotated Image', cv2.cvtColor(annotated_image, cv2.COLOR_RGB2BGR))
cv2.waitKey(0)
cv2.destroyAllWindows()
