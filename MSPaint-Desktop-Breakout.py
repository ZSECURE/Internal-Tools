import argparse
from PIL import Image

# Requirements.txt
# pip install pillow

def string_to_rgb(input_string):
    # Ensure input string length is a multiple of 3 by padding with spaces
    while len(input_string) % 3 != 0:
        input_string += " "

    rgb_values = []

    for i in range(0, len(input_string), 3):
        r = ord(input_string[i+2]) if i+2 < len(input_string) else 0
        g = ord(input_string[i+1]) if i+1 < len(input_string) else 0
        b = ord(input_string[i])
        rgb_values.append((r, g, b))

    return rgb_values

def create_bitmap(rgb_values, output_file):
    # Create a new image with RGB mode and size equal to the number of tuples
    img = Image.new('RGB', (len(rgb_values), 1))
    img.putdata(rgb_values)
    img.save(output_file)

def main():
    parser = argparse.ArgumentParser(description='Convert strings into RGB values based on ASCII equivalents.')
    parser.add_argument('input_string', type=str, help='The string to convert into RGB values.')
    parser.add_argument('--output', type=str, nargs='?', const='output.bmp', help='The output .bmp file.')

    args = parser.parse_args()

    rgb_values = string_to_rgb(args.input_string)

    for rgb in rgb_values:
        print(f'Red({rgb[0]}),Green({rgb[1]}),Blue({rgb[2]})')

    if args.output:
        create_bitmap(rgb_values, args.output)


if __name__ == '__main__':
    main()
