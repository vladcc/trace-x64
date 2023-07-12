#include <stdio.h>
#include <string.h>
#include "parse_opts.h"

#define OPTS_START          '-'
#define OPTS_LONG_ASSING    '='
#define SHORT_NAME_BUFF_LEN 3
#define LONG_NAME_BUFF_LEN  128

enum {SHORT, LONG, ARG, DOUBLE_DASH};
//-----------------------------------------------------------------------------

static int what(char * str)
{
    int ret = ARG;

    if (OPTS_START == str[0])
    {
        ret = SHORT;
        if (OPTS_START == str[1])
        {
            ret = LONG;
            if (!str[2])
                ret = DOUBLE_DASH;
        }
    }

    return ret;
}
//------------------------------------------------------------------------------

void opts_parse(int argc, char * argv[], opts_parse_data * parse_data)
{
    char sname_str[SHORT_NAME_BUFF_LEN];
	
	opts_table * the_tbl = parse_data->the_tbl;
	opts_on_unbound_arg unbound_arg = parse_data->on_unbound.handler;
	void * unbound_arg_arg = parse_data->on_unbound.context;
	opts_on_error on_error = parse_data->on_error.handler;
	void * err_ctx = parse_data->on_error.context;
	
    char * str;
    opts_entry * this_opt;
    opts_handler cbk;
    void * cbk_arg;
    opts_entry * opts_tbl = the_tbl->tbl;
    int opts_tbl_size = the_tbl->length;
    bool everything_is_arg = false;

    for (int i = 0; i < argc; ++i)
    {
        str = argv[i];
        if (!everything_is_arg)
        {
            switch (what(str))
            {
                case SHORT:
                {
                    char * pstr = str+1;
                    if (*pstr)
                    {
                        int ch, j;
                        while ((ch = *pstr))
                        {
                            snprintf(sname_str,
                                SHORT_NAME_BUFF_LEN, "%c", ch
                                        );

                            for (j = 0; j < opts_tbl_size; ++j)
                            {
                                this_opt = opts_tbl+j;
                                if (this_opt->names.short_name == ch)
                                {
                                    cbk = this_opt->handler.handler;
                                    cbk_arg = this_opt->handler.context;
                                    if (this_opt->takes_arg)
                                    {
                                        if (*(pstr+1))
                                        {
                                            cbk(sname_str, pstr+1, cbk_arg);
                                            goto next_argv;
                                        }
                                        else if (argv[i+1])
                                        {
                                            ++i;
                                            cbk(sname_str, argv[i], cbk_arg);
                                            goto next_argv;
                                        }
                                        else
                                        {
											on_error(
												OPTS_ARG_REQ_ERR,
												sname_str,
												err_ctx
											);
										}
                                    }
                                    else
                                        cbk(sname_str, NULL, cbk_arg);
                                    break;
                                }
                            }

                            if (j == opts_tbl_size)
                            {
                                on_error(
									OPTS_UNKOWN_OPT_ERR,
									sname_str,
									err_ctx
								);
                            }
                            ++pstr;
                        }
                    }
                    else
                        goto no_opt_arg;
                } break;

                case LONG:
                {
                    str += 2;
                    bool assigned = false;
                    char * parg = strchr(str, OPTS_LONG_ASSING);
                    if (parg)
                    {
                        *parg = '\0';
                        ++parg;
                        assigned = true;
                    }

                    char * pstr = str;
                    opts_entry * this_opt;
                    int j;
                    for (j = 0; j < opts_tbl_size; ++j)
                    {
                        this_opt = opts_tbl+j;
                        if (this_opt->names.long_name &&
                            (strcmp(pstr, this_opt->names.long_name) == 0))
                        {
                            cbk = this_opt->handler.handler;
                            cbk_arg = this_opt->handler.context;
                            if (this_opt->takes_arg)
                            {
                                if (!parg || !(*parg))
                                    parg = argv[++i];

                                if (!parg)
								{
									on_error(
										OPTS_ARG_REQ_ERR,
										pstr,
										err_ctx
									);
								}

                                cbk(pstr, parg, cbk_arg);
                            }
                            else if (assigned)
                                on_error(OPTS_NO_ARG_REQ_ERR, pstr, err_ctx);
                            else
                                cbk(pstr, NULL, cbk_arg);

                            break;
                        }
                    }

                    if (j == opts_tbl_size)
                        on_error(OPTS_UNKOWN_OPT_ERR, pstr, err_ctx);
                } break;

                case ARG:
                    goto no_opt_arg;
                    break;

                case DOUBLE_DASH:
                    everything_is_arg = true;
                    break;

                default:
                    break;
            }
        }
        else
        {
no_opt_arg:
            unbound_arg(str, unbound_arg_arg);
        }

next_argv:
        continue;
    }
}
//------------------------------------------------------------------------------

char * opts_get_sub_arg(char ** parg, char delimiter)
{
    char * next = NULL;

    if (*parg)
    {
        char * arg = *parg;
        while (*arg == delimiter)
            ++arg;

        *parg = arg;

        if (*arg)
            next = arg;

        bool found = false;
        while (*arg++)
        {
            if (*arg == delimiter)
            {
                found = true;
                *arg = '\0';
                *parg = arg+1;
                break;
            }
        }

        if (!found)
            *parg = NULL;
    }

    return next;
}
//------------------------------------------------------------------------------

void opts_print_help(opts_table * the_tbl)
{
    opts_entry * this_opt;
    opts_entry * opts_tbl = the_tbl->tbl;
    int opts_tbl_size = the_tbl->length;

    char sname_str[SHORT_NAME_BUFF_LEN];
    char lname_str[LONG_NAME_BUFF_LEN];
    for (int i = 0; i < opts_tbl_size; ++i)
    {
        this_opt = opts_tbl+i;
        snprintf(sname_str, SHORT_NAME_BUFF_LEN,
            "%c%c", OPTS_START, this_opt->names.short_name
            );

        snprintf(lname_str, LONG_NAME_BUFF_LEN,
         "%c%c%s", OPTS_START, OPTS_START, this_opt->names.long_name
         );

        this_opt->print_help(sname_str, lname_str);
    }
}
//------------------------------------------------------------------------------
