// csc.exe /r:System.Windows.Forms.dll /r:System.Drawing.dll CaptureScreen.cs
// .\CaptureScreen.exe > screenshot.b64.txt

using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Windows.Forms;

class Program
{
    static void Main()
    {
        // Capture the entire screen
        Rectangle bounds = Screen.PrimaryScreen.Bounds;
        using (Bitmap bitmap = new Bitmap(bounds.Width, bounds.Height))
        {
            using (Graphics g = Graphics.FromImage(bitmap))
            {
                g.CopyFromScreen(Point.Empty, Point.Empty, bounds.Size);
            }

            // Save to memory stream as PNG
            using (MemoryStream ms = new MemoryStream())
            {
                bitmap.Save(ms, ImageFormat.Png);
                byte[] imageBytes = ms.ToArray();

                // Convert to Base64
                string base64String = Convert.ToBase64String(imageBytes);

                // Output the Base64 string
                Console.WriteLine(base64String);
            }
        }
    }
}
