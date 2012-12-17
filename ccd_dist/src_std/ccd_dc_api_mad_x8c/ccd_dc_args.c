#include	"ccd_dc_ext.h"

usage(fp)
FILE	*fp;
  {
#ifdef VMS
	fprintf(fp,"Usage: ccd_dc [-s] [-h] [-o outputfile]\n");
#else
	fprintf(fp,"Usage: ccd_dc [-s] [-h]\n");
#endif /* VMS */
	fprintf(fp,
	 "\tOne or the other of the two flags -s or -h MUST be used:\n");
	fprintf(fp,
	 "\tccd_dc -s\t\truns ccd_dc in SIMULATION.\n");
	fprintf(fp,
	 "\tccd_dc -h\t\truns ccd_dc using SCANNER HARDWARE.\n");
#ifdef VMS
	fprintf(fp,"The -o outputfile causes stdout and stderr to be redirected to outputfile\n");
#endif /* VMS */
  }

/*
 *	Process arguments to ccd_dc.
 *
 *	-s	:	simulation used.
 *	-h	:	actual hardware used.
 *
 *	Default: no argument == -h.
 */

ccd_dc_args(argc,argv)
int	argc;
char	*argv[];
  {
	mdc_simulation = 0;
	raw_ccd_image = 0;
	repeat_dark_current = 1;

	while(argc > 1)
	{
	if(0 == strcmp(argv[1],"-h"))
	    mdc_simulation = 0;
	if(0 == strcmp(argv[1],"-s"))
	    mdc_simulation = 1;
	if(0 == strcmp(argv[1],"-raw_ccd_image"))
	  {
	    raw_ccd_image = 1;
	    fprintf(stdout,"ccd_dc_api:  raw_ccd_image mode.  Only copies of images\n");
	    fprintf(stdout,"             taken will be written to disk.  No geometric\n");
	    fprintf(stdout,"             or intensity corrections will be made.\n");
	  }
	if(0 == strcmp(argv[1],"-norepeat_dark_current"))
	    repeat_dark_current = 0;

	argc--;
	argv++;
	}
	if(repeat_dark_current == 1)
	  {
	    fprintf(stdout,"ccd_dc_api:  repeat_dark_current mode.  Two darks will be\n");
	    fprintf(stdout,"             retaken every so often (see darkinterval in config_ccd file).\n");
	  }
  }