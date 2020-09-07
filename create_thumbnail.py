import sys
import textwrap

from PIL import Image, ImageDraw, ImageFont

center_x = 1500
center_y = 1700
color = (92,198,255) #5cc6ff

def multiline_title(title):
  splitted = textwrap.wrap(title, width=12)
  return "\n".join(splitted)
  


def main():
  if len(sys.argv) < 5:
    print("usage: %s <source_image> <dest_image> <dest_image_small> <text>")
    exit(2)

  image_source = sys.argv[1]
  image_dest = sys.argv[2]
  small_image_dest = sys.argv[3]
  text = multiline_title(sys.argv[4])

  img = Image.open(image_source)
  img_rgb = img.convert('RGB')
  draw = ImageDraw.Draw(img_rgb)


  # font = ImageFont.truetype(<font-file>, <font-size>)
  font = ImageFont.truetype("font.ttf", 300)
  
  w, h = draw.textsize(text, font=font)
  position = (center_x-w/2, center_y-h/2) 
  
  draw.text(position, text, align="center", fill=color, font=font)
  img_rgb.save(image_dest)

  small_img = img_rgb.resize((480,480), resample=Image.BICUBIC)
  small_img.save(small_image_dest)


if __name__ == "__main__":
    main()
