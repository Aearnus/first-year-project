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
  snprintf(output_filename, 128, "%04iselflove.out", i);
  FILE* output_file = fopen(output_filename, "w");
  if (output_file == NULL) {
	puts("output_file is bad");
  } else {
	puts ("output_file is good");
  }
  
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

char* get_process_name(pid_t pid) {
  char comm_filename[128];
  snprintf(comm_filename, 128, "/proc/%d/comm", pid);
  FILE* comm_file = fopen(comm_filename, "r");
  char* out = malloc(64);
  fgets(out, 64, comm_file);
  fclose(comm_file);
  return out;
}

int filter_map_line(char* map_line, char* process_name) {
  map_line = map_line + 73;
  printf("checking memory map of file %s against %s\n", map_line, process_name);
  return ((strstr(map_line, process_name) != NULL) || (strstr(map_line, "[stack]") != NULL));
}

FILE* get_mem_file(pid_t pid) {
  char mem_filename[128];
  snprintf(mem_filename, 128, "/proc/%d/mem", pid);
  return fopen(mem_filename, "r");
}

FILE* get_maps_file(pid_t pid) {
  char maps_filename[128];
  snprintf(maps_filename, 128, "/proc/%d/maps", pid);
  return fopen(maps_filename, "r");
}

int main() {
  pid_t pid = getpid();
  
  //read the maps into memory
  FILE* maps_file = get_maps_file(pid);
  struct region temp_region;
  char temp_map_string[128];
  while (fgets(temp_map_string, 128, maps_file) != NULL) {
	// GET_PROCESS_NAME INTENTIONALLY LEAKS MEMORY HERE. IT SHOULD BE free'd NORMALLY.
	if (filter_map_line(temp_map_string, get_process_name(pid))) {
	  sscanf(temp_map_string, "%12lx-%12lx", &temp_region.start, &temp_region.end);
	  maps = realloc(maps, sizeof(struct region)*(maps_length + 1));
	  memcpy(&(maps[maps_length]), &temp_region, sizeof(struct region));
	  maps_length++;
	  printf("storing map from %lx to %lx\n\n", maps[maps_length - 1].start, maps[maps_length - 1].end);
	} else {
	  printf("rejecting map\n\n");
	}
  }
  fclose(maps_file);


  //make the memory output files
  for (unsigned int iteration = 0; iteration < 128; iteration++) {
	FILE* mem_file = get_mem_file(pid);
	make_snapshot(iteration, mem_file);
	fclose(mem_file);
  }
  return 1;
}
