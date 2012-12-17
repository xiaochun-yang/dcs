#include	"detcon_ext.h"

/*
 *	ccd_dc  -  Operate the ccd via an intenet network
 *		      connection.
 *
 */

main(argc,argv)
int	argc;
char	*argv[];
  {
	/*
	 *	Process arguments
	 */

	ccd_dc_args(argc,argv);

	ccd_register_names();

        if(check_environ())
                cleanexit(BAD_STATUS);
        if(apply_reasonable_defaults())
                cleanexit(BAD_STATUS);

	ccd_initialize();

	ccd_server_init();

	ccd_sim_clockstart();
  }

ccd_register_names()
  {
	void	ccd_heartbeat();
	void	ccd_server_update();
	void	ccd_read_input();
	void	mdc_read_status();
	void	output_status();
	void	ccd_check_alive();
	void	mdc_sim_read_status();

	clock_register_name(ccd_heartbeat,"ccd_heartbeat");
	clock_register_name(ccd_server_update,"ccd_server_update");
	clock_register_name(ccd_read_input,"ccd_read_input");
	clock_register_name(output_status,"output_status");
	clock_register_name(ccd_check_alive,"ccd_check_alive");
	clock_register_name(mdc_sim_read_status,"mdc_sim_read_status");
  }
