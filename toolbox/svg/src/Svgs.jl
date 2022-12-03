


include("../../stdlib/trees/MultiTrees.jl")


module Svgs
using ..MultiTrees
using ..Stacks

# stroke = "color" e.g. "green"
# stroke-width = "4"
# fill = "color"
# fill-opacity
# opacity
# style = "whole style semicolon separated ;, name : value"
# style="fill:rgb(0,0,255);stroke-width:3;stroke:rgb(0,0,0)"


# https://www.w3.org/TR/SVG/styling.html#PresentationAttributes


const opening_tag = "<"
const closing_tag = "/>"




function to_string(obj)
    return ""
end

function to_string(obj::T, with_quote = true) where {T <: Number}
    
    str = string(obj)
    if with_quote
        str = '"' * str * '"'
    end

    return str
end

function to_string(obj::T) where {T <: AbstractString}
    return string(obj)
end

function to_string(obj::T) where {T <: AbstractChar}
    return string(obj)
end

function to_string(obj::Vector{T}) where {T <: AbstractChar}
    return String(obj)
end



struct RGB
    r::Int
    g::Int
    b::Int

    function RGB(r::I, g::I, b::I) where {I <: Integer}
        r = convert(Int, r) |> abs
        g = convert(Int, g) |> abs
        b = convert(Int, b) |> abs

        r = r % 256
        g = g % 256
        b = b % 256

        return new(r, g, b)
    end
end

function to_string(obj::RGB)
    return "\"rgb($(obj.r), $(obj.g), $(obj.b))\""
end




struct Stroke
    stroke::Union{RGB, Nothing}
    stroke_width::Union{Float64, Nothing}
    stroke_opacity::Union{Float64, Nothing}

    function Stroke(;
        stroke         = nothing,
        stroke_width   = nothing,
        stroke_opacity = nothing)

        return new(stroke, stroke_width, stroke_opacity)
    end
end

function to_string(obj::Stroke)

    str = ""
    if !isnothing(obj.stroke)
        str = str * " " * "stroke = " * to_string(obj.stroke)
    end
    if !isnothing(obj.stroke_width)
        str = str * " " * "stroke-width = " * to_string(obj.stroke_width)
    end
    if !isnothing(obj.stroke_opacity)
        str = str * " " * "stroke-opacity = " * to_string(obj.stroke_opacity)
    end

    return str
end


struct Fill
    fill::Union{RGB, Nothing}
    fill_opacity::Union{Float64, Nothing}

    function Fill(;
        fill         = nothing,
        fill_opacity = nothing)

        return new(fill, fill_opacity)
    end
end

function to_string(obj::Fill)
    
    str = ""
    if !isnothing(obj.fill)
        str = str * " " * "fill = " * to_string(obj.fill)
    else
        str = str * " " * "fill = \"none\""
    end
    if !isnothing(obj.fill_opacity)
        str = str * " " * "fill-opacity = " * to_string(obj.fill_opacity)
    end

    return str
end







struct Rectangle
    width::Int
    height::Int
    x::Union{Int, Nothing}
    y::Union{Int, Nothing}

    stroke::Stroke
    fill::Fill

    function Rectangle(
        width, height;
        x      = nothing,
        y      = nothing,
        stroke = Stroke(),
        fill   = Fill())
    
        return new(width, height, x, y, stroke, fill)
    end
end

function to_string(obj::Rectangle)

    str_x = isnothing(obj.x) ? "" : " x = " * to_string(obj.x)
    str_y = isnothing(obj.y) ? "" : " y = " * to_string(obj.y)
    
    str = opening_tag * 
        "rect " *
        " width = "   * to_string(obj.width) *
        " height = "  * to_string(obj.height) *
        str_x *
        str_y * 
        to_string(obj.stroke) *
        to_string(obj.fill) *
        closing_tag * "\n"

    return str
end



struct Circle
    cx::Int
    cy::Int
    r::Int

    stroke::Stroke
    fill::Fill

    function Circle(
        cx, cy, r;
        stroke = Stroke(),
        fill   = Fill())

        return new(cx, cy, r, stroke, fill)
    end
end

function to_string(obj::Circle)

    str = opening_tag * 
        "circle " *
        " cx = " * to_string(obj.cx) *
        " cy = " * to_string(obj.cy) *
        " r = "  * to_string(obj.r) *
        to_string(obj.stroke) *
        to_string(obj.fill) *
        closing_tag * "\n"

    return str
end




struct Ellipse
    cx::Int
    cy::Int
    rx::Int
    ry::Int

    stroke::Stroke
    fill::Fill

    function Ellipse(
        cx, cy, rx, ry;
        stroke = Stroke(),
        fill   = Fill())

        return new(cx, cy, rx, ry, stroke, fill)
    end
end

function to_string(obj::Ellipse)

    str = opening_tag * 
        "circle " *
        " cx = " * to_string(obj.cx) *
        " cy = " * to_string(obj.cy) *
        " rx = " * to_string(obj.rx) *
        " ry = " * to_string(obj.ry) *
        to_string(obj.stroke) *
        to_string(obj.fill) *
        closing_tag * "\n"

    return str
end



struct Line
    x1::Int
    y1::Int
    x2::Int
    y2::Int

    stroke::Stroke

    function Line(
        x1, y1, x2, y2;
        stroke = Stroke())

        return new(x1, y1, x2, y2, stroke)
    end
end

function to_string(obj::Line)

    str = opening_tag * 
        "line " *
        " x1 = " * to_string(obj.x1) *
        " y1 = " * to_string(obj.y1) *
        " x2 = " * to_string(obj.x2) *
        " y2 = " * to_string(obj.y2) *
        to_string(obj.stroke) *
        closing_tag * "\n"

    return str
end


function xy_to_string(x_vec::Vector{T}, y_vec::Vector{T}) where {T <: Number}
    n = length(x_vec)

    str = ""
    for ii = 1:n
        x = x_vec[ii]
        y = y_vec[ii]
        
        str *= to_string(x, false) * "," * to_string(y, false) * " "
    end

    return str
end


struct Polygon
    x::Vector{Int}
    y::Vector{Int}
    
    stroke::Stroke
    fill::Fill

    function Polygon(
        x, y;
        stroke = Stroke(),
        fill   = Fill())

        return new(x, y, stroke, fill)
    end
end
# x,y SPACE x,y ...
function to_string(obj::Polygon)

    str = opening_tag * 
        "polygon " *
        "points = " * '"' * xy_to_string(obj.x, obj.y) * '"' * 
        to_string(obj.stroke) *
        to_string(obj.fill) *
        closing_tag * "\n"

    return str
end



struct Polyline
    x::Vector{Int}
    y::Vector{Int}

    stroke::Stroke
    fill::Fill

    function Polyline(
        x, y;
        stroke = Stroke(),
        fill   = Fill())

        return new(x, y, stroke, fill)
    end
end

function to_string(obj::Polyline)

    str = opening_tag * 
        "polyline " *
        "points = " * '"' * xy_to_string(obj.x, obj.y) * '"' * 
        to_string(obj.stroke) *
        to_string(obj.fill) *
        closing_tag * "\n"

    return str
end


# struct Path
# end
# struct Text
# end
# struct Stroking
# end


struct Group
end






# function svg(width, height)
#     svg_global = SVG(width, height)
#     root       = TreeNode(svg_global)
#     return root
# end


struct SvgGlobal
    width::Int
    height::Int

    function SvgGlobal(width = 640, height = 480)
        return new(width, height)
    end
end


struct Svg
    root::MultiTreeNode

    function Svg(width = 640, height = 480)
        data = SvgGlobal(width, height)
        root = MultiTreeNode(data)
        return new(root)
    end
end


function add!(svg::Svg, obj)
    node = MultiTreeNode(obj)

    if !has_left_child(svg.root)
        svg.root.left_child = node
    else
        parent = svg.root.left_child
        while has_right_sibling(parent)
            parent = parent.right_sibling
        end
        parent.right_sibling = node
    end
end








function on_push(obj::SvgGlobal, stack)
    str = opening_tag * 
    "svg " * 
    " width = " * to_string(obj.width) *
    " height = " * to_string(obj.height) *
    ">" * '\n'

    push!(stack, str)
    return nothing
end

function on_push(obj::Group, stack)
    # do nothing for now
    return nothing
end

function on_push(obj, stack)
    str = "\t" * to_string(obj)
    push!(stack, str)
    return nothing
end


function on_visited(obj::SvgGlobal, stack)
    str = "</svg>"
    push!(stack, str)
    return nothing
end

function on_visited(obj::Group, stack)
    # do nothing for now
    str = "</g>"
    push!(stack, str)
    return nothing
end

function on_visited(obj, stack)
    # do nothing for now
    return nothing
end



function to_string(obj::Svg)

    stack                       = Stack{String}(8)
    on_push_with_stack(cont)    = cont.visited ? nothing : on_push(cont.node.data,    stack)
    on_visited_with_stack(cont) = on_visited(cont.node.data, stack)

    dfs(
        obj.root;
        on_push_fcn    = on_push_with_stack,
        on_visited_fcn = on_visited_with_stack)
    
    strings = Stacks.valid_data(stack)
    str     = join(strings, "")
    
    return str
end



end # module






module stest
using ..Svgs



p1  = [0, 28]
p2  = [8, 28]
p3  = [28, 50]
p4  = [50, 8]
p5  = [40, 3]
p6  = [28, 18]
p7  = [8, 18]
p8  = [0, -13]
p9  = [20, -20]
p10 = [13, -50]
p11 = [0, -50]

p12 = [28, 8]
p13 = [13, -5]
p14 = [20, 8]


p17 = [28, 40]
p15 = [28 - 13, 28]
p16 = [28 + 6, 28]

p18 = [0, -30]
p19 = [10, -30]
p20 = [0, -40]

p21 = [0, -47]
p22 = [10, -38]



line_1 = [p1  p2  p3  p4 p9 p10 p11]
line_2 = [p4  p5  p6  p7 p8]
line_3 = [p12 p13 p14 p12]
line_4 = [p15 p16 p17 p15]
line_5 = [p18 p19 p20]
line_6 = [p21 p22]





svg = Svgs.Svg(1500, 1500)


circle = Svgs.Circle(
    50,
    80,
    15;
    stroke = Svgs.Stroke(;stroke = Svgs.RGB(0,0,0))
    )



factor = -5
offset = factor * 50 |> abs

stroke = Svgs.Stroke(stroke = Svgs.RGB(0,0,0), stroke_width = 3)
fill = Svgs.Fill(; fill = Svgs.RGB(0, 0, 0))

polyline_1 = Svgs.Polyline( offset .+ factor * line_1[1,:], offset .+ factor * line_1[2,:]; stroke = stroke)
polyline_2 = Svgs.Polyline( offset .+ factor * line_2[1,:], offset .+ factor * line_2[2,:]; stroke = stroke)
polyline_3 = Svgs.Polyline( offset .+ factor * line_3[1,:], offset .+ factor * line_3[2,:]; stroke = stroke)
polyline_4 = Svgs.Polyline( offset .+ factor * line_4[1,:], offset .+ factor * line_4[2,:]; stroke = stroke)
polyline_5 = Svgs.Polyline( offset .+ factor * line_5[1,:], offset .+ factor * line_5[2,:]; stroke = stroke)
# polyline_6 = Svgs.Polyline( offset .+ factor * line_6[1,:], offset .+ factor * line_6[2,:]; stroke = stroke)


polyline_1b = Svgs.Polyline( offset .- factor * line_1[1,:], offset .+ factor * line_1[2,:]; stroke = stroke)
polyline_2b = Svgs.Polyline( offset .- factor * line_2[1,:], offset .+ factor * line_2[2,:]; stroke = stroke)
polyline_3b = Svgs.Polyline( offset .- factor * line_3[1,:], offset .+ factor * line_3[2,:]; stroke = stroke)
polyline_4b = Svgs.Polyline( offset .- factor * line_4[1,:], offset .+ factor * line_4[2,:]; stroke = stroke)
polyline_5b = Svgs.Polyline( offset .- factor * line_5[1,:], offset .+ factor * line_5[2,:]; stroke = stroke)
# polyline_6b = Svgs.Polyline( offset .- factor * line_6[1,:], offset .+ factor * line_6[2,:]; stroke = stroke)




Svgs.add!(svg, polyline_1)
Svgs.add!(svg, polyline_2)
Svgs.add!(svg, polyline_3)
Svgs.add!(svg, polyline_4)
Svgs.add!(svg, polyline_5)
# Svgs.add!(svg, polyline_6)

Svgs.add!(svg, polyline_1b)
Svgs.add!(svg, polyline_2b)
Svgs.add!(svg, polyline_3b)
Svgs.add!(svg, polyline_4b)
Svgs.add!(svg, polyline_5b)
# Svgs.add!(svg, polyline_6b)




stest.svg |> Svgs.to_string |> println


end


