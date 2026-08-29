from PIL import Image

img_path = '/home/hypr/.gemini/antigravity-cli/brain/e9254e3e-2711-43c9-9a09-e847c4cc78ea/.user_uploaded/uploaded_media_1788003636765.png'
out_path = '/home/hypr/dotfiles/hyprland/.config/nvim/anime_header.txt'

img = Image.open(img_path)

# ANSI 24-bit TrueColor Half-Block Converter
width = 76
aspect = img.height / img.width
height = int(width * aspect)
if height % 2 != 0:
    height += 1

resized = img.resize((width, height), Image.Resampling.LANCZOS).convert('RGB')

ansi_lines = []
for y in range(0, height, 2):
    line = ""
    for x in range(width):
        r1, g1, b1 = resized.getpixel((x, y))        # Top pixel (FG)
        r2, g2, b2 = resized.getpixel((x, y + 1))    # Bottom pixel (BG)
        line += f"\033[38;2;{r1};{g1};{b1}m\033[48;2;{r2};{g2};{b2}m▀"
    line += "\033[0m"
    ansi_lines.append(line)

with open(out_path, 'w', encoding='utf-8') as f:
    f.write("\n".join(ansi_lines) + "\n")

print(f"Saved {len(ansi_lines)} ANSI lines to {out_path}")
