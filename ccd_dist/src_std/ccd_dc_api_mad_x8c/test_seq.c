#include	<stdio.h>

/*
 *	Program to explore the complexity and issues involved
 *	in MAD sequencing of data collection.  Do this before
 *	implimenting this in ccd_dc_hw.c
 */

#define	N_RUNS	10
#define	N_WAVE	5


int	run_nruns;
char	*run_dir;
char	*run_name;
int	run_runno[N_RUNS];
int	run_times[N_RUNS];
int	run_start[N_RUNS];

int	run_axis[N_RUNS];
float	run_delta[N_RUNS];
float	run_omega[N_RUNS];
float	run_phi[N_RUNS];
float	run_kappa[N_RUNS];

int	run_end[N_RUNS];

int	wave_nwave;
float	wave_values[N_WAVE];

int	wave_mode;	/* 0 never, 1 each run, 2 each anom wedge, 3 every n frames */
int	run_anom;	/* 0 no anom, 1 anom */

int	anom_wedge;	/* number of frames per anom wedge */
int	wave_nframes;	/* number of frames between wavelength changes */

int	dz_mode;	/* 0 no dezingering, 1 for regular dezingering, 1 variable time dezingering */
int	dz_nd;		/* number of images going into dark image dezingering */
int	dz_nx;		/* number of images going into xray image dezingering */
float	dz_dzratio;	/* ratio of 1st / second image time */

int	dk_before_run;	/* 1 do a dark current before each run */
int	dk_everytsec;	/* do a dark every "t" seconds (frames,for this test), -1 to ignore */

int	restart_run = -1;	/* run restart number */
int	restart_frame = -1;	/* frame restart number */

int	eff_axis;
float	eff_width;

float	cur_omega;
float	cur_phi;
float	cur_kappa;

setup_runs()
  {
	run_nruns = 2;

	run_runno[0] = 1;
	run_times[0] = 30;
	run_start[0] = 1;
	run_delta[0] = 1.0;
	run_end[0] = 20;

	run_axis[0] = 0;
	run_omega[0] = 10.;
	run_phi[0] = 20.;
	run_kappa[0] = 30;

	run_runno[1] = 2;
	run_times[1] = 15;
	run_start[1] = 1;
	run_axis[1] = 1;
	run_delta[1] = 1.0;
	run_end[1] = 3;

	run_axis[1] = 0;
	run_omega[1] = 30.;
	run_phi[1] = 20.;
	run_kappa[1] = 10;

	wave_nwave = 2;
	wave_values[0] = 1.5418;
	wave_values[1] = 1.7390;

	wave_mode = 1;
	run_anom = 1;

	anom_wedge = 5;
	wave_nframes = 10;

	dz_mode = 1;
	dz_nd = 2;
	dz_nx = 2;
	dz_dzratio = 1.0;

	dk_before_run = 1;
	dk_everytsec = 7;

	run_dir = ".";
	run_name = "seq";

	restart_run = -1;
	restart_frame = -1;
  }

int	batch_ctr;
int	wave_ctr;
int	run_ctr;
int	frame_ctr;
int	wedge_ctr;
int	doing_dark;
int	did_dark = 0;
int	eff_runno;
int	eff_start;
int	eff_wedge;
int	eff_end;
int	wedge_side;
float	eff_wave;

int	img_ctr;
int	img_max;

float	img_time;
float	cur_omega;
float	cur_phi;
float	cur_kappa;

float	p_wedge_omega;
float	p_wedge_phi;
float	p_wedge_kappa;

float	f_wedge_omega;
float	f_wedge_phi;
float	f_wedge_kappa;

/*
 *-----------------------------------------------------------
 *	A couple of routine to take care of time simulation.
 */

int	pseudo_time_ctr;

indicate_dark_taken()
  {
	pseudo_time_ctr = dk_everytsec;
  }

indicate_image_taken()
  {
	pseudo_time_ctr--;
	if(pseudo_time_ctr < 0)
		pseudo_time_ctr = 0;
  }

int	check_need_new_dark()
  {
	if(pseudo_time_ctr == 0)
		return(1);
	    else
		return(0);
  }

/*
 *------------------------------------------------------------
 */

seq_wave_ival()
  {
	char	lit_fname[4],file_name[256];

	for(frame_ctr = eff_start; frame_ctr <= eff_end;)
	  {
	    if(doing_dark) {
	      img_max = dz_nd;
	      if(dz_mode == 2)
	          img_max *= 2;
	     }
	    else
	      img_max = dz_nx;

	    for(img_ctr = 0; img_ctr < img_max; img_ctr++)
	      {
		if(dz_mode == 2) {
		    if(img_ctr >= img_max / 2)
		      img_time = run_times[run_ctr] * dz_dzratio;
		     else
		      img_time = run_times[run_ctr];
		  }
		 else
		    img_time = run_times[run_ctr];

	        strcpy(file_name,run_name);
	        strcat(file_name,"_");
	        sprintf(lit_fname,"%d",eff_runno);
	        util_3digit(lit_fname,eff_runno);
	        strcat(file_name,lit_fname);
	        strcat(file_name,"_");
	        util_3digit(lit_fname,frame_ctr);
	        strcat(file_name,lit_fname);
	        if(doing_dark)
			strcat(file_name,".dkx_");
	         else
			strcat(file_name,".imx_");
	        sprintf(lit_fname,"%d",img_ctr);
	        strcat(file_name,lit_fname);
	        fprintf(stdout,"%s %7.3f %7.5f ",file_name,img_time,eff_wave);
		if(doing_dark == 0) {
		    if(eff_axis == 1)
			fprintf(stdout,"%9.3f\n",cur_phi);
		      else
			fprintf(stdout,"%9.3f %9.3f %9.3f\n",cur_omega,cur_phi,cur_kappa);
		  }
		 else
			fprintf(stdout,"\n");

		/*
		 *	Move the angle forward 1 width amount.  This would occur in the beamline
		 *	process.  Pretend it's not here.
		 */

		if(doing_dark == 0) {
		  if(eff_axis == 1) {
		    cur_phi += eff_width;
		    if(cur_phi >= 360)
			cur_phi -= 360;
		  }
		 else {
		    cur_omega += eff_width;
		    if(cur_omega >= 360)
			cur_omega -= 360;
		  }
		 }

		/*
		 *	Move the angle back if this is multiple xray image dezingering.
		 *	This is NOT to be considered part of the previous code.
		 */
		if(doing_dark == 0 && img_ctr < img_max - 1) {
                  if(eff_axis == 1) {
                    cur_phi -= eff_width;
                    if(cur_phi >= 360)
                        cur_phi -= 360;
                  }
                 else {
                    cur_omega -= eff_width;
                    if(cur_omega >= 360)
                        cur_omega -= 360;
                  }
		 }
	      }
	    if(doing_dark == 0 && run_anom) {
		if(((anom_wedge - 1) == (frame_ctr - run_start[run_ctr]) % anom_wedge) || (frame_ctr == run_end[run_ctr])) {
		    if(wedge_side) {
			wedge_side = 0;
			eff_runno -= 100;

			/*
			 *	Increment BOTH sets of primary and friedel wedge angle
			 *	starts whenever the transition from friedel ---> primary is made.
			 */

			if(eff_axis == 1) {
				p_wedge_phi   += anom_wedge * eff_width;
				f_wedge_phi   += anom_wedge * eff_width;
			  }
			 else {
				p_wedge_omega += anom_wedge * eff_width;
				f_wedge_omega += anom_wedge * eff_width;
			      }

			cur_omega = p_wedge_omega;
			cur_phi   = p_wedge_phi;
			cur_kappa = p_wedge_kappa;
		      } else {
			wedge_side = 1;
			eff_runno += 100;
			frame_ctr -= frame_ctr - ((frame_ctr - run_start[run_ctr]) / anom_wedge) * anom_wedge;

			cur_omega = f_wedge_omega;
			cur_phi   = f_wedge_phi;
			cur_kappa = f_wedge_kappa;
		      }
		  }
	      }
	    if(doing_dark == 0) {
		frame_ctr++;
		if(dk_everytsec != -1) {
		    indicate_image_taken();
		    if(check_need_new_dark())
			doing_dark = 1;
		  }
	      }
	     else {
		  doing_dark = 0;
		  if(dk_everytsec != -1)
		  	indicate_dark_taken();
		  did_dark = 1;
		}
	  }
  }

initialize_angles()
  {
	float	euler_angs[3],kappa_angs[3];

	/*
	 *	Angles.
	 */

	if(run_axis[run_ctr] == 1) {
	cur_omega = 0;
	cur_kappa = 0;

	p_wedge_omega = 0;
	p_wedge_kappa = 0;

	f_wedge_omega = 0;
	f_wedge_kappa = 0;

	p_wedge_phi = run_phi[run_ctr] + (((eff_start - 1) / anom_wedge) * anom_wedge) * run_delta[run_ctr];
	f_wedge_phi = p_wedge_phi + 180;

	if(wedge_side)
		cur_phi = f_wedge_phi;
	  else
		cur_phi = p_wedge_phi;

	cur_phi += (eff_start - 1 -  (anom_wedge * ((eff_start - 1) / anom_wedge))) * run_delta[run_ctr];
	if(cur_phi >= 360)
		cur_phi -= 360;
	  }
	 else {
	    p_wedge_omega = run_omega[run_ctr] + (((eff_start - 1) / anom_wedge) * anom_wedge) * run_delta[run_ctr];
	    p_wedge_phi = run_phi[run_ctr];
	    p_wedge_kappa = run_kappa[run_ctr];

	    if(p_wedge_omega >= 360)
	    	p_wedge_omega -= 360.;

	    cur_omega = p_wedge_omega;
	    cur_phi   = p_wedge_phi;
	    cur_kappa = p_wedge_kappa;

            kappa_angs[0] = p_wedge_omega;
            kappa_angs[1] = p_wedge_phi;
            kappa_angs[2] = p_wedge_kappa;
            ktoe(kappa_angs, euler_angs);
            euler_angs[1] += 180.;
            euler_angs[2] = - euler_angs[2];
            etok(euler_angs, kappa_angs);

	    f_wedge_omega = kappa_angs[0];
	    f_wedge_phi   = kappa_angs[1];
	    f_wedge_kappa = kappa_angs[2];

	    if(wedge_side == 1) {
	        cur_omega = f_wedge_omega;
	        cur_phi   = f_wedge_phi;
	        cur_kappa = f_wedge_kappa;
	      }
	    cur_omega += (eff_start - 1 -  (anom_wedge * ((eff_start - 1) / anom_wedge))) * run_delta[run_ctr];
	    if(cur_omega >= 360)
	    	cur_omega -= 360;
	 }
  }

do_wave_wedge()
  {
	int	nbatches;

	for(run_ctr = 0; run_ctr < run_nruns; run_ctr++)
	  {
	    doing_dark = 0;
	    if(dk_before_run == 0 && did_dark == 0)
		doing_dark = 1;
	    if(dk_before_run == 1)
		doing_dark = 1;

	    if(restart_run != -1) {
		wave_ctr = restart_run / 200;
		eff_wave = wave_values[wave_ctr];
		wedge_side = (restart_run / 100) % 2;
		eff_runno = restart_run;
		eff_start = restart_frame;
	      }
	     else {
		wave_ctr = 0;
		eff_runno = run_runno[run_ctr] + 2 * 100 * wave_ctr;
		eff_start = run_start[run_ctr];
		eff_wave = wave_values[wave_ctr];
		wedge_side = 0;
	      }

	    eff_width = run_delta[run_ctr];
	    eff_axis  = run_axis[run_ctr];

	    if(eff_start + eff_wedge < run_end[run_ctr])
		eff_end = eff_start + eff_wedge - 1;
	    else
		eff_end = run_end[run_ctr];

	    nbatches = 1 + (run_end[run_ctr] - eff_start) / eff_wedge;

	    for(batch_ctr = 0; batch_ctr < nbatches; batch_ctr++)
	      {
	        for(; wave_ctr < wave_nwave; wave_ctr++)
	          {
		    if(restart_run == -1) {
		      wedge_side = 0;
		      eff_runno = run_runno[run_ctr] + 2 * 100 * wave_ctr;
		      eff_wave = wave_values[wave_ctr];
		    } else {
		        restart_run = -1;
		        restart_frame = -1;
		      }
	    	    initialize_angles();
		    seq_wave_ival();
	          }
		eff_start += eff_wedge;
		if(eff_start + eff_wedge < run_end[run_ctr])
			eff_end = eff_start + eff_wedge - 1;
		    else
			eff_end = run_end[run_ctr];
		wave_ctr = 0;
	      }
	  }
  }

main(argc,argv)
int	argc;
char	*argv[];
  {
	setup_runs();

	kappa_init(50.0);

	switch(wave_mode)
	  {
	    case 0:
		eff_wedge = 100000;
		do_wave_wedge();
		break;
	    case 1:
		eff_wedge = 100000;
		do_wave_wedge();
		break;
	    case 2:
		eff_wedge = anom_wedge;
		do_wave_wedge();
		break;
	    case 3:
		eff_wedge = wave_nframes;
		do_wave_wedge();
		break;
	  }
	exit(0);
  }