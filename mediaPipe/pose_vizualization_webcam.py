import cv2
import mediapipe as mp

def draw_landmarks_on_image(rgb_image, pose_results):
    annotated_image = rgb_image.copy()

    # Custom drawing specs for landmarks and connections
    landmark_drawing_spec = mp.solutions.drawing_utils.DrawingSpec( color=(83, 88, 93), thickness=8, circle_radius=10 )
    connection_drawing_spec = mp.solutions.drawing_utils.DrawingSpec( color=(255, 88, 0), thickness=8, circle_radius=10 )

    mp.solutions.drawing_utils.draw_landmarks(
        annotated_image,
        pose_results.pose_landmarks,
        mp.solutions.pose.POSE_CONNECTIONS,
        landmark_drawing_spec,
        connection_drawing_spec)
    return annotated_image



# Initialize MediaPipe Pose.
mp_pose = mp.solutions.pose
pose = mp_pose.Pose( model_complexity=2 )  # Use 2 for heavy, 1 for full, and 0 for light

# Start capturing video input from the camera.
cap = cv2.VideoCapture(0)  # '0' is typically the default camera.

if not cap.isOpened():
    print("Error: Could not open webcam.")
    exit()

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        print("Error: Failed to capture frame.")
        break

    # Convert the frame from BGR to RGB.
    image_rgb = cv2.cvtColor( frame, cv2.COLOR_BGR2RGB )

    # Process the image and detect pose landmarks.
    pose_results = pose.process( image_rgb )

    # Draw landmarks on the original frame.
    annotated_image = draw_landmarks_on_image(frame, pose_results)

    # Display the annotated image.
    cv2.imshow('MediaPipe Pose', annotated_image)

    # Break the loop if 'q' is pressed.
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Release the webcam and close OpenCV window.
cap.release()
cv2.destroyAllWindows()
