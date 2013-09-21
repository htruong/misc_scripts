#include <sys/types.h>
#include <sys/time.h>
#include <sys/queue.h>
#include <stdlib.h>
#include <err.h>
#include <event.h>
#include <evhttp.h>

#include <string.h>
#include <stdio.h>

#include <time.h>

#include <pthread.h>
#include <errno.h>

char * escape(char*str) {

	char *escStr;
	int i, count_final, count = strlen(str);

	count_final = count + 1;

	for(i=0; i<count; i++) {
		if (str[i] == '\'' || str[i] == '\n') {
			count_final++;
		}
	} 

	escStr = (char *) malloc(count_final * sizeof(char));

	count_final = 0;
	
	for(i=0; i<count; i++) {
		if (str[i] == '\'' || str[i] == '\n') {
			escStr[count_final] = '\\';
			count_final++;
		}
		if (str[i] == '\n') {
			escStr[count_final] = 'n';
		} else {
			escStr[count_final] = str[i];
		}
		count_final++;
	}
	escStr[count_final] = '\0';

	return escStr;
}

int exec(char* cmd, char * ret, int max) {
	FILE* pipe = popen(cmd, "r");
	int ret_val = 0;
	if (!pipe) ret_val = 0;
	int max_remaining = max;
	ret[0] = 0;
	while (!feof(pipe)) {
		max_remaining = max - strlen(ret) - 1;
		if (fgets(&ret[strlen(ret)], max_remaining, pipe) == NULL) {
			break;
		}	
	}

	pclose(pipe);
	return ret_val;
}

void argtoi(struct evkeyvalq *args, char *key, int *val, int def)
{
	char *tmp;

	*val = def;
	tmp = (char *)evhttp_find_header(args, (const char *)key);
	if (tmp) {
		*val = atoi(tmp);
	}
}

int _get_int(struct evhttp_request *req, char *key, int def) {
	struct evkeyvalq    args;
	int ret;
	evhttp_parse_query(req->uri, &args);
	argtoi(&args, key, &ret, def);
	return ret;
} 

char * _get_chars (struct evhttp_request *req, char *key, char * def) {
	struct evkeyvalq args;
	char * ret;
	evhttp_parse_query(req->uri, &args);
	ret = (char *)evhttp_find_header(&args, key);
	if (ret == NULL) {
		return def;
	} 
	return ret;
}

void notfound_hander(struct evhttp_request *req, void *arg) 
{
	struct evbuffer *buf;
	buf = evbuffer_new();
	if (buf == NULL)
		err(1, "failed to create response buffer");
	evbuffer_add_printf(buf, "404 Not found");
	evhttp_add_header(evhttp_request_get_output_headers(req),
		"Content-Type", "text/plain");
	evhttp_send_reply(req, HTTP_NOTFOUND, "Not found", buf);	
}

typedef struct {
	char * cmd;
	char * ret;
	int done;
} execstruct;

void execworker(void *q) {
	execstruct *e = (execstruct *) q;
	exec(e->cmd, e->ret, 102400 *sizeof(char));
	e->done = 1;
}


void sys_handler(struct evhttp_request *req, void *arg)
{
	struct evbuffer *buf;
	int valid_cmd = 1;
	int raw_output = 0;
	int timeout = 2;
	int needs_escaped = 1;

	char * cmd;
	cmd = (char *) malloc(1024 * sizeof(char));

	buf = evbuffer_new();
	if (buf == NULL)
		err(1, "failed to create response buffer");
	evhttp_add_header(evhttp_request_get_output_headers(req),
		"Content-Type", "text/plain");

	if (strncmp(_get_chars(req, "cmd", ""),"zing", 50) == 0) {
		sprintf(cmd, "zing_json_fetcher.sh \"%s\" %d", _get_chars(req, "artist", ""), _get_int(req, "page", 1) );
		timeout = 5;
		raw_output = 1;
	} else if (strncmp(_get_chars(req, "cmd", ""),"m3u", 50) == 0) {
		sprintf(cmd, "zing_m3u_fetcher.sh \"%s\"", _get_chars(req, "artist", ""));
		timeout = 60;
		raw_output = 1;
		needs_escaped = 0;
	} else {
		valid_cmd = 0;
	}

	if (valid_cmd) {
		char * ret;
		char * ret_escaped;
		ret = (char *) malloc(102400 *sizeof(char));

		pthread_t f;
		execstruct e;
		e.cmd = cmd;
		e.ret = ret;
		e.done = 0;
		int s, i;
		fprintf(stderr, "Trying to create a new exec thread... [%s]", cmd);
		pthread_create (&f, NULL, execworker, (void *) &e);
		for (i = 0; i < timeout; ++i) {
			sleep(1);
			if (e.done) {
				fprintf(stderr, " Done!\n");
				break;
			}
			fprintf(stderr, ".");
		}

		s = pthread_cancel(f);
		
		if (s != ESRCH) {
			fprintf(stderr, " Timed out!\n");
			sprintf(ret, "Request timed out\0");
		}
		
		//fprintf(stderr, "%s\n", ret);
		
		
		ret_escaped = escape(ret);
		if (raw_output == 0) {
			evbuffer_add_printf(buf, "{\"valid\":%d,\"result\":\"%s\"}", valid_cmd, ret_escaped);
		} else {
			evbuffer_add_printf(buf, "%s", needs_escaped ? ret_escaped : ret);
		}
		free(ret_escaped);

		free(ret);
	} else {
		evbuffer_add_printf(buf, "{\"valid\":%d,\"result\":\"\"}", valid_cmd);
	}

	evhttp_send_reply(req, HTTP_OK, "OK", buf);

	free(cmd);
}

int main(int argc, char **argv)
{
	struct evhttp *httpd;

	event_init();
	httpd = evhttp_start(argv[argc-2], atoi(argv[argc-1]));
	evhttp_set_cb(httpd, "/request_sys/", sys_handler, NULL); 
/* Set a callback for all other requests. */
	evhttp_set_gencb(httpd, notfound_hander, NULL);
event_dispatch();    /* Not reached in this code as it is now. */
	evhttp_free(httpd);    
	return 0;
}
