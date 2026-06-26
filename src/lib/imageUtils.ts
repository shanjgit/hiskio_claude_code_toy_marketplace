/**
 * Resizes an image to the specified dimensions using the Canvas API
 * @param file The image file to resize
 * @param maxWidth The maximum width of the resized image
 * @param maxHeight The maximum height of the resized image
 * @returns A promise that resolves to a new File object containing the resized image
 */
export async function resizeImage(
  file: File,
  maxWidth: number = 400,
  maxHeight: number = 400
): Promise<File> {
  return new Promise((resolve, reject) => {
    // Create an image element
    const img = new Image();
    img.onload = () => {
      // Calculate new dimensions while maintaining aspect ratio
      let width = img.width;
      let height = img.height;
      
      // Determine the scaling factor to fit within maxWidth and maxHeight
      // while maintaining aspect ratio
      if (width > height) {
        if (width > maxWidth) {
          height = Math.round(height * (maxWidth / width));
          width = maxWidth;
        }
      } else {
        if (height > maxHeight) {
          width = Math.round(width * (maxHeight / height));
          height = maxHeight;
        }
      }
      
      // Create a canvas element and draw the resized image
      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      
      const ctx = canvas.getContext('2d');
      if (!ctx) {
        reject(new Error('Could not get canvas context'));
        return;
      }
      
      // Draw the image on the canvas
      ctx.drawImage(img, 0, 0, width, height);
      
      // Always convert to JPEG so any input format (HEIC, WebP, BMP, etc.)
      // produces a universally supported output that Canvas can encode.
      const outputType = 'image/jpeg';
      const outputName = file.name.replace(/\.[^.]+$/, '.jpg');

      canvas.toBlob(
        (blob) => {
          if (!blob) {
            reject(new Error('Canvas toBlob failed'));
            return;
          }

          const resizedFile = new File([blob], outputName, {
            type: outputType,
            lastModified: Date.now(),
          });

          resolve(resizedFile);
        },
        outputType,
        0.9
      );
    };
    
    img.onerror = () => {
      reject(new Error('Failed to load image'));
    };
    
    // Load the image from the File object
    img.src = URL.createObjectURL(file);
  });
}
