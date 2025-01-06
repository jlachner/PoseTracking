import cv2
import mediapipe as mp
import numpy as np

def draw_right_arm_landmarks(rgb_image, pose_results):
    annotated_image = np.copy(rgb_image)
    
    # Initialize drawing specs
    landmark_drawing_spec = mp.solutions.drawing_utils.DrawingSpec(color=(83, 88, 93), thickness=8, circle_radius=10)
    #connection_drawing_spec = mp.solutions.drawing_utils.DrawingSpec(color=(0,191,255), thickness=8, circle_radius=10) #blue
    connection_drawing_spec = mp.solutions.drawing_utils.DrawingSpec(color=(255, 88, 0), thickness=8, circle_radius=10) #orange
    
    # Right arm connections based on MediaPipe Pose landmark numbering
    right_arm_connections = [
        (12, 14),  # Right shoulder to right elbow
        (14, 16),  # Right elbow to right wrist
    ]
    
    if pose_results.pose_landmarks:
        # Draw each connection
        for connection in right_arm_connections:
            start_idx, end_idx = connection
            start_landmark = pose_results.pose_landmarks.landmark[start_idx]
            end_landmark = pose_results.pose_landmarks.landmark[end_idx]
            cv2.line(annotated_image, 
                     (int(start_landmark.x * annotated_image.shape[1]), int(start_landmark.y * annotated_image.shape[0])), 
                     (int(end_landmark.x * annotated_image.shape[1]), int(end_landmark.y * annotated_image.shape[0])), 
                     connection_drawing_spec.color, connection_drawing_spec.thickness)
        
        # Draw each landmark
        for idx in [11, 12, 14, 16]:  # Right shoulder, elbow, and wrist
            landmark = pose_results.pose_landmarks.landmark[idx]
            cv2.circle(annotated_image, 
                       (int(landmark.x * annotated_image.shape[1]), int(landmark.y * annotated_image.shape[0])), 
                       landmark_drawing_spec.circle_radius, landmark_drawing_spec.color, landmark_drawing_spec.thickness)
    
    return annotated_image


# File paths
input_video_path = '/Users/johanneslachner/Documents/InMotion_Tracking/Input/test/constraint/constraint2.mp4'  # Update this path to your video path
output_video_path = '/Users/johanneslachner/Documents/InMotion_Tracking/Output/test/constraint/constraint2_annotated.mp4'  # Change to AVI format


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
    annotated_image = draw_right_arm_landmarks(image_rgb, pose_results)

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
