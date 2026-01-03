#!/usr/bin/env python3
"""
VGA Stream Viewer - Displays real-time VGA simulation stream
Reads raw RGB pixel data from stdin
"""

import sys
import struct
import time

try:
    import pygame
except ImportError:
    print("ERROR: pygame not installed", file=sys.stderr)
    print("Install with: pip install pygame", file=sys.stderr)
    sys.exit(1)

# VGA resolution
WIDTH = 640
HEIGHT = 480

class VGAStreamViewer:
    def __init__(self, scale=1):
        self.scale = scale
        self.width = WIDTH * scale
        self.height = HEIGHT * scale

        pygame.init()
        self.screen = pygame.display.set_mode((self.width, self.height))
        pygame.display.set_caption("VGA Stream Viewer")
        self.clock = pygame.time.Clock()
        self.running = True

        # Frame buffer
        self.surface = pygame.Surface((WIDTH, HEIGHT))

        # Statistics
        self.frame_count = 0
        self.fps = 0
        self.last_time = time.time()
        self.bytes_received = 0

    def draw_overlay(self):
        """Draw status overlay on screen"""
        font = pygame.font.Font(None, 24)

        # Background for text
        overlay = pygame.Surface((250, 80))
        overlay.set_alpha(200)
        overlay.fill((0, 0, 0))
        self.screen.blit(overlay, (5, 5))

        # Draw text
        texts = [
            f"Frame: {self.frame_count}",
            f"FPS: {self.fps:.1f}",
            f"Data: {self.bytes_received / 1024 / 1024:.1f} MB"
        ]

        for i, text in enumerate(texts):
            text_surface = font.render(text, True, (0, 255, 0))
            self.screen.blit(text_surface, (10, 10 + i * 25))

    def read_frame(self):
        """Read one frame of RGB data from stdin"""
        pixels_needed = WIDTH * HEIGHT * 3  # 3 bytes per pixel (RGB)
        data = sys.stdin.buffer.read(pixels_needed)

        if len(data) != pixels_needed:
            return False

        self.bytes_received += len(data)

        # Convert bytes to surface
        for y in range(HEIGHT):
            for x in range(WIDTH):
                idx = (y * WIDTH + x) * 3
                r = data[idx]
                g = data[idx + 1]
                b = data[idx + 2]
                self.surface.set_at((x, y), (r, g, b))

        return True

    def update_display(self):
        """Update the display with current frame"""
        # Scale surface if needed
        if self.scale != 1:
            scaled = pygame.transform.scale(self.surface, (self.width, self.height))
            self.screen.blit(scaled, (0, 0))
        else:
            self.screen.blit(self.surface, (0, 0))

        # Draw overlay
        self.draw_overlay()

        pygame.display.flip()

        # Update FPS
        current_time = time.time()
        frame_time = current_time - self.last_time
        if frame_time > 0:
            self.fps = 1.0 / frame_time
        self.last_time = current_time

        self.frame_count += 1

    def run(self):
        """Main streaming loop"""
        print("VGA Stream Viewer Started", file=sys.stderr)
        print("Reading from stdin...", file=sys.stderr)
        print("Press ESC or close window to exit", file=sys.stderr)

        try:
            while self.running:
                # Handle events
                for event in pygame.event.get():
                    if event.type == pygame.QUIT:
                        self.running = False
                    elif event.type == pygame.KEYDOWN:
                        if event.key == pygame.K_ESCAPE:
                            self.running = False
                        elif event.key == pygame.K_f:
                            # Toggle fullscreen
                            pygame.display.toggle_fullscreen()

                # Read and display frame
                if self.read_frame():
                    self.update_display()
                    self.clock.tick(60)  # Limit to 60 FPS
                else:
                    # End of stream
                    print("\nStream ended", file=sys.stderr)
                    break

        except KeyboardInterrupt:
            print("\nInterrupted by user", file=sys.stderr)
        except Exception as e:
            print(f"\nError: {e}", file=sys.stderr)
        finally:
            pygame.quit()
            print(f"Total frames: {self.frame_count}", file=sys.stderr)
            print(f"Average FPS: {self.fps:.1f}", file=sys.stderr)

def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='VGA Stream Viewer - reads raw RGB data from stdin')
    parser.add_argument('--scale', type=int, default=1,
                       help='Display scale factor (default: 1)')

    args = parser.parse_args()

    # Make stdin binary and unbuffered
    sys.stdin.reconfigure(encoding=None)

    viewer = VGAStreamViewer(scale=args.scale)
    viewer.run()

if __name__ == '__main__':
    main()
