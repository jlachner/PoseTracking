import cv2

# Define the path to the image
image_path = '/Users/johanneslachner/Documents/GIT_private/PoseTracking/images/1_raw.png' 

# Load the image
image = cv2.imread( image_path )

# Check if the image is loaded properly
if image is not None:
    cv2.imshow( 'Image', image )
    key = cv2.waitKey( 0 )              # Wait for a key press to close
    if key == 13:                       # 13 is the Enter key
        cv2.destroyAllWindows()
else:
    print( "Error: Image not found or unable to load." )
