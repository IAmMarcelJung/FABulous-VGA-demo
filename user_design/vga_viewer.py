#!/usr/bin/env python3
"""
VGA Live Viewer - Displays VGA simulation output in real-time
Monitors PPM files and updates display as simulation runs
"""

import sys
import time
import os
from pathlib import Path

try:
    import pygame
except ImportError:
    print("ERROR: pygame not installed")
    print("Install with: pip install pygame")
    sys.exit(1)

# VGA resolution
WIDTH = 640
HEIGHT = 480
SCALE = 1  # Scale factor for display

class VGAViewer:
    def __init__(self, scale=1):
        self.scale = scale
        self.width = WIDTH * scale
        self.height = HEIGHT * scale

        pygame.init()
        self.screen = pygame.display.set_mode((self.width, self.height))
        pygame.display.set_caption("VGA Live Viewer")
        self.clock = pygame.time.Clock()
        self.running = True
        self.frame_count = 0
        self.last_frame_time = 0
        self.fps = 0

    def load_ppm(self, filename):
        """Load a PPM P3 (ASCII) file and return pygame surface"""
        try:
            with open(filename, 'r') as f:
                # Read header
                magic = f.readline().strip()
                if magic != 'P3':
                    return None

                # Skip comments
                line = f.readline().strip()
                while line.startswith('#'):
                    line = f.readline().strip()

                # Read dimensions
                width, height = map(int, line.split())
                maxval = int(f.readline().strip())

                # Create surface
                surface = pygame.Surface((width, height))

                # Read pixel data
                pixels = []
                for line in f:
                    pixels.extend(map(int, line.split()))

                # Fill surface
                for y in range(height):
                    for x in range(width):
                        idx = (y * width + x) * 3
                        if idx + 2 < len(pixels):
                            r = pixels[idx]
                            g = pixels[idx + 1]
                            b = pixels[idx + 2]
                            surface.set_at((x, y), (r, g, b))

                return surface

        except (FileNotFoundError, ValueError, IndexError) as e:
            return None

    def draw_text(self, text, x, y, color=(255, 255, 0)):
        """Draw text on screen"""
        font = pygame.font.Font(None, 24)
        text_surface = font.render(text, True, color)
        self.screen.blit(text_surface, (x, y))

    def update_display(self, filename):
        """Load and display a frame"""
        surface = self.load_ppm(filename)
        if surface:
            # Scale if needed
            if self.scale != 1:
                surface = pygame.transform.scale(surface, (self.width, self.height))

            self.screen.blit(surface, (0, 0))

            # Draw overlay info
            current_time = time.time()
            if self.last_frame_time > 0:
                frame_time = current_time - self.last_frame_time
                if frame_time > 0:
                    self.fps = 1.0 / frame_time
            self.last_frame_time = current_time

            self.draw_text(f"Frame: {self.frame_count}", 10, 10)
            self.draw_text(f"FPS: {self.fps:.1f}", 10, 35)

            pygame.display.flip()
            self.frame_count += 1
            return True
        return False

    def run_live(self):
        """Monitor for new frames and display them"""
        print("VGA Live Viewer Started")
        print("Waiting for frames...")
        print("Press ESC or close window to exit")

        last_mtime = {}
        frame_files = ["frame_0.ppm", "frame_1.ppm", "frame_2.ppm"]
        current_frame = 0

        while self.running:
            # Handle events
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        self.running = False
                    elif event.key == pygame.K_SPACE:
                        # Pause/unpause
                        print("Paused - press SPACE to continue")
                        waiting = True
                        while waiting:
                            for e in pygame.event.get():
                                if e.type == pygame.KEYDOWN and e.key == pygame.K_SPACE:
                                    waiting = False
                                elif e.type == pygame.QUIT:
                                    self.running = False
                                    waiting = False

            # Check for updated frames in rotation
            filename = frame_files[current_frame % len(frame_files)]

            if os.path.exists(filename):
                mtime = os.path.getmtime(filename)
                if filename not in last_mtime or mtime > last_mtime[filename]:
                    if self.update_display(filename):
                        last_mtime[filename] = mtime
                        print(f"Displayed {filename}")
                    current_frame += 1

            self.clock.tick(60)  # 60 FPS max
            time.sleep(0.01)  # Small delay to not consume too much CPU

        pygame.quit()

    def display_single(self, filename):
        """Display a single frame and wait for user to close"""
        print(f"Displaying {filename}")
        print("Press ESC or close window to exit")

        if not self.update_display(filename):
            print(f"ERROR: Could not load {filename}")
            return

        while self.running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        self.running = False

            self.clock.tick(30)

        pygame.quit()

def main():
    import argparse

    parser = argparse.ArgumentParser(description='VGA Live Viewer')
    parser.add_argument('--live', action='store_true',
                       help='Live monitoring mode (watches for new frames)')
    parser.add_argument('--file', type=str,
                       help='Display single frame file')
    parser.add_argument('--scale', type=int, default=1,
                       help='Display scale factor (default: 1)')

    args = parser.parse_args()

    viewer = VGAViewer(scale=args.scale)

    if args.live:
        viewer.run_live()
    elif args.file:
        viewer.display_single(args.file)
    else:
        # Default: try to display frame_0.ppm if it exists
        if os.path.exists('frame_0.ppm'):
            viewer.display_single('frame_0.ppm')
        else:
            print("No frame file specified. Use --live or --file")
            print("Usage:")
            print("  python vga_viewer.py --live          # Live monitoring")
            print("  python vga_viewer.py --file frame_0.ppm  # Single frame")

if __name__ == '__main__':
    main()
