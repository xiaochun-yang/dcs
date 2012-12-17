/************************************************************************
                        Copyright 2001
                              by
                 The Board of Trustees of the 
               Leland Stanford Junior University
                      All rights reserved.

                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
Leland Stanford Junior University, nor their employees, makes any war-
ranty, express or implied, or assumes any liability or responsibility
for accuracy, completeness or usefulness of any information, apparatus,
product or process disclosed, or represents that its use will not in-
fringe privately-owned rights.  Mention of any product, its manufactur-
er, or suppliers shall not, nor is it intended to, imply approval, dis-
approval, or fitness for any particular use.  The U.S. and the Univer-
sity at all times retain the right to use and disseminate the furnished
items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209. 

************************************************************************/

/* tcl_wrapper.c */

/*File $Id: ice.c,v 1.24 2010/02/04 00:40:38 jsong Exp $ */
/*Version $RCSfile: ice.c,v $*/

/* standard include files */
#include <tcl.h>
//#include <tk.h>

/* local include files */
#include "tcl_macros.h"
#include "ice_cal.h"
#include "ice_auth.h"
#include "analyzePeak.h"
#include "image_channel.h"
#include "matrix_cmd.h"
#include "ssl_cmd.h"
#include "dcs_message_parse.h"
#include "fitFunction.h"
#include "findMax.h"
#include "imageScale.h"

extern "C" {	
	 int Dcs_c_library_Init ( Tcl_Interp *interp );

	 int Dcs_c_library_Init ( Tcl_Interp *interp )
		 {
		 REGISTER_TCL_COMMAND( cal_find_peak );
		 REGISTER_TCL_COMMAND( cal_correct_energy );
		 REGISTER_TCL_COMMAND( analyzePeak );
		 REGISTER_TCL_COMMAND( poly3rdFit );
		 REGISTER_TCL_COMMAND( poly5thFit );
		 REGISTER_TCL_COMMAND( findMax );

		 //had problems compiling with Digital unix
#if defined IRIX || defined LINUX
		 REGISTER_TCL_OBJECT_COMMAND( generate_auth_response );
		 REGISTER_TCL_COMMAND(image_channel_create);
		 REGISTER_TCL_COMMAND(image_channel_delete);
		 REGISTER_TCL_COMMAND(image_channel_update);
		 REGISTER_TCL_COMMAND(image_channel_blank);
		 REGISTER_TCL_COMMAND(image_channel_load);
		 REGISTER_TCL_COMMAND(image_channel_load_complete);
		 REGISTER_TCL_COMMAND(image_channel_resize);
		 REGISTER_TCL_COMMAND(image_channel_error_happened);
		 REGISTER_TCL_COMMAND(image_channel_allocate_channels );


        Tcl_CreateCommand( interp,
                    "createNewDcsScan2DData",
                    (Tcl_CmdProc*)NewDcsScan2DDataCmd,
                    (ClientData)NULL,
                    (Tcl_CmdDeleteProc*)NULL );

		 REGISTER_TCL_OBJECT_COMMAND( DcsAxisTicks );
		 REGISTER_TCL_OBJECT_COMMAND( NewDcsStringParser );
		 REGISTER_TCL_OBJECT_COMMAND( DcsSslUtil );
		 REGISTER_TCL_OBJECT_COMMAND( imageScaleBilinear );
		 REGISTER_TCL_OBJECT_COMMAND( imageResizeBilinear );
		 REGISTER_TCL_OBJECT_COMMAND( imageSubSampleAvg );
		 REGISTER_TCL_OBJECT_COMMAND( imageDownsizeAreaSample );
#endif

		 Tcl_PkgProvide( interp, "dcs_c_library","1.0");	

		 return TCL_OK;
		 }

}
