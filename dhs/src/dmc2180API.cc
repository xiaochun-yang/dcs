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

#include "dmc2180API.h"
#include "log_quick.h"

xos_result_t Dmc2180::init_connection() {
	char command2[200];
	char response[200];
	int error_code;
	double storedEncoderValue[DMC2180_MAX_ENCODERS];
	/* set the host address */

	xos_socket_address_init(&serverAddress);
	LOG_INFO("get ip from hostname");

	//label = hostname;

	/* get the ip address of the dmc2180 from the hostname in the database */
	if (xos_socket_address_set_ip_by_name(&serverAddress, hostname.c_str())
			== XOS_FAILURE) {
		LOG_SEVERE1("Could not get ip address for %s\n",hostname.c_str() );
		xos_error_exit("exit!");
	};

	// Galil is open on all ports! next line not very important, but set it to 23 to follow
	// telnet protocol.
	xos_socket_address_set_port(&serverAddress, 23);

	LOG_INFO("Dmc2180:: init_connection -- create socket");
	/* create the client socket */
	if (xos_socket_create_client(&socket) == XOS_FAILURE) {
		xos_error("Error creating DCS client socket.");
		return XOS_FAILURE;
	}

	LOG_INFO("Dmc2180:: init_connection -- connect to dmc2180");
	/* connect to the dmc2180 and return result */
	if (xos_socket_make_connection(&socket, &serverAddress) == XOS_SUCCESS) {
		LOG_INFO1("Socket connected for %s\n", hostname.c_str() );
	} else {
		LOG_WARNING1("Could not create socket for %s\n", hostname.c_str());
		return XOS_FAILURE;
	}

	/* Before the RS, we need to read the encoder values, which will be cleared */
	for (int axis = 0; axis < DMC2180_MAX_ENCODERS; axis++) {
		if (relativeEncoder[axis].axisUsed) {
			relativeEncoder[axis].get_current_position(
					&storedEncoderValue[axis]);
		}
	}

	execute("RS", response, &error_code, FALSE );
	if (error_code != 0) {
		LOG_WARNING("Could not execute RS\n");
		return XOS_FAILURE;
	}

	execute("AB 0", response, &error_code, FALSE );
	if (error_code != 0) {
		LOG_WARNING("Could not execute AB\n");
		return XOS_FAILURE;
	}

	// Restore the encoder values now that we have completed the RS
	for (int axis = 0; axis < DMC2180_MAX_ENCODERS; axis++) {
		if (relativeEncoder[axis].axisUsed) {
			relativeEncoder[axis].set_position(storedEncoderValue[axis]);
		}
	}

	LOG_INFO1("Download script to %s\n", hostname.c_str() );
	/*Load scripts to be executed at DMC2180 level.*/
	if ((download(response, &error_code) == XOS_FAILURE)) {
		LOG_SEVERE("Could NOT download programs into DMC 2180");
		return XOS_FAILURE;
	}

	LOG_WARNING1("error = %d\n", error_code );

	if (error_code != 0) {
		LOG_SEVERE("galil script download error\n");
		return XOS_FAILURE;
	} else {
		LOG_INFO("galil program download complete");
	}

	//command the dmc2180 to close all sockets
	        if ( (execute("XQ #AUTO",response, &error_code,FALSE) == XOS_FAILURE) || (error_code !=0))
        {
                LOG_INFO1("%s\n",response);
                LOG_SEVERE1("dmc2180::init_connection: executing script AUTO returned error = %d\n", error_code );
                xos_error_exit("");
                return XOS_FAILURE;
        };
        //LOG_INFO1("yangxx %s\n",response);

	if ((execute("XQ #ShutAll,1", response, &error_code, FALSE) == XOS_FAILURE)
			|| (error_code != 0)) {
		LOG_INFO1("%s\n",response);
		LOG_SEVERE1("dmc2180::init_connection: executing script CloseALL returned error = %d\n", error_code );
		xos_error_exit("");
		return XOS_FAILURE;
	};

	LOG_INFO("disconnect as cleanly as possible");
	//disconnect as cleanly as possible
	if (xos_socket_destroy(&socket) != XOS_SUCCESS) {
		xos_error("Dmc2180::init_connection -- error disconnecting socket");
	};

	LOG_INFO("wait two seconds before connecting");
	//wait 2 seconds before reconnecting
	xos_thread_sleep(2000);

	xos_socket_address_init(&serverAddress);
	LOG_INFO("get ip from hostname");

	//label = hostname;

	/* get the ip address of the dmc2180 from the hostname in the database */
	if (xos_socket_address_set_ip_by_name(&serverAddress, hostname.c_str())
			== XOS_FAILURE) {
		LOG_SEVERE1("Could not get ip address for %s\n",hostname.c_str() );
		xos_error_exit("exit!");
	};

	//Galil is open on all ports! next line not very important
	xos_socket_address_set_port(&serverAddress, 23);

	LOG_INFO("Dmc2180:: init_connection -- create socket");
	/* create the client socket */
	if (xos_socket_create_client(&socket) == XOS_FAILURE) {
		xos_error("Error creating DCS client socket.");
		xos_error_exit("");
		return XOS_FAILURE;
	}

	/* reconnect to the dmc2180 */
	if (xos_socket_make_connection(&socket, &serverAddress) == XOS_SUCCESS) {
		LOG_INFO1("Socket reconnected for %s\n", hostname.c_str() );
	} else {
		LOG_SEVERE1("Could not recreate socket for %s\n", hostname.c_str());
		xos_error_exit("");
		return XOS_FAILURE;
	}

	LOG_INFO("Start an unsolicited message handler.");
	// create the server socket, but do not specify the port
	// allow the xos_socket_create_server set the port
	while (xos_socket_create_server(&unsolicitedHandler, 0) != XOS_SUCCESS) {
		LOG_WARNING("Error creating socket.");
		return XOS_FAILURE;
	}

	LOG_INFO("Initialize the thread-listening semaphore");
	if (xos_semaphore_create(&newThreadListening, 0) == XOS_FAILURE)
		xos_error_exit("dmc2180_initialize -- semaphore initialization failed");

	LOG_INFO("Create a thread to handle the client over the new socket");
	if (xos_thread_create(&unsolicitedMessageThread,
			dmc2180_unsolicited_handler, (void *) this) != XOS_SUCCESS) {
		LOG_SEVERE("Thread creation unsuccessful.");
		xos_error_exit("Exit");
	} else {
		// wait for new thread to start listening 
		if (xos_semaphore_wait(&newThreadListening, 0) != XOS_SUCCESS) {
			LOG_SEVERE("Error waiting on semaphore");
			xos_error_exit("Exit.");
		}
	}

	xos_socket_address_t tempAddress;
	byte tempIPArray[4];

	//Get the system name that DHS is running on
	//	if ( gethostname( systemHostname,100) == -1)
	//	{
	//	xos_error_exit("main -- The local hostname is unknown\n");
	//	}

	LOG_INFO("Get IP address of the current machine");
	xos_socket_address_init(&tempAddress);
	xos_socket_address_set_ip_by_name(&tempAddress, mPrivateHostname.c_str());
	xos_socket_address_get_ip(&tempAddress, tempIPArray);

	sprintf(command2, "MG _IHF2");
	execute(command2, response, &error_code, FALSE);

	LOG_INFO("Create message to report new port number to dmc2180");
	sprintf(command2, "IHF=%d,%d,%d,%d <%d >2", tempIPArray[0], tempIPArray[1],
			tempIPArray[2], tempIPArray[3], xos_socket_get_local_port(
					&unsolicitedHandler));

	LOG_INFO(command2);
	execute(command2, response, &error_code, FALSE);

	if (error_code != 0)
		LOG_INFO1("%s \n" ,response);

	sprintf(command2, "MG _IHF0");
	execute(command2, response, &error_code, FALSE);

	sprintf(command2, "MG _IHF1");
	execute(command2, response, &error_code, FALSE);

	sprintf(command2, "MG _IHF3");
	execute(command2, response, &error_code, FALSE);

	//	LOG_INFO(response);
	if (error_code != 0) {
		xos_error(
				"dmc2180_initialize -- could not initialize asynchronous message port.\n");
		return XOS_FAILURE;
	}

	LOG_INFO("connect complete");

	assertLimitSwitchPolarity();

	assertSampleRate();
/*
	execute(command2, response, &error_code, FALSE );
	if (error_code != 0) {
		LOG_WARNING("Could not set CN\n");
		return XOS_FAILURE;
	}
*/
	return XOS_SUCCESS;
}

xos_result_t Dmc2180::execute(char * command, char * response,
		int * error_code, xos_boolean_t silent) {

	int number_of_commands = 1;
	char * next_cmd;
	char * temp_cmd;
	xos_boolean_t error;

	//timespec time_stamp;
	//long start_time;

	temp_cmd = command;
	while ((next_cmd = strchr(temp_cmd, ';')) != NULL) {
		number_of_commands++;
		temp_cmd = next_cmd + 1;
	}

	//	clock_gettime( CLOCK_REALTIME, &time_stamp );
	//start_time = time_stamp.tv_nsec + time_stamp.tv_sec * 1000000000;

	//printf("found %d commands\n",number_of_commands);

	if (send_message(command, silent) == XOS_FAILURE) {
		LOG_WARNING("Could not send command");
		return XOS_FAILURE;
	};

	error = FALSE;
	/* we must get a ? or a : for each command sent */
	for (int cmd_cnt = 0; cmd_cnt < number_of_commands; cmd_cnt++) {
		if (get_response(response, error_code, silent) == XOS_FAILURE) {
			LOG_WARNING1("dmc2180 command returned error: %d\n", *error_code);
			LOG_WARNING1("%s\n", response);
			error = TRUE;
		}
	}

	if (error == TRUE) {
		send_message("TC 1", FALSE);
		/*get first character from response*/
		if (get_response(response, error_code, silent) == XOS_FAILURE) {
			LOG_WARNING1("Dmc2180::send_command returned_error: %d\n", *error_code);
			LOG_WARNING1("%s", response);
		} else {
			*error_code = atoi(response);
		}
	}

	return XOS_SUCCESS;
}

xos_result_t Dmc2180::download(char * response, int * error_code) {
	//	char * buffer;
	//	buffer = new char [(strlen(script.c_str() ) + 20)];
	//	sprintf( buffer, "DL%c%c%s%c%c\\",13,10,script.c_str() ,13,10);

	//	printf("download_to_dmc2180-> %s", script.c_str() );
	if (xos_socket_write(&socket, script.c_str(), script.length())
			!= XOS_SUCCESS) {
		LOG_WARNING("socket write fail\n");
		return XOS_FAILURE;
	}

	if (get_response(response, error_code, FALSE ) == XOS_FAILURE) {
		LOG_WARNING1("ERROR: %s\n",response);
		while (response[0] == '?') {
			LOG_WARNING1("%s\n",response);
			get_response(response, error_code, FALSE );
		}

		LOG_WARNING1("Download returned_error: %d\n", *error_code);
		//		delete buffer;
		return XOS_FAILURE;
	} else {
		LOG_INFO1("Download successful: %s\n",response);
	}

	//delete buffer;
	return XOS_SUCCESS;
}

xos_result_t Dmc2180::assertLimitSwitchPolarity() {
	char command[200];
	char response[200];

	int error_code;
	sprintf(command, "MG _CN");

	execute(command, response, &error_code, FALSE );

	if (error_code != 0) {
		LOG_SEVERE("Could not get motor type\n");
		return XOS_FAILURE;
	}

	if ( atoi(response) != atoi(limitSwitchPolarity.c_str()) ) {
		LOG_SEVERE2("Limit switch polarity did not match expected type. Expected '%d'. Current '%d'.",
				atoi( limitSwitchPolarity.c_str()),
				atoi( response) );
		LOG_SEVERE("To override the limit switch polarity, add to configuration file, galil.limitSwitchPolarity=1 or galil.limitSwitchPolarity=-1");

		xos_thread_sleep(1000);
		xos_error_exit(
				"Limit switch polarity should be set and burned on galil with CN command.");
	}

	return XOS_SUCCESS;
}

xos_result_t Dmc2180::assertSampleRate() {
	char command[200];
	char response[200];

	int error_code;
	sprintf(command, "MG _TM");

	execute(command, response, &error_code, FALSE );

	if (error_code != 0) {
		LOG_SEVERE("Could not get motor type\n");
		return XOS_FAILURE;
	}

	if ( atoi(response) != atoi(sampleRateMs.c_str()) ) {
		LOG_SEVERE2("SamplingRate did not match expected sample rate '%d'. Current '%d'.",
				atoi( sampleRateMs.c_str()),
				atoi( response) );
		LOG_SEVERE1("To override the limit switch polarity, add to configuration file, e.g. galil.sampleRateMs=%d", atoi(response));

		xos_thread_sleep(1000);
		xos_error_exit(
				"Sample rate should be set and burned on galil with TM command.");
	}

	return XOS_SUCCESS;
}

xos_result_t Dmc2180::send_message(char * message, xos_boolean_t silent) {
	char buffer2[200];
	sprintf(buffer2, "%s%c%c", message, 13, 10);

	if (xos_socket_write(&socket, buffer2, strlen(buffer2)) == XOS_SUCCESS) {
//LOG_INFO1("yangx message is sent to galil %s", buffer2);
		if (!silent) {
			LOG_INFO2("%s-> %s",hostname.c_str(), buffer2);
		}
		return XOS_SUCCESS;
	} else {
		LOG_WARNING("socket write fail\n");
		return XOS_FAILURE;
	}
}

xos_result_t Dmc2180::get_response(char * buffer, int *error_code, xos_boolean_t silent) {
	int cnt = 0;
	xos_boolean_t end_message = FALSE;
	xos_boolean_t error = FALSE;

	*error_code = 0;

	/* block until message arrives from server */
	if (xos_socket_wait_until_readable(&socket, 0) != XOS_WAIT_SUCCESS) {
		LOG_WARNING("Error waiting for message from DCS server.");
		return XOS_FAILURE;
	}

	/* read a message from the dmc2180 */
	while (cnt < 200 && end_message == FALSE) {

		if (xos_socket_read(&socket, &buffer[cnt], 1) == XOS_FAILURE) {
			LOG_WARNING("Error reading controller.");
			break;
		}

		buffer[cnt] = buffer[cnt] & 0x7f;

		switch (buffer[cnt]) {
		case ':':
			error = FALSE;
			end_message = TRUE;
			break;
		case '?':
			error = TRUE;
			end_message = TRUE;
			break;
		case 26:
			LOG_INFO("ctrl-z");
			error = FALSE;
			end_message = TRUE;
			break;
		case '\\':
			error = FALSE;
			end_message = TRUE;
			break;
		default:
			break;
		}
		cnt++;
	}

	buffer[cnt] = 0;

	if (!silent) {
		LOG_INFO2("%s -> %s\n",hostname.c_str(),buffer);
	}
	if (error == TRUE) {
		return XOS_FAILURE;
	}

	return XOS_SUCCESS;
}

Dmc2180::Dmc2180() {
	char AxisLabels[9] = "XYZWEFGH";

	/* table mapping motor axis labels to an index*/
        axisLabels["A"] = 0; axisLabels["a"] = 0; axisLabels["X"] = 0; axisLabels["x"] = 0;
        axisLabels["B"] = 1;    axisLabels["b"] = 1;    axisLabels["Y"] = 1; axisLabels["y"] = 1;
        axisLabels["C"] = 2;    axisLabels["c"] = 2;    axisLabels["Z"] = 2; axisLabels["z"] = 2;
        axisLabels["D"] = 3;    axisLabels["d"] = 3;    axisLabels["W"] = 3; axisLabels["w"] = 3;
        axisLabels["E"] = 4;    axisLabels["e"] = 4;
        axisLabels["F"] = 5;    axisLabels["f"] = 5;
        axisLabels["G"] = 6;    axisLabels["g"] = 6;
        axisLabels["H"] = 7;    axisLabels["h"] = 7;

/*	axisLabels["A"] = 0;
	axisLabels["a"] = 0;
	axisLabels["X"] = 0;
	axisLabels["x"] = 0;
	axisLabels["B"] = 1;
	axisLabels["b"] = 1;
	axisLabels["Y"] = 1;
	axisLabels["y"] = 1;
	axisLabels["C"] = 2;
	axisLabels["c"] = 2;
	axisLabels["Z"] = 2;
	axisLabels["z"] = 2;
	axisLabels["D"] = 3;
	axisLabels["d"] = 3;
	axisLabels["W"] = 3;
	axisLabels["w"] = 3;
	axisLabels["E"] = 4;
	axisLabels["e"] = 4;
	axisLabels["F"] = 5;
	axisLabels["f"] = 5;
	axisLabels["G"] = 6;
	axisLabels["g"] = 6;
	axisLabels["H"] = 7;
	axisLabels["h"] = 7;
*/
	/* initialize usage array for axes */
	for (int axis = 0; axis < DMC2180_MAX_AXES; axis++) {
		motor[axis].axisUsed = FALSE;
		motor[axis].axisLabel = AxisLabels[axis];
		motor[axis].axisIndex = axis;
		motor[axis].dmc2180 = this; //allows motor to access controller data
	}

	/* initialize usage array for axes */
	for (int channel = 0; channel < DMC2180_MAX_SHUTTERS; channel++) {
		shutter[channel].channel_used = FALSE;
		shutter[channel].channel = channel + 1;
		shutter[channel].dmc2180 = this; //allows motor to access controller data
	}

	/* initialize usage array for axes */
	for (int axis = 0; axis < DMC2180_MAX_ENCODERS; axis++) {
		relativeEncoder[axis].axisUsed = FALSE;
		relativeEncoder[axis].axisLabel = AxisLabels[axis];
		relativeEncoder[axis].axisIndex = axis;
		relativeEncoder[axis].dmc2180 = this; //allows motor to access controller data
	}

	/* initialize usage array for axes */
	for (int axis = 0; axis < DMC2180_MAX_ANALOG_ENCODERS; axis++) {
		analogEncoder[axis].axisUsed = FALSE;
		analogEncoder[axis].axisLabel = AxisLabels[axis];
		analogEncoder[axis].axisIndex = axis;
		analogEncoder[axis].dmc2180 = this; //allows motor to access controller data
	}

	for (int axis = 0; axis < DMC2180_MAX_ABSOLUTE_ENCODERS; axis++) {
		absoluteEncoder[axis].axisUsed = FALSE;
		absoluteEncoder[axis].axisLabel = AxisLabels[axis];
		absoluteEncoder[axis].axisIndex = axis;
		absoluteEncoder[axis].dmc2180 = this; //allows motor to access controller data
	}

}

Dmc2180::~Dmc2180() {
	LOG_INFO("Dmc2180::destructor -- disconnect from Dmc2180\n");
	if (xos_socket_destroy(&socket) == XOS_FAILURE) {
		LOG_INFO("Dmc2180::destructor -- failure closing socket\n");
	} else {
		LOG_INFO("Dmc2180::destructor -- success closing socket\n");
	}
}

int Dmc2180::isVectorActive() {
	LOG_INFO1("Vector active -> %d\n",active);
	return (active);
}

xos_result_t Dmc2180::setVectorActive(xos_boolean_t status) {
	active = status;
	LOG_INFO1("Set vector active %d\n",active);
	return XOS_SUCCESS;
}

xos_result_t Dmc2180::setNumVectorComponents(int Num) {

	if ((Num == 1) || (Num == 2)) {
		numComponents = Num;
		//LOG_INFO1("stored active components %d\n",numComponents);
		return XOS_SUCCESS;

	} else {
		LOG_WARNING1("Num Components %d\n",numComponents);
		return XOS_FAILURE;
	}
}

/*This command checks the status of each motor of the card
 and determines if it is part of a vector move*/
xos_boolean_t Dmc2180::checkVectorComplete() {
	xos_index_t axisIndex;

	/*is this card still involved in a vector sequence?*/
	if (isVectorActive() == FALSE)
		return FALSE;

	/*Find any motors involved in the sequence*/
	for (axisIndex = 0; axisIndex < DMC2180_MAX_AXES; axisIndex++) {
		//		dhs_database_get_device_mutex( deviceIndex[axisIndex] );

		if (motor[axisIndex].isVectorComponent == TRUE) {
			return XOS_SUCCESS;
		}
	}

	/*only come here if no motors involved in vector move*/
	setVectorActive(FALSE);
	LOG_INFO1("Vector move is complete %s\n", hostname.c_str() );

	return TRUE;
}

/*This member function stores the motor's configuration in */
/*the dmc2180 class.*/
xos_result_t Dmc2180::motor_store_stepper_configuration(char * axisCharacter,
		int * index) {
	axis2index::iterator lookup;

	/* lookup axis string in hash table */
	lookup = axisLabels.find(string(axisCharacter));

	if (lookup == axisLabels.end()) {
		LOG_WARNING1("motor axis %s not supported", axisCharacter );
		return XOS_FAILURE;
	}

	*index = (*lookup).second;
	LOG_INFO2("Found %s on axis %d\n", (*lookup).first.c_str(), *index );

	/* make sure axis is not already in use */
	if (motor[*index].axisUsed == TRUE) {
		LOG_WARNING1("Motor axis %s already used", motor[*index].axisLabel );
		return XOS_FAILURE;
	}

	// log this axis as USED
	motor[*index].axisUsed = TRUE;
	motor[*index].isStepper = TRUE;
	return XOS_SUCCESS;
}

/*This member function stores the motor's configuration in */
/*the dmc2180 class.*/
xos_result_t Dmc2180::motor_store_servo_configuration(char * axisCharacter,
		int * index, char * derivative, char * proportional, char * integrator,
		xos_boolean_t servoBetweenMoves) {
	axis2index::iterator lookup;

	/* lookup axis string in hash table */
	lookup = axisLabels.find(string(axisCharacter));

	LOG_INFO2("Found %s on axis %d\n", (*lookup).first.c_str(), (*lookup).second );

	if (lookup == axisLabels.end()) {
		LOG_WARNING1("Motor axis %s not supported", axisCharacter );
		return XOS_FAILURE;
	} else
		*index = (*lookup).second;

	/* make sure axis is not already in use */
	if (motor[*index].axisUsed == TRUE) {
		LOG_WARNING1("Motor axis %s already used", motor[*index].axisLabel );
		return XOS_FAILURE;
	}

	// log this axis as USED
	motor[*index].axisUsed = TRUE;

	//motor is a dc servo motor
	motor[*index].isStepper = FALSE;
	//assign the PID parameters
	motor[*index].PIDderivative = derivative;
	motor[*index].PIDproportional = proportional;
	motor[*index].PIDintegrator = integrator;
	motor[*index].servoBetweenMoves = servoBetweenMoves;

	return XOS_SUCCESS;
}

xos_result_t Dmc2180_motor::timedExposure(
		dhs_motor_start_oscillation_message_t & exposeCmd) {
	if (isStepper)
		return timedExposureStepperMotor(exposeCmd);
	else
		return timedExposureServoMotor(exposeCmd);
}

xos_result_t Dmc2180_motor::timedExposureStepperMotor(
		dhs_motor_start_oscillation_message_t & exposeCmd) {
	/* local variables */
	char buffer[1000];

	dcs_unscaled_t exposureEnd_counts;

	dcs_unscaled_t exposureRange_counts;
	dcs_unscaled_t exposureVelocity_counts_per_s;
	//dcs_scaled_t accelerationTime_s;
	dcs_unscaled_t accelerationDistance_counts;
	int error_code;
	string exposureScriptName;
	//int outputCompareDirection;
    //detectorTriggerDelay_s: Shutter needs to open first, then delay detector signal (e.g. for pilatus) to give the shutter time to open. 
	//dcs_scaled_t detectorTriggerDelay_s = 0.04096;
	//dcs_unscaled_t motorError_counts = 50;
    int galilSampleRate = 1000;
    double ks_value = 1.313; //Must match the KS command in the galil script file (i.e. huber.txt).
    double tau = ks_value * 4.5;
    double velocityErr = 0.01;  //error in velocity
    

	set_speed(); //set the speed in case the slew speed has been changed last time through this code.

	dcs_unscaled_t exposureStart_counts = SCALED2UNSCALED( exposeCmd.startPosition , scaleFactor);
    LOG_INFO1("scaleFactor: %f steps/deg ", scaleFactor );

	dcs_scaled_t exposureEnd_degrees = exposeCmd.startPosition
			+ exposeCmd.oscRange;

	exposureEnd_counts = SCALED2UNSCALED(exposureEnd_degrees , scaleFactor);
	exposureRange_counts = SCALED2UNSCALED(exposeCmd.oscRange , scaleFactor);
    LOG_INFO1("exposureDelta: %f deg ", exposeCmd.oscRange);
    LOG_INFO1("exposureDelta: %d step", exposureRange_counts);

	/* calculate speed of oscillation */
	exposureVelocity_counts_per_s = (long) ((double) exposureRange_counts
			/ exposeCmd.oscTime);

    dcs_unscaled_t exposureVelocity_counts_per_sample = exposureVelocity_counts_per_s / galilSampleRate;

    LOG_INFO1("exposureVelocity: %d step/s", exposureVelocity_counts_per_s);
    if ( exposureVelocity_counts_per_s > speed ) {
        LOG_WARNING("data collection requested speed exceeding phi configuration" );
		return XOS_FAILURE;
    }

	/* minimum speed is 1 steps/sec */
	if (exposureVelocity_counts_per_s < 1) {
        LOG_WARNING("data collection requested speed minimum is 1 count per second" );
		return XOS_FAILURE;
    }

	/* get acceleration rate */
	dcs_scaled_t acceleration_counts_per_ss = speed * 1000 / accelerationTime; 
    LOG_INFO1("accelerationRate: %d steps/s^2", acceleration_counts_per_ss);

    //get acceleration rate counts / samples^2
	dcs_scaled_t acceleration_counts_per_sampleSqrd = acceleration_counts_per_ss / (galilSampleRate * galilSampleRate); 
    LOG_INFO1("accelerationRate: %f steps/sample^2", acceleration_counts_per_sampleSqrd);

	//accelerationTime_s = exposureVelocity_counts_per_s / (dcs_scaled_t)acceleration_counts_per_ss;
    //LOG_INFO1("rampTime: %f", accelerationTime_s);

	/* what distance to ramp up in? */
    double alpha = - tau * log ( velocityErr );
    double tprime_samples = exposureVelocity_counts_per_sample  / acceleration_counts_per_sampleSqrd ;
    accelerationDistance_counts = (dcs_unscaled_t)(0.5 * exposureVelocity_counts_per_sample * tprime_samples + exposureVelocity_counts_per_sample * alpha);

    LOG_INFO1("rampDistance: %d (counts)", accelerationDistance_counts);

	//dcs_unscaled_t shutterOpenTrigger_counts;
	//dcs_unscaled_t initialPosition_counts;

    //distance traveled is the remaining distance at constant speed before the exposure
    //dcs_unscaled_t detectorTriggerDelay_counts = (dcs_unscaled_t)( exposureVelocity_counts_per_s * detectorTriggerDelay_s );
	//initialPosition_counts = exposureStart_counts - detectorTriggerDelay_counts - accelerationDistance_counts - motorError_counts;
    //shutterOpenTrigger_counts = exposureStart_counts - detectorTriggerDelay_counts;
    //printf("detectorTriggerDelay_counts: %ld\n", detectorTriggerDelay_counts);

	//dcs_unscaled_t distanceToShutterOpen_counts = acceleration_counts_per_ss * ((dcs_unscaled_t)(shutterOpenTrigger_s * shutterOpenTrigger_s)) / 2;
	//dcs_unscaled_t initialPosition_counts = exposureStart_counts - distanceToShutterOpen_counts - motorError_counts;

	//dcs_unscaled_t overshootPosition_counts = exposureEnd_counts + accelerationDistance_counts  + motorError_counts;

	if (exposeCmd.useShutter == TRUE) {
		exposureScriptName = "Expose";
	} else {
		exposureScriptName = "NoExps";
	}

	//handle the reverse motors
	int directionSign = reverse ? -1 : 1;
	//shutterOpenTrigger_counts *= directionSign;
	exposureStart_counts *= directionSign;
	exposureEnd_counts *= directionSign;
	exposureVelocity_counts_per_s *= directionSign;
	accelerationDistance_counts *= directionSign;
	//initialPosition_counts *= directionSign;
	//overshootPosition_counts *= directionSign;

	//if (initialPosition_counts < overshootPosition_counts) {
	//	outputCompareDirection = 0;
	//} else {
		//see galil manual regarding OC command on shot setup in reverse direction.
	//	outputCompareDirection = -65536;
	//}

	// ExpStart...Exposure Start: phi location where shutter should open
	// ExpEnd...Exposure End: phi location where shutter should close
	// ExpVel...Exposure Velocity: speed of the motor during the exposure
	// ReadyPos..position from which the phi can ramp up to speed before hitting the ExpStart position.
	sprintf(buffer, "~a=\"%c\";"
        "KSVal=%f;"
        "ShutCh=%d;"
		"ExpStart=%ld;"
		//"ShutOpen=%ld;"
		"ExpEnd=%ld;"
		"ExpVel=%ld;"
		"RampCnt=%ld;"
		//"ReadyPos=%ld;"
		//"OverPos=%ld;"
		//"OcDir=%d;"
		"XQ #%s,3", axisLabel, ks_value, exposeCmd.shutterChannel, exposureStart_counts, /*shutterOpenTrigger_counts,*/
			exposureEnd_counts, exposureVelocity_counts_per_s, accelerationDistance_counts, /*initialPosition_counts,*/
			/*overshootPosition_counts, outputCompareDirection,*/
			exposureScriptName.c_str());

//LOG_INFO1("yangxx a=%c\n", axisLabel);

	if (controller_execute(buffer, &error_code, FALSE ) == XOS_FAILURE)
		return XOS_FAILURE;

	isScriptParticipant = TRUE;
    scriptThreadNumber =3;

	return XOS_SUCCESS;
}

xos_result_t Dmc2180_motor::timedExposureServoMotor(
		dhs_motor_start_oscillation_message_t & exposeCmd) {
	/* local variables */
	char buffer[1000];

	dcs_unscaled_t exposureEnd_counts;

	dcs_unscaled_t exposureRange_counts;
	dcs_unscaled_t exposureVelocity_counts_per_s;
	dcs_scaled_t accelerationTime_s;
	dcs_unscaled_t accelerationDistance_counts;
	int error_code;
	string exposureScriptName;
	int outputCompareDirection;
	dcs_scaled_t detectorTriggerDelay_s = 0.04096;  //delay in hardware for triggering detector (e.g. for pilatus)
	dcs_unscaled_t motorError_counts = 50;

	set_speed(); //set the speed in case the slew speed has been changed last time through this code.

	dcs_unscaled_t exposureStart_counts = SCALED2UNSCALED( exposeCmd.startPosition , scaleFactor);
    LOG_INFO1("scaleFactor: %f steps/deg ", scaleFactor );

	dcs_scaled_t exposureEnd_degrees = exposeCmd.startPosition
			+ exposeCmd.oscRange;

	exposureEnd_counts = SCALED2UNSCALED(exposureEnd_degrees , scaleFactor);
	exposureRange_counts = SCALED2UNSCALED(exposeCmd.oscRange , scaleFactor);
    LOG_INFO1("exposureDelta: %f deg ", exposeCmd.oscRange);
    LOG_INFO1("exposureDelta: %d step", exposureRange_counts);

	/* calculate speed of oscillation */
	exposureVelocity_counts_per_s = (long) ((double) exposureRange_counts
			/ exposeCmd.oscTime);
    LOG_INFO1("exposureVelocity: %d step/s", exposureVelocity_counts_per_s);
    if ( exposureVelocity_counts_per_s > speed ) {
        LOG_WARNING("data collection requested speed exceeding phi configuration" );
		return XOS_FAILURE;
    }

	/* minimum vector speed is 2 steps/sec */
	if (exposureVelocity_counts_per_s < 1)
		exposureVelocity_counts_per_s = 1;

	/* get acceleration rate */
	//accelerationRate = (exposureVelocity * 1000) / acceleration;
	//dcs_scaled_t accelerationRate = speed * 1000 / accelerationTime; // steps/s^2

    //
	//dcs_unscaled_t acceleration_counts_per_ss = int(speed * 1000 / accelerationTime); // steps/s^2
    //hard coding to 60000 because it is also in the galil script.  If it is removed from the galil script, it fails to trigger the outpot compare.
	dcs_unscaled_t acceleration_counts_per_ss = 100000; // steps/s^2
    LOG_INFO1("accelerationRate: %d steps/s^2", acceleration_counts_per_ss);

	accelerationTime_s = exposureVelocity_counts_per_s / (dcs_scaled_t)acceleration_counts_per_ss;
    LOG_INFO1("rampTime: %f", accelerationTime_s);

	/* what distance to ramp up in? */
	//accelerationDistance_counts = (dcs_unscaled_t)((accelerationRate_counts_per_ss * accelerationTime_s * accelerationTime_s) / 2.0);
	accelerationDistance_counts = (dcs_unscaled_t)( exposureVelocity_counts_per_s * exposureVelocity_counts_per_s  ) / (2 * acceleration_counts_per_ss);

    LOG_INFO1("rampDistance: %d", accelerationDistance_counts);

	dcs_unscaled_t shutterOpenTrigger_counts;
	dcs_unscaled_t initialPosition_counts;

    //distance traveled is the remaining distance at constant speed before the exposure
    dcs_unscaled_t detectorTriggerDelay_counts = (dcs_unscaled_t)( exposureVelocity_counts_per_s * detectorTriggerDelay_s );
	initialPosition_counts = exposureStart_counts - detectorTriggerDelay_counts - accelerationDistance_counts - motorError_counts;
    shutterOpenTrigger_counts = exposureStart_counts - detectorTriggerDelay_counts;
    printf("detectorTriggerDelay_counts: %ld\n", detectorTriggerDelay_counts);

	//dcs_unscaled_t distanceToShutterOpen_counts = acceleration_counts_per_ss * ((dcs_unscaled_t)(shutterOpenTrigger_s * shutterOpenTrigger_s)) / 2;
	//dcs_unscaled_t initialPosition_counts = exposureStart_counts - distanceToShutterOpen_counts - motorError_counts;

	dcs_unscaled_t overshootPosition_counts = exposureEnd_counts + accelerationDistance_counts  + motorError_counts;

	if (exposeCmd.useShutter == TRUE) {
		exposureScriptName = "Expose";
	} else {
		exposureScriptName = "NoExps";
	}

	//handle the reverse motors
	int directionSign = reverse ? -1 : 1;
	exposureStart_counts *= directionSign;
	exposureEnd_counts *= directionSign;
	exposureVelocity_counts_per_s++;
	exposureVelocity_counts_per_s *= directionSign;
	initialPosition_counts *= directionSign;
	overshootPosition_counts *= directionSign;

	if (initialPosition_counts < overshootPosition_counts) {
		outputCompareDirection = 0;
	} else {
		//see galil manual regarding OC command on shot setup in reverse direction.
		outputCompareDirection = -65536;
	}



	// ExpStart...Exposure Start: phi location where shutter should open
	// ExpEnd...Exposure End: phi location where shutter should close
	// ExpVel...Exposure Velocity: speed of the motor during the exposure
	// ReadyPos..position from which the phi can ramp up to speed before hitting the ExpStart position.
	sprintf(buffer, "~a=\"%c\";"
        "ShutCh=%d;"
		"ExpStart=%ld;"
		"ExpEnd=%ld;"
		"ExpVel=%ld;"
		"ReadyPos=%ld;"
		"OverPos=%ld;"
		"OcDir=%d;"
		"XQ #%s,3", axisLabel, exposeCmd.shutterChannel, shutterOpenTrigger_counts,
			exposureEnd_counts, exposureVelocity_counts_per_s, initialPosition_counts,
			overshootPosition_counts, outputCompareDirection,
			exposureScriptName.c_str());

//LOG_INFO1("yangxx to see a is %c \n", axisLabel);

	if (controller_execute(buffer, &error_code, FALSE ) == XOS_FAILURE)
		return XOS_FAILURE;

	isScriptParticipant = TRUE;
    scriptThreadNumber =3;
//yangx added
//   LOG_INFO1("yangx to see a is %s \n", buffer);
	return XOS_SUCCESS;
}

Dmc2180_motor::Dmc2180_motor() {
	isScriptParticipant = FALSE;
    scriptThreadNumber = -1;
	isVectorComponent = FALSE;
}

xos_result_t Dmc2180_motor::init() {
	int error_code;

	if (isStepper) {
		/* STEPPER MOTOR */
		/*STEPPER motor with active low step pulses*/
		sprintf(command, "CE%c=0", axisLabel);

		if (controller_execute(command, &error_code, FALSE ) == XOS_FAILURE) {
			xos_error("Dmc2180::initialize_motors -- Could not set motor type");
			return XOS_FAILURE;
		}

		/*don't set the motor type at initialization.  This should be burned into the galil.*/
/*		if (assertMotorType((char*) dmc2180->expectedStepperMotorType.c_str())
				== XOS_FAILURE)
			xos_error_exit(
					"Please set the expected motor type correctly in the galil using the MT command");*/
	} else {
		/*SERVO motor*/
		/* CE -> configure encoder e.g. quadrature or pulse. plus direction*/
		/* MT -> motor type. and reverse type*/
/*
		sprintf(command, "CE%c=0", axisLabel);
		controller_execute(command, &error_code, FALSE );
		if (error_code != 0) {
			xos_error("Dmc2180::initialize_motors -- could not set CE and MT\n");
			return XOS_FAILURE;
		}

		if (assertMotorType((char*) dmc2180->expectedServoMotorType.c_str())
				== XOS_FAILURE)
			xos_error_exit(
					"Please set the expected motor type correctly in the galil using the MT command");
*/
		sprintf(command, "KD%c=%s", axisLabel, PIDderivative.c_str());

		if (controller_execute(command, &error_code, FALSE ) == XOS_FAILURE) {
			xos_error(
					"Dmc2180::initialize_motors -- Could not set motor pid parameters");
			return XOS_FAILURE;
		}

		sprintf(command, "KP%c=%s", axisLabel, PIDproportional.c_str());

		if (controller_execute(command, &error_code, FALSE ) == XOS_FAILURE) {
			xos_error(
					"Dmc2180::initialize_motors -- Could not set motor pid parameters");
			return XOS_FAILURE;
		}

		sprintf(command, "KI%c=%s", axisLabel, PIDintegrator.c_str());

		if (controller_execute(command, &error_code, FALSE ) == XOS_FAILURE) {
			xos_error(
					"Dmc2180::initialize_motors -- Could not set motor pid parameters");
			return XOS_FAILURE;
		}

		sprintf(command, "IT%c=0.1", axisLabel);

		if (controller_execute(command, &error_code, FALSE ) == XOS_FAILURE) {
			xos_error(
					"Dmc2180::initialize_motors -- Could not set motor pid parameters");
			return XOS_FAILURE;
		}

		//turn off dc motors
		if (servoBetweenMoves) {
			sprintf(command, "SH%c", axisLabel);
		} else {
			sprintf(command, "MO%c", axisLabel);
		}
		/* construct and send message to dmc2180 */
		controller_execute(command, &error_code, FALSE);

	}

	//set the current position of the motor
	if (set_position(initPosition) == XOS_FAILURE) {
		xos_error(
				"Dmc2180::initialize_motors -- could not set motor position\n");
		return XOS_FAILURE;
	};

	lastPosition = initPosition;

	//set the current position of the motor
	if (set_speed() == XOS_FAILURE) {
		xos_error("Dmc2180::initialize_motors -- could not set motor speed\n");
		return XOS_FAILURE;
	};

	//set the current position of the motor in the Galil
	if (set_acceleration() == XOS_FAILURE) {
		xos_error(
				"Dmc2180::initialize_motors -- could not set motor acceleration\n");
		return XOS_FAILURE;
	};

	return XOS_SUCCESS;
}

xos_result_t Dmc2180::initialize_motors() {
	int cnt;

	//loop over all of the motors
	for (cnt = 0; cnt < DMC2180_MAX_AXES; cnt++) {
		if (motor[cnt].axisUsed == TRUE) {
			if (motor[cnt].init() == XOS_FAILURE)
				return XOS_FAILURE;
		}
	}

	return XOS_SUCCESS;
}

xos_result_t Dmc2180_motor::set_position(dcs_unscaled_t new_position) {
	int error_code;

	/* set the position on the Galil board */
	sprintf(command, "DP%c=%ld", axisLabel, new_position);
	return controller_execute(command, &error_code, FALSE );
}

xos_result_t Dmc2180_motor::set_speed() {
	int error_code;

	/* set the position on the Galil board */
	sprintf(command, "SP%c=%ld", axisLabel, speed);
	return controller_execute(command, &error_code, FALSE );
}

xos_result_t Dmc2180_motor::set_acceleration() {
	int error_code;

	if (accelerationTime == 0) {
		xos_error("dmc2180_motor:set_acceleration -- acceleration is 0\n");
		return XOS_FAILURE;
	}

	/* set the acceleration on the Galil board */
	sprintf(command, "AC%c=%ld", axisLabel, speed / accelerationTime * 1000);

	if (controller_execute(command, &error_code, FALSE ) == XOS_FAILURE)
		return XOS_FAILURE;

	sprintf(command, "DC%c=%ld", axisLabel, speed / accelerationTime * 1000);

	return controller_execute(command, &error_code, FALSE );
}

xos_result_t Dmc2180_motor::set_motor_direction(dcs_flag_t reverseFlag) {
	reverse = reverseFlag;

	return XOS_SUCCESS;
}

xos_result_t Dmc2180_motor::get_current_position(dcs_unscaled_t * position) {
	int error_code;
	/* get position of axis */
	if (isStepper)
		sprintf(command, "TD%c", axisLabel);
	else
		sprintf(command, "TP%c", axisLabel);

	controller_execute(command, &error_code, FALSE );

	if (error_code == 0) {
		*position = (dcs_unscaled_t) atoi(lastResponse);
		if (reverse)
			*position *= -1;
	} else {
		xos_error("dmc2180::get_current_position\n");
		return XOS_FAILURE;
	}
	return XOS_SUCCESS;
}

xos_result_t Dmc2180RelativeEncoder::get_current_position(
		dcs_scaled_t * position) {
	LOG_INFO("Entering relative encoder\n");
	int error_code;
	/* get position of axis */

	sprintf(command, "TP%c", axisLabel);

	controller_execute(command, &error_code, FALSE );

	if (error_code == 0) {
		*position = (dcs_scaled_t) atof(lastResponse) / scale_factor;
	} else {
		LOG_WARNING("Error getting current position\n");
		return XOS_FAILURE;
	}

	return XOS_SUCCESS;
}

xos_result_t Dmc2180AnalogEncoder::get_current_position(dcs_scaled_t * position) {
	int error_code;
	/* get position of axis */

	sprintf(command, "MG @AN[%d]", axisIndex);
	controller_execute(command, &error_code, FALSE );

	if (error_code == 0) {
		*position = (dcs_scaled_t) atof(lastResponse) / scale_factor;
	} else {
		LOG_WARNING("Error getting current position\n");
		return XOS_FAILURE;
	}

	return XOS_SUCCESS;
}

xos_result_t Dmc2180AbsoluteEncoder::get_current_position(
		dcs_scaled_t * position) {
	int error_code;
	/* get position of axis */

	sprintf(command, "SS%c", axisLabel);
	controller_execute(command, &error_code, FALSE );
	sprintf(command, "MG _SS%c", axisLabel);
	controller_execute(command, &error_code, FALSE );

	if (error_code == 0) {
		*position = (dcs_scaled_t) atof(lastResponse) / scale_factor;
	} else {
		LOG_WARNING("Error getting current position\n");
		return XOS_FAILURE;
	}

	return XOS_SUCCESS;
}

xos_result_t Dmc2180AnalogEncoder::set_position(dcs_scaled_t newPosition) {
	LOG_WARNING1("analog encoder cannot be set: channel %ld\n", axisLabel);
	return XOS_SUCCESS;
}

xos_result_t Dmc2180AbsoluteEncoder::set_position(dcs_scaled_t newPosition) {
	LOG_WARNING1("absolute encoder cannot be set: channel %ld\n", axisLabel);
	return XOS_SUCCESS;
}

xos_result_t Dmc2180RelativeEncoder::set_position(dcs_scaled_t newPosition) {
	/* local variables */
	int error_code;

	LOG_INFO1("scale_factor : %f\n",scale_factor);

	sprintf(command, "DE%c=%ld", axisLabel, SCALED2UNSCALED( (dcs_scaled_t)newPosition, scale_factor ) );
	/* construct and send message to dmc2180 */
	controller_execute(command, &error_code, FALSE );

	LOG_INFO1("error_code: %d\n",error_code);

	/* check for errors */
	if (error_code != 0) {
		LOG_WARNING1("error_code: %d\n",error_code);

		/* report failure */
		return XOS_FAILURE;
	}

	/* report success */
	return XOS_SUCCESS;
}

xos_result_t Dmc2180_motor::get_reference_position(dcs_unscaled_t * position) {
	int error_code;
	/* get position of axis */
	sprintf(command, "RP%c", axisLabel);

	controller_execute(command, &error_code, FALSE );

	if (error_code == 0) {
		*position = (dcs_unscaled_t) atoi(lastResponse);
		if (reverse)
			*position *= -1;
	} else {
		xos_error("dmc2180::get_current_position\n");
		return XOS_FAILURE;
	}
	return XOS_SUCCESS;
}

xos_result_t Dmc2180_motor::get_target_position(dcs_unscaled_t * position) {
	int error_code;
	dcs_unscaled_t tempPosition[8];
	/* get position of axis */

	sprintf(command, "PA ?,?,?,?,?,?,?,?");

	controller_execute(command, &error_code, FALSE );

	if (error_code == 0) {
		//LOG_INFO1("stop codes message: %s",response);
		sscanf(lastResponse, "%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld",
				&tempPosition[0], &tempPosition[1], &tempPosition[2],
				&tempPosition[3], &tempPosition[4], &tempPosition[5],
				&tempPosition[6], &tempPosition[7]);
		*position = tempPosition[axisIndex];
		if (reverse)
			*position *= -1;
	} else {
		xos_error("dmc2180::get_target_position\n");
		return XOS_FAILURE;
	}
	return XOS_SUCCESS;
}

xos_result_t Dmc2180_motor::start_move(dcs_unscaled_t new_destination,
		char * error_string) {
	/* local variables */
	int switchMask;
	int error_code;

	destination = new_destination;

	/*handle reverse flag at lowest level accessing H/W*/
	if (reverse)
		new_destination *= -1;

	//For DC motors servo the motor at current position
	if (isStepper == FALSE) {

		sprintf(command, "MG _MO%c", axisLabel);
		if (controller_execute(command, &error_code, FALSE) == XOS_SUCCESS) {
			int motorOff;
			sscanf(lastResponse, "%d", &motorOff);
			if (motorOff == 1) {
				//turn the motor on
				sprintf(command, "SH%c", axisLabel);
				/* construct and send message to dmc2180 */
				controller_execute(command, &error_code, FALSE);
			};
		} else {
			xos_error("get_switch_mask -- could not get response\n");
			return XOS_FAILURE;
		}

        //The oscillation code may have changed the slew speed and acceleration.
		//set_acceleration();
		//set_speed();
	}
	//set_speed(); //The oscillation code may have changed the slew speed.

	/* construct and send message to dmc2180 */
	sprintf(command, "PA%c=%ld", axisLabel, new_destination);

	controller_execute(command, &errorCode, FALSE );

	/* construct and send message to dmc2180 */
	sprintf(command, "BG%c", axisLabel);

	controller_execute(command, &errorCode, FALSE );

	LOG_INFO1("error_code: %d\n",errorCode);

	/* check for errors */
	if (errorCode == 22) {
		get_switch_mask(&switchMask, &error_code);
		switchMask &= 0x0c;
		switch (switchMask) {
		case 0:
			strcpy(error_string, "both_hw_limits");
			break;
		case 4:
			strcpy(error_string, "cw_hw_limit");
			break;
		case 7:
			strcpy(error_string, "no_limits");
			break;
		case 8:
			strcpy(error_string, "ccw_hw_limit");
			break;
		default:
			strcpy(error_string, "unknown");
			break;
		}
		/* report failure */
		return XOS_FAILURE;
	}

	/* report success */
	return XOS_SUCCESS;
}

xos_result_t Dmc2180_motor::start_home( char * deviceName,  char * error_string )
        {

        /* local variables */
        int switchMask;
        int error_code;

        //destination = new_destination;

        /*handle reverse flag at lowest level accessing H/W*/
        //if (reverse) new_destination *= -1;


        //For DC motors servo the motor at current positiona
        // LOG_INFO1("homee deviceName=%s\n", deviceName);
        if(strcmp(deviceName,"gonio_phi") == 0)
        {
                sprintf(command, "FI%c", axisLabel );

                /* construct and send message to dmc2180 */
                controller_execute( command, &error_code,FALSE );
        }
        else
        {
                sprintf( command, "HM%c", axisLabel );
                /* construct and send message to dmc2180 */
        //      LOG_INFO1("homee command=%s\n", command);
                controller_execute( command, &error_code,FALSE );
        }

        /* construct and send message to dmc2180 */
        sprintf( command, "BG%c",axisLabel );

        // LOG_INFO1("homee command=%s\n", command);
        controller_execute( command, &errorCode,FALSE );

        // LOG_INFO("homee after home command executed\n");
        LOG_INFO1("error_code: %d\n",errorCode);
        /* check for errors */
        if ( errorCode == 22 )
                {
                get_switch_mask( &switchMask, &error_code);
                switchMask &= 0x02;
                switch ( switchMask )
                        {
                        case 0:
                                strcpy( error_string, "in_home");
                                break;
                        /*
                       case 4:
                                strcpy( error_string, "cw_hw_limit");
                                break;
                        case 7:
                                strcpy( error_string, "no_limits");
                                break;
                        case 8:
                                strcpy( error_string, "ccw_hw_limit");
                                break;
                        */
                        default:
                                strcpy( error_string, "unknown");
                                break;
                        }
                /* report failure */
                return XOS_FAILURE;
                }

        /* report success */
        return XOS_SUCCESS;
        }


xos_result_t Dmc2180_motor::get_switch_mask(int * switchMask, int * error_code) {
	sprintf(command, "TS%c", axisLabel);
	//WARNING: check error
	if (controller_execute(command, error_code, FALSE ) == XOS_SUCCESS)
		*switchMask = atoi(lastResponse);
	else {
		xos_error("get_switch_mask -- could not get response\n");
		return XOS_FAILURE;
	}

	return XOS_SUCCESS;
}

xos_boolean_t Dmc2180_motor::isMoving() {
	int motion_complete;
	int error_code;
	int stopCode;

	dcs_unscaled_t unscaledReference;
	dcs_unscaled_t unscaledPosition;
	//dcs_unscaled_t unscaledTarget;

	if (isScriptParticipant == TRUE) {
		if (checkScriptDone() == FALSE)
			return TRUE;
		//abort_move_soft();
	}

	get_stop_code(&stopCode);
	// get the current position
	get_current_position(&unscaledPosition);
	get_reference_position(&unscaledReference);
	//get_target_position( & unscaledTarget );

	LOG_INFO3("axis:%c current: %ld,  reference: %ld\n", axisLabel, unscaledPosition, unscaledReference );

	//check to see if stop codes indicate the motor is done
	if (stopCode != 0 && stopCode != 100) {
		LOG_INFO1("STOP LEVEL1: motor stop code: %d\n", stopCode);

		// check motion complete variable
		sprintf(command, "MG _BG%c", axisLabel);
		//WARNING:: check error
		controller_execute(command, &error_code, FALSE );
		sscanf(lastResponse, "%d", &motion_complete);

		if (motion_complete == 0) {
			LOG_INFO("STOP LEVEL2: controller ready to receive new move command");
			//The galil dmc2180 has stated that the motor has stopped moving.
			//However, step pulses may still be leaving the controller at this point!
			//Usually, it is sufficient to verify that the reference and current position
			// are the same, however it is possible that the motor could be stopped
			// by a limit switch and the two values are not the same.
			// Therefore we need to simply check to see if the last "current position"
			// is the same as this "current position".  This may not work if the polling period
			// was extremely fast.  Unfortunately this means that there is still no known way
			// of verifying that the motor has REALLY stopped moving with a simple query.

			// get the current position
			//get_current_position( &unscaledPosition );

			// decide whether the motor is moving or if it has hit a limit
			if (stopCode != 1 && stopCode != 101) {
				handleStop();
				LOG_INFO("STOP LEVEL3a: motor was aborted\n");
				//motor hit a limit or aborted.
				if (unscaledPosition == lastUnscaledPosition) {
					LOG_INFO("STOP LEVEL4a:current position of motor is not changing.\n");
					lastUnscaledPosition = unscaledPosition + 999; // make sure it is different next time we move.
					return FALSE;
				}
				lastUnscaledPosition = unscaledPosition;
			} else {
				//
				LOG_INFO("STOP LEVEL3b: motor stopped normally\n");
				//motor stopped (stopping) normally
				//motor ready for move command but motor may still be moving
				//get_reference_position( &unscaledReference );

				//verify that ALL of the steps have gone out
                if ( abs(unscaledReference - unscaledPosition) < 5 ) {
                    LOG_INFO("isMoving: STOP LEVEL4b: (reference - position) < 5 \n");
					// the dmc2180's internal state machine has stabilized
					return FALSE;
				}
			}
		}
	}
	return TRUE;
}

xos_result_t Dmc2180_motor::handleStop() {
	int error_code;
	//For DC motors servo the motor at current position
	if (isStepper == FALSE && servoBetweenMoves == FALSE) {
		sprintf(command, "MO%c", axisLabel);
		/* construct and send message to dmc2180 */
		controller_execute(command, &error_code, FALSE );

	}

	return XOS_SUCCESS;
}

xos_result_t Dmc2180_motor::get_stop_reason(char * statusString) {
	int code;
	/* get stop code for all motors */
	get_stop_code(&code);

	switch (code) {
	case 1:
		strcpy(statusString, "normal");
		break;
	case 2:
		strcpy(statusString, "cw_hw_limit");
		break;
	case 3:
		strcpy(statusString, "ccw_hw_limit");
		break;
	case 4:
	case 7:
		strcpy(statusString, "aborted");
		break;
        case 10:
                strcpy(statusString, "normal");
                break;
	case 101:
		strcpy(statusString, "normal");
		break;
	default:
		strcpy(statusString, "unknown");
		break;
	}
	return XOS_SUCCESS;
}

xos_result_t Dmc2180::get_stop_codes(int *codes) {
	char command[200];
	char response[200];
	int error_code;

	/* get position of axis */
	sprintf(command, "SC");
	execute(command, response, &error_code, FALSE );

	//printf("stop codes message: %s",response);
	sscanf(response, "%d,%d,%d,%d,%d,%d,%d,%d", codes, codes + 1, codes + 2,
			codes + 3, codes + 4, codes + 5, codes + 6, codes + 7);

	return XOS_SUCCESS;
}

xos_result_t Dmc2180_motor::get_stop_code(int *code) {
	int error_code;
	char codeString[200];

	/* get position of axis */
	sprintf(command, "SC%c", axisLabel);
	controller_execute(command, &error_code, FALSE );

	if (error_code != 0) {
		LOG_WARNING("could not get code with SC command.");
		*code = 999;
		return XOS_FAILURE;
	}

	sscanf(lastResponse, "%s", codeString);
	*code = atoi(codeString);
	return XOS_SUCCESS;
}

xos_boolean_t Dmc2180_motor::checkScriptDone() {
	int error_code;
	char codeString[200];

	sprintf(command, "MG _HX%d", scriptThreadNumber );
	controller_execute(command, &error_code, FALSE );

	if (error_code != 0) {
		LOG_WARNING("could not get thread execution status.");
		return TRUE;
	}

	sscanf(lastResponse, "%s", codeString);

	if (strcmp("0.0000", codeString) == 0) {
        scriptThreadNumber = -1;
        isScriptParticipant = FALSE;

        set_acceleration();
		set_speed();
        
		return TRUE;
    }

	//if (strcmp("2.0000", codeString) == 0) {
    //    scriptThreadNumber = -1;
    //    isScriptParticipant = FALSE;
   // 	return TRUE;
    //}

	return FALSE;
}

xos_result_t Dmc2180_motor::abort_move_soft() {
	int error_code;

	handleStop();

	sprintf(command, "ST%c", axisLabel);
	controller_execute(command, &error_code, FALSE );
	LOG_INFO2("Aborted device %c with %s\n", axisLabel, command );

    if ( isScriptParticipant ) {
	    sprintf(command, "HX%d", scriptThreadNumber );
		controller_execute(command, &error_code, FALSE );
	    if (error_code != 0) LOG_SEVERE("Could not halt script");


	    sprintf(command, "XQ #HALT,5" );
		controller_execute(command, &error_code, FALSE );
	    if (error_code != 0) LOG_SEVERE("Could not halt script");
    }

	return XOS_SUCCESS;
}


xos_result_t Dmc2180_motor::abort_move_hard() {
	int error_code;

	handleStop();

	sprintf(command, "AB 1");

	/* construct and send message to dmc2180 */
	controller_execute(command, &error_code, FALSE );

	LOG_INFO2("Aborted device %c with %s\n",axisLabel, command );

	sprintf(command, "StopOsc=1");
	controller_execute(command, &error_code, FALSE );

	if (error_code != 0)
		return XOS_FAILURE;

	return XOS_SUCCESS;
}

xos_result_t Dmc2180_motor::assertMotorType(char * expectedMotorType) {
	int error_code;
	sprintf(command, "MT%c=?", axisLabel);

	controller_execute(command, &error_code, FALSE );

	if (error_code != 0) {
		LOG_SEVERE("Could not get motor type\n");
		return XOS_FAILURE;
	}

	if (fabs(atof(lastResponse) - atof(expectedMotorType)) > 0.1) {
		LOG_SEVERE3("Motor type on channel '%c' did not match expected type. Expected '%1.1f'. Current '%1.1f'.", axisLabel, atof( expectedMotorType), atof(lastResponse) );
		return XOS_FAILURE;
	}

	return XOS_SUCCESS;
}

xos_result_t Dmc2180_device::controller_execute(char * message,
		int *error_code, xos_boolean_t silent) {
	if (!silent)
		LOG_INFO( message );
	return (*dmc2180).execute(message, lastResponse, error_code, silent);
}

xos_result_t Dmc2180::kick_watchdog(int kickValue) {
	int error_code;
	char response[200];
	char command2[200];
	int returnkick;

	//First check that command to the controller and response
	//from the controller are synched up.
	sprintf(command2, "MG \"%x\"", kickValue);
	//SILENTLY KICK watchodog
	execute(command2, response, &error_code, TRUE);

	//printf("kick_watchdog -- check if telnet session synched up\n");
	sscanf(response, "%x", &returnkick);

	if (returnkick != kickValue) {
		//commands are not synched up!
		LOG_INFO3("Dmc2180::kick_watchdog sent %x and got %x on %s\n",
				kickValue,
				returnkick,
				hostname.c_str() );
		return XOS_FAILURE;
	}

	//Now kick the watchdog on the dmc2180.
	sprintf(command2, "Kick=$%x", kickValue);
	//silently kick watchdog
	return execute(command2, response, &error_code, TRUE);
}

xos_result_t Dmc2180::start_watchdog(int * error_code) {

	char response[200];
	execute("XQ #W_Dog,1", response, error_code, FALSE);
	LOG_INFO1("%s\n",response);
	if (*error_code != 0) {
		LOG_INFO1("dmc2180::start_watchdog XQ #W_Dog,1 returned error = %d\n", *error_code );
		return XOS_FAILURE;
	};

	return XOS_SUCCESS;
}

xos_result_t Dmc2180_shutter::set_state(shutter_state_t newState) {
	int error_code;

	/* construct command depending on desired output state */
	if (newState == SHUTTER_CLOSED) {
		if (polarity == LOW_VOLTAGE_IS_CLOSED)
			sprintf(command, "CB %d", channel); //clear bit
		else
			sprintf(command, "SB %d", channel); //set bit
	} else {
		//newState == SHUTTER_OPEN
		if (polarity == LOW_VOLTAGE_IS_OPEN)
			sprintf(command, "CB %d", channel); //clear bit
		else
			sprintf(command, "SB %d", channel); //set bit
	}

	controller_execute(command, &error_code, FALSE );

	if (error_code != 0) {
		xos_error("Dmc2180_shutter:: error setting shutter_state\n");
		return XOS_FAILURE;
	}
	return XOS_SUCCESS;

}
;

xos_result_t Dmc2180::getDigitalInput(int * value) {
	char command[200];
	char response[200];
	int error_code;

	/* get position of axis */
	sprintf(command, "TI");
	execute(command, response, &error_code, TRUE );

	if (error_code != 0) {
		xos_error("Dmc2180_shutter:: error reading digital Input\n");
		return XOS_FAILURE;
	}

	//LOG_INFO1("stop codes message: %s",response);
	sscanf(response, "%d", value);

	return XOS_SUCCESS;
}

string Dmc2180::updateString(string dcsStringName) {
	char command[200];
	char response[200];
	int error_code;
	
	string newStringValue = "";
	
	int blockValue[DMC2180_MAX_DIGITAL_INPUT_BLOCK];
	sprintf(command, "MG _TI0,_TI1");
	execute(command, response, &error_code, FALSE);
	sscanf(response, "%d %d", &blockValue[0], &blockValue[1] );
	
	for (int block = 0; block < DMC2180_MAX_DIGITAL_INPUT_BLOCK; block ++ ) {
		for (int ch = 0; ch <8 ; ch ++ ) {
			int channel = block * 8 + ch;
			const Dmc2180_digitalInput & input = digitalInput[channel];
			if ( ! input.channel_used ) continue;

			int bit = ( blockValue[block] >> ch) & 1;
			
			if ( input.stringMembership == dcsStringName ) {
				newStringValue.append(" " + input.inputName);
				if ( bit == 0 ) {
					newStringValue.append(" " + input.lowVoltageStr);
				} else {
					newStringValue.append(" " + input.highVoltageStr);
				}
			}
		}
	}
	
	/*
	int base_input_channel = 8 * input_block;
	std::set<string> changedStrings;
	for (int ch = 0; ch < 8; ch++) {
		int channel = base_input_channel + ch;
		Dmc2180_digitalInput & lastInput = dmc2180.digitalInput[channel];
		//if ( ! input.channel_used ) continue;

		int latestBit = (latestDigitalInput >> ch) & 1;

		if (lastInput.state != latestBit) {
			lastInput.state = latestBit;
			changedStrings.insert(lastInput.stringMembership);
			//updateDigitalInputString ( lastInput.stringMembership , dmc2180 );
		}
	}

	set<string>::iterator p = changedStrings.begin();
	while (p != changedStrings.end() ) {
		updateDigitalInputString( *p, dmc2180);
	}
*/
	return newStringValue;
}

