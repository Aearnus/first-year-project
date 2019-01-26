#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <string.h>

struct region {
  unsigned long start;
  unsigned long end;
};
struct region* maps = NULL;
unsigned int maps_length = 0;

void make_snapshot(unsigned int i, FILE* mem_file) {
  char output_filename[128];
  snprintf(output_filename, 128, "%0iselflove.out", i);
  FILE* output_file = fopen(output_filename, "w");

  for (unsigned int curr_map = 0; curr_map < maps_length; curr_map++) {
	fseek(mem_file, maps[curr_map].start, SEEK_SET);
	unsigned long curr_map_size = maps[curr_map].end - maps[curr_map].start;
	char* temp_mem = malloc(curr_map_size);
	fread(temp_mem, curr_map_size, 1, mem_file);
	fwrite(temp_mem, curr_map_size, 1, output_file);
	free(temp_mem);
  }
	
  fclose(output_file);
}

int main() {
  pid_t pid = getpid();
  
  //read the maps into memory
  char maps_filename[128];
  snprintf(maps_filename, 128, "/proc/%d/maps", pid);
  FILE* maps_file = fopen(maps_filename, "r");
  struct region temp_region;
  char temp_map_string[128];
  while (fgets(temp_map_string, 128, maps_file) != NULL) {
	sscanf(temp_map_string, "%12lx-%12lx", &temp_region.start, &temp_region.end);
	maps = realloc(maps, sizeof(struct region)*(maps_length + 1));
	memcpy(&(maps[maps_length]), &temp_region, sizeof(struct region));
	maps_length++;
	printf("storing map from %lx to %lx\n", maps[maps_length - 1].start, maps[maps_length - 1].end);
  }
  fclose(maps_file);

  //remove the syscall map
  maps_length--;
  
  char mem_filename[128];
  snprintf(mem_filename, 128, "/proc/%d/mem", pid); 
  FILE* mem_file = fopen(mem_filename, "r");
  make_snapshot(0, mem_file);
  fclose(mem_file);
  return 1;
}
