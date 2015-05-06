
#include "log_quick.h"
#include "RobotService.h"
#include "DcsMessageManager.h"
#include "robot.h"
#include "RobotControls.h"
#include "XosStringUtil.h"
#include "robot_call.h"
#include <math.h>
#include <string>
#include <vector>

#include "RobotCall.h"


RobotService::OperationToMethod RobotService::m_OperationMap[] =
{//  name,								immediately, method to call
	{"clear_mounted_state",					FALSE, &RobotService::ClearMountedState},
	{"mount_crystal",					FALSE, &RobotService::MountCrystal},
        {"dismount_crystal",                                    FALSE, &RobotService::DismountCrystal},
	{"center_grabber",					FALSE, &RobotService::CenterGrabber},
	{"dry_grabber",						FALSE, &RobotService::DryGrabber},
        {"cool_grabber",                                        FALSE, &RobotService::CoolGrabber},
	{"ReadOrtecCounters",                                   FALSE, &RobotService::ReadOrtecCounters},
	{"move_to_new_energy",                   		FALSE, &RobotService::MoveToNewEnergy},
	{"get_current_energy",           			FALSE, &RobotService::GetCurrentEnergy},
	{"mono_status",						FALSE, &RobotService::MonoStatus},
};

RobotService::MotorNameStruct RobotService::m_MotorMap[] = {
        {"MFirst",                      MOTOR_FIRST},
//        {"MSecond",                     MOTOR_SECOND},
};

RobotService::RobotService( ):
	m_MsgManager( DcsMessageManager::GetObject( )),
	m_MsgQueue( 1 ),
	m_pRobot(NULL),
	m_pCurrentOperation(NULL),
	m_pInstantOperation(NULL)
{
    xos_semaphore_create( &m_SemThreadWait, 0 );
    xos_semaphore_create( &m_SemStopOnly, 0 );
    m_pRobot = new RobotControls;

    m_pRobot->SetSleepSemaphore( &m_SemStopOnly );
}

RobotService::~RobotService( )
{
	stop( );
	delete m_pRobot;

    xos_semaphore_close( &m_SemStopOnly );
    xos_semaphore_close( &m_SemThreadWait );
}

void RobotService::start( )
{
    if (m_Status != STOPPED)
	{
		LOG_WARNING( "called start when it is still not in stopped state" );
		return;
	}

    //set status to starting, this may cause broadcase if any one is interested in status change
	SetStatus( STARTTING );

    //reset all flags
    m_CmdStop = FALSE;
    m_CmdReset = FALSE;
    m_FlagEmergency = FALSE;

    xos_thread_create( &m_Thread, Run, this );
}

void RobotService::stop( )
{
    m_CmdStop = TRUE;

    if (m_Status == READY)
    {
        SetStatus( STOPPING );
    }

    //signal threads
    xos_semaphore_post( &m_SemThreadWait );
}


//this function not used yet
void RobotService::reset( )
{
    DcsMessageManager& theManager = DcsMessageManager::GetObject( );

    DcsMessage* pMsg = NULL;

    if ((pMsg = m_MsgQueue.Dequeue( )) != NULL)
    {
		theManager.DeleteDcsMessage( pMsg );
    }
}

//this is called by other thread:
//we will check the content of the message, if it can be immediately dealt with,
//we send reply directly, otherwise, it will be put in a queue and wait our own
//thread to deal with it.
#define ARRAYLENGTH( a ) (sizeof(a)/sizeof(a[0]))
BOOL RobotService::ConsumeDcsMessage( DcsMessage* pMsg )
{
	LOG_FINEST( "+RobotService::ConsumeDcsMessage" );

	//safety check
	if (pMsg == NULL)
	{
		LOG_WARNING( "RobotService::ConsumeDcsMessage called with NULL msg" );
		LOG_FINEST( "-RobotService::ConsumeDcsMessage" );
		return TRUE;
	}

	switch ( pMsg->ClassifyMessageType() )
   	{
      		case DCS_OPERATION_START_MSG:
         		return HandleKnownOperations(pMsg);
                                        
      		case DCS_ABORT_MSG:  
         		LOG_FINEST("RobotService::ConsumeDcsMessage: abort unfinished operations");

			// abort( );
         		m_MsgManager.DeleteDcsMessage( pMsg );
         		return TRUE;

                case DCS_REGISTER_PSEUDO_MOTOR_MSG:
                        return registerMotor( pMsg );
                                                                                                                       
                case DCS_MOVE_MOTOR_MSG:
                case DCS_CONFIGURE_PSEUDO_MOTOR_MSG:
                        return HandleKnownMotors(pMsg);
                                                                                                                       
                case DCS_REGISTER_STRING_MSG:
//                      return registerString( pMsg );
                                                                                                                       
                case DCS_STRING_MSG:
//                      return HandleKnownStrings(pMsg);

/*                                                                      
     		 case DCS_ION_CHAMBER_READ_MSG:
         		HandleIonChamberRequest(pMsg);
         		m_MsgManager.DeleteDcsMessage( pMsg );
         		return TRUE;

     		 case DCS_ION_CHAMBER_REGISTER_MSG:
         		LOG_FINEST("-RobotDhsService::ConsumeDcsMessage: consume ion chamber message.XXXXXX");
         		m_MsgManager.DeleteDcsMessage( pMsg );
         		//consume this message without doing anything
         		return TRUE;
*/                                                                      
		  case DCS_UNKNOWN_MSG:
         		LOG_FINEST( "RobotDhs::ConsumeDcsMessage: not recognized, pass on" );
         		return FALSE;
                                                                      
      		  default:
        		break;
   	}
   	LOG_FINEST( "RobotDhs::ConsumeDcsMessage: not a message for that can be handled, pass on" );
   	return FALSE;
}

/////////////////////////////////////////////////////////////////////////////
BOOL RobotService::HandleKnownOperations( DcsMessage* pMsg )
{
   m_pInstantMessage = pMsg;
   //check to see if this is an operation we can finish immediately
   LOG_INFO1("OPNAME: %s\n", m_pInstantMessage->GetOperationName());
   LOG_INFO1("operation massage: %s\n", m_pInstantMessage->GetText() );

   for (unsigned int i = 0; i < ARRAYLENGTH(m_OperationMap); ++i)
   {
   	LOG_INFO1("OPNAME1: %s\n", m_OperationMap[i].m_OperationName);
	
      if (!strcmp( m_pInstantMessage->GetOperationName( ), m_OperationMap[i].m_OperationName ))
      {
         LOG_FINEST1( "match operation%d", i );
         m_pInstantMessage->m_PrivateData = i;
         if (m_OperationMap[i].m_Immediately)
         {
            LOG_FINEST( "immediately" );
            (this->*m_OperationMap[i].m_pMethod)( );
         }
         else
         {
            //check to see if it is repeated operation
/*            if (m_pCurrentOperation &&
                  !strcmp( m_pCurrentOperation->GetOperationHandle( ), m_pInstantMessage->GetOperationHandle( ) ) &&
                  !strcmp( m_pCurrentOperation->GetOperationName( ),  m_pInstantMessage->GetOperationName( ) ))
            {
               LOG_INFO( "ignore the same operation message" );
               //ignore it
            }
          else
            {
*/               //put it in the queue, our own thread will take care of it
               if (m_MsgQueue.Enqueue( m_pInstantMessage ))
               {
                  LOG_FINEST1( "added to dcs msg queue, current length=%d\n", m_MsgQueue.GetCount( ) );
                  //wake up the worker thread
                  xos_semaphore_post ( &m_SemThreadWait );
                                                                      
                  //do not delete this message yet, we put it into a queue
                  m_pInstantMessage = NULL;
               }
               else
               {
                  //send reply: busy
                  //11 = strlen("busy doing") + 1
                                                                      
                  char status_buffer[MAX_OPERATION_HANDLE_LENGTH + 11] = "busy";
                  if (m_pCurrentMessage)
                  {
                     strcat( status_buffer, "doing " );
                     strcat( status_buffer, m_pCurrentMessage->GetOperationName( ) );
                     strcat( status_buffer, " " );
                     strcat( status_buffer, m_pCurrentMessage->GetOperationHandle( ) );
                  }
                                                                      
                  LOG_FINEST( "reply busy" );
                  DcsMessage* pReply = m_MsgManager.NewOperationCompletedMessage( m_pInstantMessage, status_buffer );
                  SendoutDcsMessage( pReply );
               }//need to send busy
                                                                      
//            }//if can ignore
                                                                      
         }//if immediate
                                                                      
         if (m_pInstantMessage)
            m_MsgManager.DeleteDcsMessage( m_pInstantMessage );
         LOG_FINEST( "-RobotService::ConsumeDcsMessage: we consume it" );
         return TRUE;
      }//if match one of supported operations
   }//for
                                                                      
   //not interested in this operation message
   return FALSE;
}

////////////////////////////////////////////////////////////////////////////
// The old comments from SSRL for the adqboard DHS
/************************************************************************\
* HandleKnownMotors takes the the message and finds out what type of
* motorMove it is. currently their is only one motor the light motor                                                         *
\************************************************************************/
BOOL RobotService::HandleKnownMotors( DcsMessage *pMsg )
{

        m_pInstantMessage = pMsg;
        for (int i = 0; i < NUM_MOTOR; ++i)
        {
                if (!strcmp( m_motorName[i], pMsg->GetMotorName( ) ))
                {
                        LOG_FINEST1("match motor%d", i);
                        m_pInstantMessage->m_PrivateData = i;

			// Configure Psudo Motor
                        if(m_MsgQueue.Enqueue(m_pInstantMessage)){
                                xos_semaphore_post( &m_SemThreadWait );
                                m_pInstantMessage = NULL;
                        }
                        else
                        {//should not get here unless the queues are set to have a limit m_MsgQueue(0) means no limit
                                char status_buffer[128] = "busy";
                                if (m_pCurrentMessage){
                                         strcat(status_buffer, "doing ");
                                        strcat(status_buffer, m_pCurrentMessage->GetOperationName());
                                        strcat(status_buffer, " ");
                                        strcat(status_buffer, m_pCurrentMessage->GetOperationHandle());
                                }
                                LOG_FINEST1("%s",status_buffer);
                                DcsMessage* pReply = m_MsgManager.NewMotorDoneMessage( pMsg->GetMotorName( ), 0.0, status_buffer );
                                SendoutDcsMessage(pReply);
                        }
                        if (m_pInstantMessage)
                                m_MsgManager.DeleteDcsMessage(m_pInstantMessage);
                        LOG_FINEST("RobotService::ConsumeDcsMessage: we consume it");
                        return TRUE;
                }//if !strcmp
        }//for int i
        return false;
}

////////////////////////////////////////////////////////////////////////////
BOOL RobotService::registerMotor(DcsMessage* pMsg)
{
        for (unsigned int i = 0; i < sizeof(m_MotorMap)/sizeof(m_MotorMap[0]); ++i){
                size_t name_length = strlen(m_MotorMap[i].m_localName);
                if (!strncmp( pMsg->GetLocalName( ), m_MotorMap[i].m_localName, name_length ))
                {
                	LOG_INFO2( "register motor %s for %s", pMsg->GetMotorName( ), pMsg->GetLocalName( ) );
                        strcpy( m_motorName[m_MotorMap[i].m_index], pMsg->GetMotorName( ) );
                        m_MsgManager.DeleteDcsMessage( pMsg );
                        return TRUE;
                }
        }
        return FALSE;
}

////////////////////////////////////////////////////////////////////////////
// Got stoh_read_ion_chambers
bool RobotService::HandleIonChamberRequest( DcsMessage* pMsg )
{
/*   std::string tmp;
   std::string time_secs;
   BOOL is_repeated = FALSE;
   BOOL is_channel_wanted[ADAC_NUM_CHANNELS];
                                                                                                                         
   for (int ii = 0; ii < ADAC_NUM_CHANNELS; ++ii) {
      is_channel_wanted[ii] = FALSE;
   }
                                                                                                                         
   ParseIonChamberRequest(pMsg->GetText(),
         tmp, time_secs, is_repeated, is_channel_wanted);
                                                                                                                         
   // Issue an asynchronous command.
   // When the result is ready, this dhs must send
   // a response htos_report_ion_chambers time_secs repeat counts
   adac_read_ion_chambers(time_secs.c_str(), is_repeated,
         is_channel_wanted);
                                                                                                                         
*/   return TRUE;
}

////////////////////////////////////////////////////////////////////////////
/* bool RobotService::HandleKnownStrings(DcsMessage* pMsg)
{
      m_pInstantMessage = pMsg;
        for (int i = 0; i < NUM_STRING; ++i)
        {
                if (!strcmp( m_stringName[i], pMsg->GetStringName( ) ))
                {
                        LOG_FINEST1("match string%d", i);
                        m_pInstantMessage->m_PrivateData = i;
                        if (m_MsgQueue.Enqueue(m_pInstantMessage)){
                                xos_semaphore_post( &m_SemThreadWait );
                                m_pInstantMessage = NULL;
                        }
                        else
                        {//should not get here unless the queues are set to have a limit m_MsgQueue(0) means no limit
                                char status_buffer[128] = "busy";
                                if (m_pCurrentMessage){
                                        strcat(status_buffer, "doing ");
                                        strcat(status_buffer, m_pCurrentMessage->GetOperationName());
                                        strcat(status_buffer, " ");
                                        strcat(status_buffer, m_pCurrentMessage->GetOperationHandle());
                                }
                                LOG_FINEST1("%s",status_buffer);
                                DcsMessage* pReply = m_MsgManager.NewMotorDoneMessage( pMsg->GetMotorName( ), 0.0, status_buffer );
                                SendoutDcsMessage(pReply);
                        }
                        if (m_pInstantMessage)
                                m_MsgManager.DeleteDcsMessage(m_pInstantMessage);
                        LOG_FINEST("RobotService::ConsumeDcsMessage: we consume it");
                        return TRUE;
                }//if !strcmp
        }//for int i
        return false;
}
*/
////////////////////////////////////////////////////////////////////////////
void RobotService::SendoutDcsMessage( DcsMessage* pMsg )
{
	LOG_FINEST1( "RobotService::SendoutDcsMessage( %s )", pMsg->GetText( ) );

	if (!ProcessEvent( pMsg ))
	{
		LOG_INFO1( "RobotService: no one listening to this message, delete it: %s", pMsg->GetText( ) );
		m_MsgManager.DeleteDcsMessage( pMsg );
	}
}

////////////////////////////////////////////////////////////////////////////
void RobotService::ThreadMethod( )
{
	//init the console
	if (m_pRobot == NULL || !m_pRobot->Initialize( ))
	{
		LOG_SEVERE( "console initialization failed. thread quit" );
        	SetStatus( STOPPED );
		return;
	}

    	SetStatus( READY );

	LOG_INFO( "Robot Thread ready" );

	while (TRUE)
	{
		//wait operation message comes up or stop command issued.
       		xos_semaphore_wait( &m_SemThreadWait, 0 );
		LOG_FINEST( "Robot thread out of waiting" );
		//check to see if it is stop
		if (m_CmdStop)
		{
			if (m_FlagEmergency)
			{
				//immediately return
				LOG_INFO( "Robot thread emergency exit" );
				return;
			}
			else
			{
				//break the loop and clean up
				LOG_INFO( "Robot thread quit by STOP" );
				break;
			}
		}//if stopped

		if (m_MsgQueue.IsEmpty( ))
		{
			continue;
		}

                m_pCurrentMessage = m_MsgQueue.GetHead();
                if (m_pCurrentMessage == NULL){
                        m_MsgQueue.Dequeue();
                        LOG_INFO("Message got Dequeued in boardService::ThreadMethod\n");
                        continue;
                }
                switch (m_pCurrentMessage->ClassifyMessageType( ))
                {
			case DCS_ABORT_MSG:
//?                     	m_inAborting = false;
                        	break;

                	case DCS_OPERATION_START_MSG:
                        
				if (m_pCurrentMessage->m_PrivateData >= 0 && m_pCurrentMessage->m_PrivateData < sizeof(m_OperationMap)/sizeof(m_OperationMap[0])){
                                	LOG_INFO("IN RobotService::ThreadMethod starting method\n");
                                	(this->*m_OperationMap[m_pCurrentMessage->m_PrivateData].m_pMethod)();
                        	}
                        	else {
                                	LOG_WARNING("RobotDhsService::ThreadMethod: should never be here, the match was done before it was put into queue\n");
                        	}
                        	break;
                
                	case DCS_MOVE_MOTOR_MSG:
                                if (m_pCurrentMessage->m_PrivateData >= 0 && m_pCurrentMessage->m_PrivateData < NUM_MOTOR)
                                {
					int channel = m_pCurrentMessage->m_PrivateData;
                                        double NewEnergy = m_pCurrentMessage->GetMotorPosition( );
					

					CurrentPosition[channel] = NewEnergy;

                                        LOG_FINEST1( "x4a energy GetMotorPosition(): %lf", NewEnergy );
                                        if (channel >= 0 && channel < NUM_MOTOR)
                                        {
                                                if (m_motorName[channel][0] != 0)
                                                {
							// open the shuuter before move the energy;

							// Start to move motor here.
							if(!MoveToTargetEnergy(NewEnergy))
							{
			                                        LOG_WARNING( "Energy Change failed" );
								SendoutDcsMessage(m_MsgManager.NewMotorDoneMessage( m_motorName[channel], NewEnergy, "error" ) );
								break;
							}
						
							LOG_FINEST1("x4a energy moved to %lf ", NewEnergy);	
							
							// Updating the position while Wait for the mono to be stable
							// wait for 100 ms
							xos_thread_sleep(100);
							
							//Wait for 500 ms before read the current energy
//							xos_thread_sleep( 500 );

							// Close the shutter after energy move finished

							if(GetEnergy(&NewEnergy, CurrentPosition[channel]))
							{					
                                                        	SendoutDcsMessage(m_MsgManager.NewMotorDoneMessage( m_motorName[channel], NewEnergy, "normal" ) );
                LOG_FINEST("Get current energy is done");			
							}
							else
							{
                                                                SendoutDcsMessage(m_MsgManager.NewMotorDoneMessage( m_motorName[channel], NewEnergy, "error" ) );
                LOG_FINEST("Get current energy is failed");
							}
               LOG_FINEST1("x4a currentEnergy = %lf ",NewEnergy);
							break;
                                                }
                                        }
                                                                                                                              
                                }
                                break;

                	case DCS_CONFIGURE_PSEUDO_MOTOR_MSG:

                        	if (m_pCurrentMessage->m_PrivateData >= 0 && m_pCurrentMessage->m_PrivateData < NUM_MOTOR)
                        	{
					//Adding the energy moving and reading function here
				        
					int channel = m_pCurrentMessage->m_PrivateData;
//        				CurrentPosition = m_pCurrentMessage->GetMotorPosition( );
//                                      LOG_WARNING1( "GetMotorPosition(): %lf", CurrentPosition );
				        if (channel >= 0 && channel < NUM_MOTOR)
        				{
                				if (m_motorName[channel][0] != 0)
						{
                        				CurrentPosition[channel] = m_pCurrentMessage->GetMotorPosition( );
							SendoutDcsMessage(m_MsgManager.NewMotorDoneMessage( m_motorName[channel], CurrentPosition[channel], "normal" ) );
                				}
        				}
                        	}
                        	break;

                	default:
                        	LOG_WARNING1( "strange unsupported message in queue: %s", m_pCurrentMessage->GetText( ) );
                        	break;
		}

		//remove this message from the queue and delete it
		m_pCurrentOperation = NULL;	//no delete
		m_MsgManager.DeleteDcsMessage( m_MsgQueue.Dequeue( ) );
	}//while

	//clean up before exit
    	m_pRobot->Cleanup( );	//??????????????

    	LOG_INFO("Robot thread stopped and EvtStopped set");
    	SetStatus( STOPPED );
}

BOOL RobotService::ConnectToRobot( PTR_ROBOT_FUNC pMethod )
{
	BOOL res;
	char status_buffer[100];
        res= (m_pRobot->*pMethod)( m_pCurrentMessage->GetOperationArgument( ), status_buffer );
	return res;
}

//////////////////////////////////////////////////////////////////////////////////
// Right now this function is only good for not immediate execution (using m_pCurrentMessage)
// The immediate execution (using m_pIstantMessage) will have to add on later. 
void RobotService::WrapRobotMethod( PTR_ROBOT_FUNC pMethod )
{
	char status_buffer[Robot::MAX_LENGTH_STATUS_BUFFER + 1] = {0};
	//run the function and get result
// LOG_FINEST("WrapRobotMethod 1");
// LOG_FINEST1("m_pCurrentMessage->GetOperationArgument( ):%s", m_pInstantMessage->GetOperationArgument( ) );
// LOG_FINEST("WrapRobotMethod 2");

	//yangx "m_pRobot->*pMethod" return 0 for updating, return 1 for completion
	while (!(m_pRobot->*pMethod)( m_pCurrentMessage->GetOperationArgument( ), status_buffer ))
	{
        	status_buffer[Robot::MAX_LENGTH_STATUS_BUFFER] = '\0';
		//update
		DcsMessage* pReply = m_MsgManager.NewOperationUpdateMessage( m_pCurrentMessage, status_buffer );
		SendoutDcsMessage( pReply );

		//check if stop command in effect
		if (m_CmdStop)
		{
			LOG_INFO( "RobotService::WrapRobotMethod: got stop during looping" );
			m_pCurrentMessage = NULL;
			m_MsgManager.DeleteDcsMessage( m_MsgQueue.Dequeue( ) );
			return;
		}
	}

	//The order is important here: the creation of reply message needs current operation message,
	//you cannot delete it yet.
	//You must set the current operation to NULL and remove it from Queue before you send out reply

	//final reply
	DcsMessage* pReply = m_MsgManager.NewOperationCompletedMessage( m_pCurrentMessage, status_buffer );

	//before sending out, do clear first to prepare for next message
	//remove this message from the queue and delete it
	m_pCurrentMessage = NULL;
	m_MsgManager.DeleteDcsMessage( m_MsgQueue.Dequeue( ) );

	//send the reply out at the last step
	SendoutDcsMessage( pReply );
}

////////////////////////////////////////////////////////////////////////////////////////////
BOOL RobotService::MoveToTargetEnergy(double NewEnergy)
{


        // Get the current wavelength from xPSCAN
        if( (send_energy_request_to_control(&NewEnergy)) !=0 )
        {
              LOG_WARNING("RobotService Error: Move Energy failed ");
	      return FALSE;              
        }
	return TRUE;
}

///////////////////////////////////////////////////////////////////////////////////////////
BOOL RobotService::MonoStable()
{

	char m_buf[123];

	// time out in 1000 ms.
        if(cons_rpc_gets(1, "POST_REQUEST DCM4 MONO_STATE 1000", m_buf))
        {
        	LOG_WARNING("The Mono is not stable, try again");
                return FALSE;
        }

        if( (strcmp(m_buf, "STABLE")) == 0)
	{
		LOG_FINEST("Energy is stable");
        	return TRUE; 
	}
	else
	{
		// LOG_FINEST("Energy is not stable. Wait......");
		return FALSE;	
	}
}

///////////////////////////////////////////////////////////////////////////////////////////
BOOL RobotService::DcmOnLine()
{
                                                                                                                                           
        char m_buf1[123];
                                                                                                                                           
       
        if(cons_rpc_gets(1, "GET_CURRENT_SCRIPT", m_buf1))
        {
                LOG_WARNING("Could not get any value from Robot, try again");
                return FALSE;
        }
                                                                                                                                           
        if( (strcmp(m_buf1, "DCM5.CXE")) == 0)
        {
                LOG_FINEST("DCM is online");
                return TRUE;
        }
        else
        {
                // LOG_FINEST("DCM is not online.");
                return FALSE;
        }
}

///////////////////////////////////////////////////////////////////////////////////////////
BOOL RobotService::GetEnergy(double* energy, double c_energy)
{

        // Get the current wavelength from xPSCAN
        if( (get_current_energy_from_control(energy)) !=0 )
        {
              LOG_WARNING("RobotService Error: Get Current Energy failed ");
	      return FALSE;              
        }

        return TRUE;
}

///////////////////////////////////////////////////////////////////////////////////////////
BOOL RobotService::ConnectX4a()
{
	
	return(m_pRobot->ConnectRobotServer());
/*
	int fd;

	// hard coded IP address and port. need to be changed. should set them in config
        if(-1 == (fd = connect_to_host_api(&fd, "10.0.0.4", 8059, NULL)))
        {

                LOG_WARNING("Error connecting to x4a server");
                return FALSE;
        }

        LOG_FINEST("x4a server is being connected sucessfully");
	close(fd);    //Should I leave it open and use the fd for other functions?

	// Get the current Energy from Robot at startup process
//	int channel = m_pCurrentMessage->m_PrivateData;
//      double NewEnergy = m_pCurrentMessage->GetMotorPosition( );
	double NewEnergy;
	
	if(GetEnergy(&NewEnergy, 12658.0)) // the second parameter in this function is only for debuggin. Just give a any number.
        {
        	SendoutDcsMessage(m_MsgManager.NewMotorDoneMessage( "energy", NewEnergy, "normal" ) );
                LOG_FINEST1("Get current energy is done. The current Energy is %lf", NewEnergy);
        }
        else
        {
        	SendoutDcsMessage(m_MsgManager.NewMotorDoneMessage( "energy", NewEnergy, "error" ) );
                LOG_WARNING("RobotService: Get current energy is failed");
        }
*/        
//	return TRUE;
}

///////////////////////////////////////////////////////////////////////////////////////////
void RobotService::ClearMountedState()
{
	WrapRobotMethod( &Robot::ClearMountedState );
}
/*
void RobotService::ConnectRobotServer()
{
        WrapRobotMethod( &Robot::ConnectRobotServer );
}
*/
void RobotService::MountCrystal()
{
        WrapRobotMethod( &Robot::MountCrystal );
}

void RobotService::DismountCrystal()
{
	 WrapRobotMethod( &Robot::DismountCrystal );
}

void RobotService::CenterGrabber()
{
        WrapRobotMethod( &Robot::CenterGrabber );
}

void RobotService::DryGrabber()
{
        WrapRobotMethod( &Robot::DryGrabber );
}

void RobotService::CoolGrabber()
{
        WrapRobotMethod( &Robot::CoolGrabber);
}

void RobotService::ReadOrtecCounters()
{
        WrapRobotMethod( &Robot::ReadOrtecCounters);
}


void RobotService::GetCurrentEnergy()
{
        WrapRobotMethod( &Robot::GetCurrentEnergy );
}

void RobotService::MoveToNewEnergy()
{
        WrapRobotMethod( &Robot::MoveToNewEnergy );
}

void RobotService::MonoStatus( )
{
	WrapRobotMethod( &Robot::MonoStatus );
}
