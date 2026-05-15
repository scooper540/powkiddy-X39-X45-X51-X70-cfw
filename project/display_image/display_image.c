#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/select.h>
#include <sys/reboot.h>
#include <linux/input.h>
#include <stdint.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <linux/fb.h>


#pragma pack(push,1)

typedef struct {
    uint16_t type;
    uint32_t size;
    uint16_t reserved1;
    uint16_t reserved2;
    uint32_t offset;
} BMPHeader;

typedef struct {
    uint32_t size;
    int32_t width;
    int32_t height;
    uint16_t planes;
    uint16_t bits;
    uint32_t compression;
    uint32_t imageSize;
    int32_t xppm;
    int32_t yppm;
    uint32_t colorsUsed;
    uint32_t importantColors;
} BMPInfoHeader;

#pragma pack(pop)

static inline uint16_t rgb888_to_rgb565(
    uint8_t r,
    uint8_t g,
    uint8_t b)
{
    return ((r >> 3) << 11) |
           ((g >> 2) << 5)  |
           (b >> 3);
}

void main(int argc, char* argv[])
{
    if(argc != 2)
    {
        printf("error you must provide image bmp to be displayed\r\n");
        return;
    }
    int fb = open("/dev/fb0", O_RDWR);
    if (fb < 0)
    {
        perror("open fb");
        return;
    }

    struct fb_var_screeninfo vinfo;
    struct fb_fix_screeninfo finfo;

    ioctl(fb, FBIOGET_VSCREENINFO, &vinfo);
    ioctl(fb, FBIOGET_FSCREENINFO, &finfo);

    uint8_t *fbp = mmap(
        0,
        finfo.smem_len,
        PROT_READ | PROT_WRITE,
        MAP_SHARED,
        fb,
        0);

    if (fbp == MAP_FAILED)
    {
        perror("mmap");
        close(fb);
        return;
    }

    FILE *f = fopen(argv[1], "rb");
    if (!f)
    {
        perror("fopen bmp");
        munmap(fbp, finfo.smem_len);
        close(fb);
        return;
    }

    BMPHeader header;
    BMPInfoHeader info;

    fread(&header, sizeof(header), 1, f);
    fread(&info, sizeof(info), 1, f);

    if (header.type != 0x4D42)
    {
        printf("Not a BMP\n");
        fclose(f);
        munmap(fbp, finfo.smem_len);
        close(fb);
        return;
    }

    if (info.bits != 24)
    {
        printf("Only 24-bit BMP supported\n");
        fclose(f);
        munmap(fbp, finfo.smem_len);
        close(fb);
        return;
    }

    int src_w = info.width;
    int src_h = info.height;

    int dst_w = vinfo.xres;
    int dst_h = vinfo.yres;

    // BMP rows padded to 4 bytes
    int bmp_stride = (src_w * 3 + 3) & ~3;

    uint8_t *bmp_data = malloc(bmp_stride * src_h);

    fseek(f, header.offset, SEEK_SET);
    fread(bmp_data, 1, bmp_stride * src_h, f);

    fclose(f);

    for (int y = 0; y < dst_h; y++)
    {
        for (int x = 0; x < dst_w; x++)
        {
            int sx, sy;

            sx = x * src_w / dst_w;
            sy = y * src_h / dst_h;

            uint8_t *p;
            p = bmp_data + (src_h - 1 - sy) * bmp_stride + sx * 3;

            uint8_t b = p[0];
            uint8_t g = p[1];
            uint8_t r = p[2];

            uint16_t color = rgb888_to_rgb565(r, g, b);

            int dx = x;
            int dy = y;

            long location =
                dy * finfo.line_length +
                dx * 2;

            *((uint16_t*)(fbp + location)) = color;
        }
    }

    free(bmp_data);

    munmap(fbp, finfo.smem_len);
    close(fb);
}
