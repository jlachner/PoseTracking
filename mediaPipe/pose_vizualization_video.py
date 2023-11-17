import cv2
import mediapipe as mp
import numpy as np

def draw_landmarks_on_image(rgb_image, pose_results):
    annotated_image = np.copy(rgb_image)
    
    # Custom drawing specs for landmarks and connections
    landmark_drawing_spec = mp.solutions.drawing_utils.DrawingSpec(color=(83, 88, 93), thickness=8, circle_radius=10)
    connection_drawing_spec = mp.solutions.drawing_utils.DrawingSpec(color=(255, 88, 0), thickness=8, circle_radius=10)

    mp.solutions.drawing_utils.draw_landmarks(
        annotated_image,
        pose_results.pose_landmarks,
        mp.solutions.pose.POSE_CONNECTIONS,
        landmark_drawing_spec,
        connection_drawing_spec)
    return annotated_image

# File paths
input_video_path = '/Users/johanneslachner/Documents/GIT_private/PoseTracking/images/2_raw.mp4'  # Update this path to your video path
output_video_path = '/Users/johanneslachner/Documents/GIT_private/PoseTracking/images/2_annotated.mp4'  # Change to AVI format


# Initialize MediaPipe Pose.
mp_pose = mp.solutions.pose
pose = mp_pose.Pose( model_complexity=2, min_detection_confidence=0.5, min_tracking_confidence=0.5 )

# Initialize video capture and writer
cap = cv2.VideoCapture(input_video_path)

# Video writer
fourcc = cv2.VideoWriter_fourcc( *'mp4v' )  # or 'XVID'
fps = cap.get(cv2.CAP_PROP_FPS)
frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
out = cv2.VideoWriter(output_video_path, fourcc, fps, (frame_width, frame_height))

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    # Convert the frame from BGR to RGB
    image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    # Process the frame
    pose_results = pose.process(image_rgb)

    # Draw the pose annotation on the frame
    annotated_image = draw_landmarks_on_image(image_rgb, pose_results)

    # Convert back to BGR for displaying and writing
    annotated_image_bgr = cv2.cvtColor(annotated_image, cv2.COLOR_RGB2BGR)

    # Display the frame
    cv2.imshow('MediaPipe Pose', annotated_image_bgr)

    # Write the frame
    out.write(annotated_image_bgr)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Release everything
cap.release()
out.release()
cv2.destroyAllWindows()
