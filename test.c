#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <limits.h>
#include <linux/limits.h>

#define MAX_HEADER_SIZE 512

typedef struct PixelNode
{
    unsigned char Red;
    unsigned char Green;
    unsigned char Blue;
    unsigned char CdfValue;
    struct PixelNode *up;
    struct PixelNode *down;
    struct PixelNode *left;
    struct PixelNode *right;
} PixelNode;

int width, height;

extern PixelNode *readPPM(const char *filename);
extern void computeCDFValues(PixelNode *head);
extern void applyHistogramEqualization(PixelNode* head);
extern void writePPM(const char *filename, const PixelNode *head);


////////////////////////////////////////////////////////////////////////////////////////////



// PixelNode *readPPM(const char *filename)
// {
//     FILE *file = fopen(filename, "rb");
//     if (!file)
//     {
//         perror("Error opening file");
//         return NULL;
//     }

//     // Read and parse the header
//     char header[512];
//     if (!fgets(header, sizeof(header), file))
//     {
//         perror("Error reading header");
//         fclose(file);
//         return NULL;
//     }

//     // Check the PPM format
//     if (strncmp(header, "P6", 2) != 0)
//     {
//         fprintf(stderr, "Invalid image format (must be 'P6')\n");
//         fclose(file);
//         return NULL;
//     }

//     // Read image dimensions and max color value
//     int maxColorValue;
//     while (fgets(header, sizeof(header), file))
//     {
//         if (header[0] == '#')
//         {
//             continue;
//         }
//         if (sscanf(header, "%d %d", &width, &height) == 2)
//         {
//             break;
//         }
//     }
//     while (fgets(header, sizeof(header), file))
//     {
//         if (header[0] == '#')
//         {
//             continue;
//         }
//         if (sscanf(header, "%d", &maxColorValue) == 1)
//         {
//             break;
//         }
//     }

//     if (width <= 0 || height <= 0 || maxColorValue != 255)
//     {
//         fprintf(stderr, "Invalid image metadata\n");
//         fclose(file);
//         return NULL;
//     }

//     PixelNode *head = NULL;
//     PixelNode *prevRow = NULL;
//     PixelNode *prevPixel = NULL;

//     for (int y = 0; y < height; y++)
//     {
//         PixelNode *currentRow = NULL;
//         for (int x = 0; x < width; x++)
//         {
//             PixelNode *newPixel = (PixelNode *)malloc(sizeof(PixelNode));
//             if (!newPixel)
//             {
//                 perror("Memory allocation failed");
//                 fclose(file);
//                 return NULL;
//             }

//             // Read pixel data
//             if (fread(&newPixel->Red, 1, 1, file) != 1 ||
//                 fread(&newPixel->Green, 1, 1, file) != 1 ||
//                 fread(&newPixel->Blue, 1, 1, file) != 1)
//             {
//                 perror("Error reading pixel data");
//                 free(newPixel);
//                 fclose(file);
//                 return NULL;
//             }

//             newPixel->CdfValue = 0;
//             newPixel->up = NULL;
//             newPixel->down = NULL;
//             newPixel->left = prevPixel;
//             newPixel->right = NULL;

//             if (prevPixel)
//             {
//                 prevPixel->right = newPixel;
//             }

//             if (x == 0)
//             {
//                 currentRow = newPixel;
//             }

//             if (prevRow)
//             {
//                 PixelNode *abovePixel = prevRow;
//                 for (int i = 0; i < x; i++)
//                 {
//                     abovePixel = abovePixel->right;
//                 }
//                 newPixel->up = abovePixel;
//                 abovePixel->down = newPixel;
//             }

//             prevPixel = newPixel;
//         }

//         if (y == 0)
//         {
//             head = currentRow;
//         }

//         prevRow = currentRow;
//         prevPixel = NULL;
//     }

//     fclose(file);
//     return head;
// }

/////////////////////////////////////////////////////////////////////////////////////

int main()
{
    const char *inputFilename = "image01.ppm";
    const char *outputFilename = "output.ppm";

    PixelNode *head = readPPM(inputFilename);

    if (head)
    {
        //
         computeCDFValues(head);
        //
         applyHistogramEqualization(head);
        //
        writePPM(outputFilename, head);
    }

    return 0;
}