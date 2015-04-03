#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <string.h>

#define K_PREFIX 10000

static struct option long_options[] = {
    /* These options set a flag. */
    {"all", no_argument, 0, 'a'},
    {"nginx", no_argument, 0, 'n'},
    {"redis", no_argument, 0, 'r'},
    {"beanstalkd", no_argument, 0, 'b'},
    {"help", no_argument, 0, 'h'},
    {"prefix", required_argument, 0, K_PREFIX}, 
    {0, 0, 0, 0}
};

char* save_option(char **opts, char c, int index, unsigned* len, unsigned* max_len) {
    char opt[20];

    if (index > 0) {
        strcpy(opt, " --");
        strcat(opt, long_options[index].name);
    }
    else {
        char tmp[4] = {' ', '-', c, '\0'};
        strcpy(opt, tmp);  
    }

    if (*len + strlen(opt) + 1 > *max_len) {
        *opts = (char*)realloc(*opts, *max_len+strlen(opt)*2+1);
        if (!*opts) {
            return NULL;
        }
    }

    *opts = strcat(*opts, opt);
    *len = *len + strlen(opt) + 1;
    *max_len = *max_len + strlen(opt)*2 + 1;

    return *opts;
}

int main (int argc, char **argv) {
    int c;
    char *install_path = NULL;
    char *options = NULL;
    unsigned int cur_opt_len = 0;
    unsigned int max_opt_len = 0;

    while(1) {
        
        int option_index = -1;

        c = getopt_long (argc, argv, "abrnh", long_options, &option_index);
        if (c == -1)
            break;

        switch(c) {
            /* store path from prefix */
            case K_PREFIX:
                install_path = optarg;
                break;

            case 'a':
            case 'b':
            case 'r':
            case 'n':
            case 'h':
                if (!save_option(&options, c, option_index, &cur_opt_len, &max_opt_len)) {
                    free(options);
                    exit(-1);
                }
                break;

            case '?':
                free(options); 
                exit(-1);

            default:
                abort();
        }
    }

    /* output args as command "getopt". */
    printf("%s ", options);
    if (install_path) {
        printf("--prefix %s ", install_path);
    }
    printf("--");

    free(options);

    return 0;
}
