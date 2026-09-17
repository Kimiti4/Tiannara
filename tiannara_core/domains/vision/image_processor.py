"""
Image Processor - Image loading, preprocessing, and basic operations
"""

import numpy as np
from typing import Union, List, Tuple
from pathlib import Path
import httpx


class ImageProcessor:
    """Handle image loading, preprocessing, and basic CV operations"""
    
    def __init__(self):
        self.supported_formats = ['.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp']
    
    def load_image(self, image_path: Union[str, Path]) -> np.ndarray:
        """
        Load image from file path.
        
        Args:
            image_path: Path to image file
            
        Returns:
            NumPy array (H, W, C) in RGB format
        """
        try:
            from PIL import Image
        except ImportError:
            raise ImportError("PIL/Pillow is required. Install with: pip install Pillow")
        
        image_path = Path(image_path)
        
        if not image_path.exists():
            raise FileNotFoundError(f"Image not found: {image_path}")
        
        if image_path.suffix.lower() not in self.supported_formats:
            raise ValueError(f"Unsupported format: {image_path.suffix}")
        
        # Load image
        img = Image.open(image_path)
        
        # Convert to RGB
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Convert to numpy array
        return np.array(img)
    
    async def download_image(self, url: str) -> np.ndarray:
        """
        Download image from URL.
        
        Args:
            url: Image URL
            
        Returns:
            NumPy array (H, W, C) in RGB format
        """
        try:
            from PIL import Image
            import io
        except ImportError:
            raise ImportError("PIL/Pillow is required. Install with: pip install Pillow")
        
        async with httpx.AsyncClient() as client:
            response = await client.get(url)
            response.raise_for_status()
            
            # Load from bytes
            img = Image.open(io.BytesIO(response.content))
            
            if img.mode != 'RGB':
                img = img.convert('RGB')
            
            return np.array(img)
    
    def save_temporary(self, image_data: np.ndarray, prefix: str = "tiannara_") -> str:
        """
        Save image to temporary file.
        
        Args:
            image_data: NumPy array
            prefix: Filename prefix
            
        Returns:
            Path to temporary file
        """
        try:
            from PIL import Image
            import tempfile
        except ImportError:
            raise ImportError("PIL/Pillow is required")
        
        # Create temp file
        temp_file = tempfile.NamedTemporaryFile(
            suffix='.jpg',
            prefix=prefix,
            delete=False
        )
        temp_path = temp_file.name
        temp_file.close()
        
        # Save image
        img = Image.fromarray(image_data)
        img.save(temp_path, 'JPEG')
        
        return temp_path
    
    def extract_dominant_colors(
        self,
        image_data: np.ndarray,
        n_colors: int = 5
    ) -> List[str]:
        """
        Extract dominant colors from image using k-means clustering.
        
        Args:
            image_data: NumPy array (H, W, C)
            n_colors: Number of dominant colors
            
        Returns:
            List of hex color strings
        """
        try:
            from sklearn.cluster import KMeans
        except ImportError:
            # Fallback: simple color sampling
            return self._simple_color_sampling(image_data, n_colors)
        
        # Reshape image to list of pixels
        pixels = image_data.reshape(-1, 3)
        
        # Sample for performance
        if len(pixels) > 10000:
            indices = np.random.choice(len(pixels), 10000, replace=False)
            pixels_sample = pixels[indices]
        else:
            pixels_sample = pixels
        
        # K-means clustering
        kmeans = KMeans(n_clusters=n_colors, random_state=42, n_init=10)
        kmeans.fit(pixels_sample)
        
        # Get cluster centers (dominant colors)
        colors_rgb = kmeans.cluster_centers_.astype(int)
        
        # Convert to hex
        return [self._rgb_to_hex(tuple(color)) for color in colors_rgb]
    
    def resize_image(
        self,
        image_data: np.ndarray,
        width: Optional[int] = None,
        height: Optional[int] = None,
        maintain_aspect: bool = True
    ) -> np.ndarray:
        """
        Resize image.
        
        Args:
            image_data: NumPy array
            width: Target width
            height: Target height
            maintain_aspect: Maintain aspect ratio
            
        Returns:
            Resized image array
        """
        try:
            from PIL import Image
        except ImportError:
            raise ImportError("PIL/Pillow is required")
        
        img = Image.fromarray(image_data)
        
        if maintain_aspect:
            # Calculate dimensions maintaining aspect ratio
            orig_width, orig_height = img.size
            
            if width and not height:
                ratio = width / orig_width
                height = int(orig_height * ratio)
            elif height and not width:
                ratio = height / orig_height
                width = int(orig_width * ratio)
            elif width and height:
                # Fit within box
                ratio_w = width / orig_width
                ratio_h = height / orig_height
                ratio = min(ratio_w, ratio_h)
                width = int(orig_width * ratio)
                height = int(orig_height * ratio)
        
        img_resized = img.resize((width or img.width, height or img.height), Image.LANCZOS)
        
        return np.array(img_resized)
    
    def normalize_image(
        self,
        image_data: np.ndarray,
        mean: List[float] = [0.485, 0.456, 0.406],
        std: List[float] = [0.229, 0.224, 0.225]
    ) -> np.ndarray:
        """
        Normalize image for model input.
        
        Args:
            image_data: NumPy array (H, W, C) in range [0, 255]
            mean: Normalization mean per channel
            std: Normalization std per channel
            
        Returns:
            Normalized array
        """
        # Convert to float and scale to [0, 1]
        normalized = image_data.astype(np.float32) / 255.0
        
        # Apply normalization
        for i in range(3):
            normalized[:, :, i] = (normalized[:, :, i] - mean[i]) / std[i]
        
        return normalized
    
    # Private methods
    
    def _simple_color_sampling(
        self,
        image_data: np.ndarray,
        n_colors: int
    ) -> List[str]:
        """Simple color extraction without sklearn"""
        # Sample pixels from corners and center
        h, w = image_data.shape[:2]
        
        sample_points = [
            (0, 0),  # Top-left
            (0, w-1),  # Top-right
            (h-1, 0),  # Bottom-left
            (h-1, w-1),  # Bottom-right
            (h//2, w//2),  # Center
        ]
        
        colors = []
        for y, x in sample_points[:n_colors]:
            rgb = tuple(image_data[y, x].astype(int))
            colors.append(self._rgb_to_hex(rgb))
        
        return colors
    
    @staticmethod
    def _rgb_to_hex(rgb: Tuple[int, int, int]) -> str:
        """Convert RGB tuple to hex string"""
        return '#{:02x}{:02x}{:02x}'.format(
            max(0, min(255, rgb[0])),
            max(0, min(255, rgb[1])),
            max(0, min(255, rgb[2]))
        )
