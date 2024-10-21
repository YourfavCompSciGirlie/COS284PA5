#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

PixelNode *readPPM(const char *filename);
void computeCDFValues(PixelNode *head);
void applyHistogramEqualization(PixelNode *head);
void savePPM(const char *filename, PixelNode *head, int width, int height);
void writePPM(const char *filename, const PixelNode *head);

PixelNode *readPPM(const char *filename)
{
    FILE *file = fopen(filename, "rb");
    if (!file)
    {
        perror("Error opening file");
        return NULL;
    }

    // Read and parse the header
    char header[512];
    if (!fgets(header, sizeof(header), file))
    {
        perror("Error reading header");
        fclose(file);
        return NULL;
    }

    // Check the PPM format
    if (strncmp(header, "P6", 2) != 0)
    {
        fprintf(stderr, "Invalid image format (must be 'P6')\n");
        fclose(file);
        return NULL;
    }

    // Read image dimensions and max color value
    int maxColorValue;
    while (fgets(header, sizeof(header), file))
    {
        if (header[0] == '#')
        {
            continue;
        }
        if (sscanf(header, "%d %d", &width, &height) == 2)
        {
            break;
        }
    }
    while (fgets(header, sizeof(header), file))
    {
        if (header[0] == '#')
        {
            continue;
        }
        if (sscanf(header, "%d", &maxColorValue) == 1)
        {
            break;
        }
    }

    if (width <= 0 || height <= 0 || maxColorValue != 255)
    {
        fprintf(stderr, "Invalid image metadata\n");
        fclose(file);
        return NULL;
    }

    PixelNode *head = NULL;
    PixelNode *prevRow = NULL;
    PixelNode *prevPixel = NULL;

    for (int y = 0; y < height; y++)
    {
        PixelNode *currentRow = NULL;
        for (int x = 0; x < width; x++)
        {
            PixelNode *newPixel = (PixelNode *)malloc(sizeof(PixelNode));
            if (!newPixel)
            {
                perror("Memory allocation failed");
                fclose(file);
                return NULL;
            }

            // Read pixel data
            if (fread(&newPixel->Red, 1, 1, file) != 1 ||
                fread(&newPixel->Green, 1, 1, file) != 1 ||
                fread(&newPixel->Blue, 1, 1, file) != 1)
            {
                perror("Error reading pixel data");
                free(newPixel);
                fclose(file);
                return NULL;
            }

            newPixel->CdfValue = 0;
            newPixel->up = NULL;
            newPixel->down = NULL;
            newPixel->left = prevPixel;
            newPixel->right = NULL;

            if (prevPixel)
            {
                prevPixel->right = newPixel;
            }

            if (x == 0)
            {
                currentRow = newPixel;
            }

            if (prevRow)
            {
                PixelNode *abovePixel = prevRow;
                for (int i = 0; i < x; i++)
                {
                    abovePixel = abovePixel->right;
                }
                newPixel->up = abovePixel;
                abovePixel->down = newPixel;
            }

            prevPixel = newPixel;
        }

        if (y == 0)
        {
            head = currentRow;
        }

        prevRow = currentRow;
        prevPixel = NULL;
    }

    fclose(file);
    return head;
}

void computeCDFValues(PixelNode *head)
{
    int histogram[256] = {0}; 
    int cdf[256] = {0};       
    int totalPixels = 0;

    // 1. Compute the histogram
    PixelNode *currentRow = head;
    PixelNode *currentPixel;
    while (currentRow != NULL)
    {
        currentPixel = currentRow;
        while (currentPixel != NULL)
        {
            // Assuming grayscale, so use Red as representative intensity
            unsigned char intensity = currentPixel->Red;
            histogram[intensity]++;
            totalPixels++;
            currentPixel = currentPixel->right;
        }
        currentRow = currentRow->down;
    }

    // 2. compute the CDF from the histogram
    cdf[0] = histogram[0];
    for (int i = 1; i < 256; i++)
    {
        cdf[i] = cdf[i - 1] + histogram[i];
    }

    // 3. normalize the CDF values to scale from 0 to 255
    for (int i = 0; i < 256; i++)
    {
        cdf[i] = (int)(((float)cdf[i] / totalPixels) * 255.0);
    }

    // 4. assign the CDF values to the corresponding pixels
    currentRow = head;
    while (currentRow != NULL)
    {
        currentPixel = currentRow;
        while (currentPixel != NULL)
        {
            // assign CDF value based on pixel intensity (grayscale, using Red channel)
            unsigned char intensity = currentPixel->Red;
            currentPixel->CdfValue = cdf[intensity];
            currentPixel = currentPixel->right;
        }
        currentRow = currentRow->down;
    }
}

void applyHistogramEqualization(PixelNode *head)
{
    PixelNode *currentRow = head;
    PixelNode *currentPixel;

    while (currentRow != NULL)
    {
        currentPixel = currentRow;
        while (currentPixel != NULL)
        {
            // retrieve
            unsigned char cdfValue = currentPixel->CdfValue;
            unsigned char newPixelValue = (unsigned char)(cdfValue + 0.5);

            if (newPixelValue > 255)
            {
                newPixelValue = 255;
            }

            // setting pixel's RGB values to newPixelValue
            currentPixel->Red = newPixelValue;
            currentPixel->Green = newPixelValue;
            currentPixel->Blue = newPixelValue;

            // move to the next pixel 
            currentPixel = currentPixel->right;
        }
        currentRow = currentRow->down;
    }
}

void savePPM(const char *filename, PixelNode *head, int width, int height)
{
    FILE *file = fopen(filename, "wb");
    if (!file)
    {
        perror("Error opening file for writing");
        return;
    }

    // header
    fprintf(file, "P6\n%d %d\n255\n", width, height);

    //pixel data
    PixelNode *currentRow = head;
    PixelNode *currentPixel;

    while (currentRow != NULL)
    {
        currentPixel = currentRow;
        while (currentPixel != NULL)
        {
            fwrite(&currentPixel->Red, 1, 1, file);
            fwrite(&currentPixel->Green, 1, 1, file);
            fwrite(&currentPixel->Blue, 1, 1, file);

            currentPixel = currentPixel->right;
        }
        currentRow = currentRow->down;
    }

    fclose(file);
}

void writePPM(const char *filename, const PixelNode *head)
{
    // 1. Open the File:
    FILE *file = fopen(filename, "wb");
    if (!file)
    {
        perror("Error opening file for writing");
        return;
    }

    int width = 0, height = 0;

    //traverse the first row
    const PixelNode *currentPixel = head;
    while (currentPixel != NULL)
    {
        width++;
        currentPixel = currentPixel->right;
    }

    // traverse the first column
    const PixelNode *currentRow = head;
    while (currentRow != NULL)
    {
        height++;
        currentRow = currentRow->down;
    }

    //PPM Header:
    fprintf(file, "P6\n%d %d\n255\n", width, height);

    currentRow = head;
    while (currentRow != NULL)
    {
        currentPixel = currentRow;
        while (currentPixel != NULL)
        {
            fwrite(&currentPixel->Red, 1, 1, file);
            fwrite(&currentPixel->Green, 1, 1, file);
            fwrite(&currentPixel->Blue, 1, 1, file);

            currentPixel = currentPixel->right;
        }
        currentRow = currentRow->down;
    }

    fclose(file);
}

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
        savePPM(outputFilename, head, width, height);
        //
        writePPM("final_output.ppm", head);
    }

    return 0;
}
