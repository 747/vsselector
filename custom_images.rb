require 'cairo'

w = 128
h = 128
cx = w / 2
cy = h / 2
rw = w
rh = h
rx = 0
ry = 0
rr = rw / 16
diff = h * 1.0/3
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

    context.fill { context.rounded_rectangle rx, ry, rw, rh, rr }

    context.select_font_face 'Aileron', nil, Cairo::FontWeight::BOLD
    context.set_source_color "#FFFFFF"
    context.set_font_size 48
    unless nx
      ext = context.text_extents n.upcase
      nx = cx - ext.width / 2 - ext.x_bearing
      ny = h * 1.0/3 - ext.height / 2 - ext.y_bearing
    end
    context.move_to nx, ny
    context.show_text n.upcase
    is = n == "tag" ? i == 0x20 ? "\u2423" : i == 0x7F ? "END" : i.chr : i.to_s
    box = is == "\u2423"
    context.select_font_face 'DejaVuSans', nil, Cairo::FontWeight::BOLD if box
    ix = context.text_extents is
    context.move_to cx - ix.width / 2 - ix.x_bearing, ny + diff - (box ? h / 12.0 : 0)
    context.show_text is

    context.show_page
    surface.finish
  end
end

surface = Cairo::SVGSurface.new "public/images/selectors/zwj.svg", w, h
context = Cairo::Context.new surface
context.set_source_color c

context.fill { context.rounded_rectangle rx, ry, rw, rh, rr }

context.select_font_face 'Aileron', nil, Cairo::FontWeight::BOLD
context.set_source_color "#FFFFFF"
context.set_font_size 48
ext = context.text_extents "ZWJ"
context.move_to cx - ext.width / 2 - ext.x_bearing, cy - ext.height / 2 - ext.y_bearing
context.show_text "ZWJ"

context.show_page
surface.finish
