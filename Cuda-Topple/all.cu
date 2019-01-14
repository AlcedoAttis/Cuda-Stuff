#include <iostream>
#include <vector>
#include <SFML/Graphics.hpp>

#define wdt 1024
#define hgt 1024
#define pix wdt*hgt

// TODO: Edge cases 
__global__
void updateSand(int *data_curr, int *data_old, unsigned char *pixels) {
    int ROW = blockIdx.y*blockDim.y+threadIdx.y;
    int COL = blockIdx.x*blockDim.x+threadIdx.x;
    if(ROW >= hgt-1 || COL >= wdt-1 || ROW <= 0 || COL <= 0) return;
    int NUM = ROW*wdt + COL; 

    data_old[NUM] = data_curr[NUM]%4 + data_curr[NUM+1]/4 + data_curr[NUM-1]/4 + data_curr[NUM-wdt]/4 + data_curr[NUM+wdt]/4;
    if(data_old[NUM] > 0) {
        if(data_old[NUM] % 4 == 1) {
            pixels[4*NUM] = 255; pixels[4*NUM+1] = 0; pixels[4*NUM+2] = 0; }
        if(data_old[NUM] % 4 == 2) {
            pixels[4*NUM] = 0; pixels[4*NUM+1] = 255; pixels[4*NUM+2] = 0; }
        if(data_old[NUM] % 4 == 3) {
            pixels[4*NUM] = 0; pixels[4*NUM+1] = 0; pixels[4*NUM+2] = 255; }
        if(data_old[NUM] % 4 == 0) {
            pixels[4*NUM] = 255; pixels[4*NUM+1] = 255; pixels[4*NUM+2] = 255; }
    } else {
        for(int j=0; j<3; j++) pixels[4*NUM+j] = 0;
    }
}

int main() { 
    // boiler // create Window
    sf::RenderWindow window(sf::VideoMode(wdt, hgt), "Hello Sandkasten!");
    // boiler // needed to draw image
    sf::Texture texture;
    texture.create(wdt, hgt); 
    sf::Sprite sprite(texture);

    // code
    int *data_p, *data_q;
    unsigned char *pixels;

    cudaMallocManaged(&data_p, pix*sizeof(int));
    cudaMallocManaged(&data_q, pix*sizeof(int));
    cudaMallocManaged(&pixels, 4*pix*sizeof(sf::Uint8));

    for(int i=0; i<pix; i++) pixels[4*i+3] = 255; //set alpha to max
    // set towers
    data_p[hgt/2*wdt + wdt/2] = 2000000;
    // boiler // run program
    while (window.isOpen()) {

        int xy = 32;
        dim3 thread_grid_in_block(xy, xy);
        dim3 grid_of_blocks((wdt + 32 - 1)/xy, (wdt + 32 - 1)/xy);

        updateSand<<<grid_of_blocks, thread_grid_in_block>>>(data_p, data_q, pixels);
        cudaDeviceSynchronize();
        int *temp = data_p; data_p=data_q; data_q = temp;

        // boiler // show sprite
        texture.update(pixels);  
        window.clear();
        window.draw(sprite);
        window.display();

        sf::Event event;
        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed || 
                event.key.code == sf::Keyboard::Escape) {
                
                cudaFree(data_p);
                cudaFree(data_q);
                cudaFree(pixels);
                window.close();
            }
        }
    }
    return 0;
}   