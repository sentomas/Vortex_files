using Images
using Luxor


function generate_spiral_halftone(input_path::String, output_path::String; loops::Int=50, max_thickness::Float64=8.0)
    println("Loading image...")
    # 1. Load the image and convert it to grayscale
    # In Julia, Gray.(img) converts pixels to a value between 0.0 (black) and 1.0 (white)
    img = load(input_path)
    img_gray = Gray.(img)
    
    # Get dimensions. For simplicity, we'll base the canvas on the smallest dimension
    # to ensure the spiral fits perfectly within a square crop of the center.
    h, w = size(img_gray)
    canvas_size = min(h, w)
    
    # Calculate the center point for image array mapping
    center_x = w ÷ 2
    center_y = h ÷ 2

    println("Setting up Luxor canvas ($canvas_size x $canvas_size)...")
    # 2. Initialize the Luxor drawing
    Drawing(canvas_size, canvas_size, output_path)
    origin() # Moves the (0,0) coordinate to the dead center of the canvas
    background("white")
    setcolor("black")
    
    # Smooth out the line connections
    setlinecap("round")
    setlinejoin("round")

    # 3. Archimedean Spiral Math Setup (r = a + b * theta)
    # We want the spiral to reach the edge of the canvas at the final loop
    max_radius = canvas_size / 2.0
    max_theta = loops * 2 * π
    b = max_radius / max_theta 
    
    println("Tracing spiral path and sampling pixels...")
    # 4. Tracing the spiral
    theta_step = 0.05 # Determines the resolution/smoothness of the curve
    prev_pt = Point(0, 0)
    
    for theta in 0:theta_step:max_theta
        # Calculate Polar to Cartesian coordinates
        r = b * theta
        x = r * cos(theta)
        y = r * sin(theta)
        
        current_pt = Point(x, y)
        
        # Map Luxor's Cartesian coordinates (where 0,0 is the center) 
        # back to the Image array indices (where 1,1 is the top-left)
        img_x = round(Int, x + center_x)
        img_y = round(Int, y + center_y)
        
        # Ensure our math doesn't ask for a pixel outside the image bounds
        if img_x >= 1 && img_x <= w && img_y >= 1 && img_y <= h
            
            # Sample the pixel brightness
            pixel_brightness = Float64(img_gray[img_y, img_x])
            
            # Calculate line thickness
            # We subtract brightness from 1.0 to invert it: dark pixels (0.0) create thick lines, 
            # light pixels (1.0) create thin lines. We set a minimum thickness of 0.5 so the line doesn't break.
            thickness = max(0.5, max_thickness * (1.0 - pixel_brightness))
            
            setline(thickness)
            
            # Draw the line segment
            # --- WITH THIS ---
            line(prev_pt, current_pt, :stroke)
        end
        
        # Move forward
        prev_pt = current_pt
    end
    
    # 5. Finalize and save the SVG
    finish()
    println("Success! Spiral saved to: $output_path")
end

# ==========================================
# Execution Example
# ==========================================

# Replace "your_image.jpg" with a real image path on your machine.
# generate_spiral_halftone("your_image.jpg", "output.svg", loops=65, max_thickness=9.0)