require 'cairo'

w = 128
h = 128
cx = w / 2
cy = h / 2
rw = w * 0.9
rh = h * 0.9
rx = cx - rw / 2
ry = cy - rh / 2
rr = rw / 16
diff = h * (1.0/3 - 1.0/20)
c = "#321760"

set = {
  "fvs" => (1..3).to_a,
  "vs"  => (1..256).to_a,
  "tag" => (0x20..0x7F).to_a,
}

set.each do |n, ent|
  nx = nil
  ny = nil

  ent.each do |i|
    surface = Cairo::SVGSurface.new "public/images/selectors/#{n}-#{i}.svg", w, h
    context = Cairo::Context.new surface
    context.set_source_color c

    context.stroke { context.rounded_rectangle rx, ry, rw, rh, rr }

    context.select_font_face 'Aileron', nil, Cairo::FontWeight::BOLD
    context.set_font_size 40
    unless nx
      ext = context.text_extents n.upcase
      nx = cx - ext.width / 2 - ext.x_bearing
      ny = h * (1.0/3 + 1.0/40) - ext.height / 2 - ext.y_bearing
    end
    context.move_to nx, ny
    context.show_text n.upcase
    is = n == "tag" ? i == 0x20 ? "\u2423" : i == 0x7F ? "END" : i.chr : i.to_s
    ix = context.text_extents is
    context.move_to cx - ix.width / 2 - ix.x_bearing, ny + diff
    context.show_text is

    context.show_page
    surface.finish
  end
end

surface = Cairo::SVGSurface.new "public/images/selectors/zwj.svg", w, h
context = Cairo::Context.new surface
context.set_source_color c

context.stroke { context.rounded_rectangle rx, ry, rw, rh, rr }

context.select_font_face 'Aileron', nil, Cairo::FontWeight::BOLD
context.set_font_size 40
ext = context.text_extents "ZWJ"
context.move_to cx - ext.width / 2 - ext.x_bearing, cy - ext.height / 2 - ext.y_bearing
context.show_text "ZWJ"

context.show_page
surface.finish
