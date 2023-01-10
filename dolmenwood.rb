#!/usr/bin/env ruby
require 'RMagick'
require 'rtesseract'

pdf_file_name = ARGV[0] || "Dolmenwood Campaign Book 2022-11-28.pdf"
first_page = (ARGV[1] || 173).to_i
second_page = (ARGV[2] || 372).to_i
marker = "angle-down"
titles = []

puts "creating hex markdown files"
(first_page..second_page).each do |i|
  print i
  # convert one pdf page to jpg
  im = Magick::Image.read("#{pdf_file_name}[#{i}]"){|a| a.density = "500x500" }
  image_name = "hexes-page-#{i}.jpg"
  im[0].write(image_name)
  
  # OCR image
  image = RTesseract.new(image_name, lang: 'eng')
  text = image.to_s # Getting the value
  
  # guess hex number
  hex_number = text.split("\n").first(5).select{|l| l.match(/^[0-1][0-9][0-1][0-9]/) }.first || "page #{i}"
  titles << text.split("\n").first 
  
  # markup headers
  text = "# #{text}"
  text.gsub!(/\n\n([A-Za-z0-9\ \(\)\-\'\’]*)\n\n/, '\n\n## \1\n\n')
  
  # markup bold prompts
  text.gsub!(/\n\n([^:]*)(\:.*)\n/, '\n\n**\1**\2\n')
  
  # cleanup mangled line endings
  text.gsub!('\\n', "\n")
  
  # remove page number
  text.gsub!("\n\n#{i-1}\n", "\n\n")
  
  
  # remove line wrap
  text.gsub!("\n\n", "¶¶¶").gsub!("\n", ' ').gsub!("¶¶¶", "\n\n")
  

  # write markdown file
  File.write("./Hexes/Hex #{hex_number}.md", text)
  
  # delete image
  File.delete(image_name) if File.exists? image_name
  print '.'
end


puts "creating map markdown"

x_offset = 0.88
y_offset = -0.6
x_delta = 0.454 # 8.12 ÷ 18
y_delta = -0.523 # -4.65 ÷ 9
even_stagger = y_delta / 2

text = ''
columns = 19
rows = 12
i = 0
(1..19).each do |col|
  col_string = col.to_s.rjust(2, "0")
  x = x_offset + (x_delta * (col-1))
  (1..12).each do |row|
    y = y_offset + (y_delta * (row-1))
    y = y + even_stagger  if col % 2 == 0
    row_string = row.to_s.rjust(2, "0")
    hex_string = "#{col_string}#{row_string}"
    text << "marker: default, #{y}, #{x}, [[Hex #{hex_string}]], #{titles[i]}, 8\n"
    i = i + 1
  end
end
File.write("./Dolmenwood map.md", text)


puts "creating map image"
# Generate map
maps = Magick::ImageList.new
maps.read("#{pdf_file_name}[417]"){|a| a.density = "250x250" }
maps.read("#{pdf_file_name}[418]"){|a| a.density = "250x250" }
maps.append(false).write("Dolmenwood-map.jpg"){|a| a.quality = 70 }