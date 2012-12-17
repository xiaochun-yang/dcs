#include "xos.h"
#include "xos_socket.h"
#include "XosStringUtil.h"



int main(int argc, char** argv)

{	

	if (argc < 7) {
		printf("Usage gui_test <dcss host> <dcss port> <user> <sessionId> <dcss user> <dcss sessionId>\n");
		exit(0);
	}
	
	std::string dcssHost = argv[1];
	int dcssPort = atoi(argv[2]);
	std::string user = argv[3];
	std::string sessionId = argv[4];
	std::string dcssUser = argv[5];
	std::string dcssSessionId = argv[6];
	
	
	xos_socket_address_t    address;
    xos_socket_t socket;

    // create an address structure pointing at the authentication server
    xos_socket_address_init( &address );
    xos_socket_address_set_ip_by_name( &address, dcssHost.c_str() );
    xos_socket_address_set_port( &address, dcssPort );

    // create the socket to connect to server
    if (xos_socket_create_client( &socket ) != XOS_SUCCESS) {
        printf("Failed in sendRequestLine: xos_socket_create_client");
        exit(0);
    }

    // connect to the server
    if (xos_socket_make_connection( &socket, &address ) != XOS_SUCCESS) {
        printf("Failed in xos_socket_make_connection");
        exit(0);
    }

	//initialize the input buffers for the socket messages
	dcs_message_t dcsMessage;
	xos_initialize_dcs_message( &dcsMessage, 10, 10 );

	std::string str(" Se K blctlxxsim 9000 15000 0.045 {12458.0 1204.14653412 12488.0 1134.92732047 12508.0 1304.57549481 12526.5 1192.58528105 12543.5 1167.11032939 12559.0 1092.39715232 12573.0 1090.93451871 12585.5 1291.81938126 12596.5 1197.95222123 12606.0 1062.0786337 12614.0 1254.72383381 12620.5 1037.03632144 12625.5 1130.47151716 12628.0 1112.35076205 12629.0 1235.79722383 12630.0 1205.89436219 12631.0 1023.02183872 12632.0 1252.57926433 12633.0 1098.26828218 12634.0 1211.4038622 12635.0 1237.88478778 12636.0 1029.20603011 12637.0 1103.53525939 12638.0 992.421589736 12639.0 985.883132275 12640.0 994.271357943 12641.0 1100.97857786 12642.0 1022.05747535 12643.0 1007.9084469 12644.0 1109.35916623 12645.0 956.075020358 12646.0 956.446151418 12647.0 953.728541412 12648.0 1146.61961761 12649.0 1112.40979459 12650.0 1021.6562531 12651.0 942.599619063 12652.0 1074.57681418 12653.0 937.506980215 12654.0 1114.5267356 12655.0 1004.28782374 12656.0 912.490886831 12657.0 1000.78408728 12658.0 957.106071434 12659.0 927.052428185 12660.0 957.06272933 12661.0 994.145622326 12662.0 869.318531083 12663.0 872.858104571 12664.0 940.673315639 12665.0 965.214517686 12666.0 896.867630577 12667.0 881.38394627 12668.0 937.404939061 12669.0 891.728277825 12670.0 920.802358495 12671.0 946.396830985 12672.0 831.111449912 12673.0 847.90552647 12674.0 903.087255382 12675.0 831.988224772 12676.0 934.459177266 12677.0 939.075708327 12678.0 814.707419962 12679.0 860.356852903 12680.0 915.668997452 12681.0 810.79505503 12682.0 865.005067376 12683.0 939.274027825 12684.0 788.103347296 12685.0 879.100742755 12686.0 767.138506731 12687.0 899.203147987 12688.0 825.2095099 12689.5 800.920988972 12693.0 770.471149764 12698.0 885.299848046 12704.5 743.821817636 12712.5 722.251639368 12722.0 779.808039674 12733.0 812.096572462 12745.5 768.065221597 12759.5 793.040722393 12775.0 695.111976386 12792.0 760.109871649 12810.5 823.796184894 12838.0 799.61638412 12868.0 783.154694923}");

	std::string msg;
	std::string rootName;
	int count = 0;
	std::string operationId;
	while (count < 2) {
		
		++count;
		
		operationId = "1." + XosStringUtil::fromInt(count);
		rootName = "dataset" + XosStringUtil::fromInt(count);
		
		msg = "stoh_start_operation runAutochooch " + operationId
				+ " " + user + " " + sessionId + " /data/" + user + "/autochooch/ " + rootName
				+ " " + dcssUser + " " + dcssSessionId + " /data/" + dcssUser + "/dcss"
				+ str;
				
		printf("sending message: %s\n", msg.c_str());

		
		// Send a request
		if (xos_send_dcs_text_message (&socket, msg.c_str()) != XOS_SUCCESS)
			xos_error_exit("Failed to send dcs request message");
			    			
    
    	xos_thread_sleep(100);
	
	} // loop forever
	
    xos_thread_sleep(1000);

	printf("sending message stoh_abort_all\n");

	// Send a request
	if (xos_send_dcs_text_message (&socket, "stoh_abort_all") != XOS_SUCCESS)
		xos_error_exit("Failed to send dcs request message");
	
	printf("Hit any key to exit"); fflush(stdout);
	getchar();
	
	xos_destroy_dcs_message(&dcsMessage);
	xos_socket_destroy(&socket);
	
	

	
	return 0;
}

