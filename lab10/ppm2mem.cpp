#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <cstring>
#include <filesystem>

namespace fs = std::__fs::filesystem;

const int MAX_WIDTH = 320;
const int MAX_HEIGHT = 240;

std::vector<unsigned char> buf(MAX_WIDTH * MAX_HEIGHT * 3);

void usage(const char *prog_name) {
    std::cerr << "Usage: " << prog_name << " <output_file>" << std::endl;
    std::cerr << "Note: The program reads PPM files from fish1, fish2, and fish3 folders." << std::endl;
    exit(EXIT_FAILURE);
}

void process_folder(const std::string &folder, std::ofstream &ofp) {
    for (const auto &entry : fs::directory_iterator(folder)) {
        std::cout<<entry<<"\n";
        if (entry.path().extension() == ".ppm") {
            std::ifstream fp(entry.path(), std::ios::binary);
            if (!fp) {
                std::cerr << "Error: Could not open file " << entry.path() << std::endl;
                continue;
            }

            std::string line;
            int width, height, max_val;

            // Read header
            std::getline(fp, line); // P6
            if (line != "P6") {
                std::cerr << "Error: Invalid PPM format in " << entry.path() << std::endl;
                fp.close();
                continue;
            }

            std::getline(fp, line); // Comment or dimensions
            while (line[0] == '#') std::getline(fp, line); // Skip comments

            std::istringstream(line) >> width >> height;
            if (width > MAX_WIDTH || height > MAX_HEIGHT) {
                std::cerr << "Error: Image size too large in " << entry.path() << std::endl;
                fp.close();
                continue;
            }

            std::getline(fp, line); // Max value
            std::istringstream(line) >> max_val;
            if (max_val != 255) {
                std::cerr << "Error: Unsupported max value in " << entry.path() << std::endl;
                fp.close();
                continue;
            }

            // Read image data
            fp.read(reinterpret_cast<char *>(buf.data()), width * height * 3);
            if (fp.gcount() != width * height * 3) {
                std::cerr << "Error: Image data read error in " << entry.path() << std::endl;
                fp.close();
                continue;
            }
            fp.close();

            // Write to output
            for (int idx = 0; idx < width * height; idx++) {
                int r = buf[3 * idx + 0] >> 4;
                int g = buf[3 * idx + 1] >> 4;
                int b = buf[3 * idx + 2] >> 4;
                ofp << std::hex << r << g << b << std::endl;
            }
        }
    }
}

int main(int argc, char **argv) {
    if (argc != 2) {
        usage(argv[0]);
    }

    std::ofstream ofp(argv[1], std::ios::out);
    if (!ofp) {
        std::cerr << "Error: Could not open output file " << argv[1] << std::endl;
        return EXIT_FAILURE;
    }

    std::cout << "Processing images from folders: fish1, fish2, fish3" << std::endl;

    // Process each folder
    process_folder("/Users/chengpingfeng/Downloads/image", ofp);

    std::cout << "Processing complete. Output written to " << argv[1] << std::endl;

    ofp.close();
    return EXIT_SUCCESS;
}
