using Oxygen
using HTTP
include("spiral_generator.jl")

# 1. Serve the Frontend UI
@get "/" function(req::HTTP.Request)
    return HTTP.Response(200, ["Content-Type" => "text/html"], body=read("index.html", String))
end

@post "/generate-spiral" function(req::HTTP.Request)
    multiparts = HTTP.parse_multipart_form(req)
    form_data = Dict(m.name => m for m in multiparts)
    
    # 1. Load and immediately downscale to save RAM
    raw_bytes = read(form_data["image"].data)
    temp_in = tempname() * ".jpg"
    write(temp_in, raw_bytes)
    
    # Force the image to be no larger than 1000px before math starts
    # This reduces RAM usage by 75%
    img = load(temp_in)
    if size(img, 1) > 1000 || size(img, 2) > 1000
        img = imresize(img, ratio=1000/max(size(img)...))
        save(temp_in, img)
    end

    loops = parse(Int, String(read(form_data["loops"].data)))
    max_thickness = parse(Float64, String(read(form_data["max_thickness"].data)))
    
    temp_out = tempname() * ".svg"
    
    # 2. Run the math
    generate_spiral_halftone(temp_in, temp_out; loops=loops, max_thickness=max_thickness)
    
    svg_content = read(temp_out, String)
    
    # 3. CLEANUP: Delete temp files and force Julia to empty the RAM
    rm(temp_in, force=true)
    rm(temp_out, force=true)
    
    # This is the "Nuclear Option" for memory
    GC.gc() 

    return HTTP.Response(200, body=svg_content)
end
# 3. Cloud Configuration
# Render sets a dynamic "PORT" environment variable. If it doesn't exist (like on your local PC), default to 8080.
port = parse(Int, get(ENV, "PORT", "8080"))

println("Starting Vortex Studio server on port $port...")
serve(host="0.0.0.0", port=port)