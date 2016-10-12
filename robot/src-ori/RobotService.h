#ifndef __ROBOT_SERVICE_H__
#define __ROBOT_SERVICE_H__

#include "activeObject.h"
#include "DcsMessageTwoWay.h"
#include "MQueue.h"
#include "robot.h"
#include "XosMutex.h"
#include <string>
#include <list>


typedef BOOL (Robot::*PTR_ROBOT_FUNC)( const char argument[], char status_buffer[] );

class DcsMessageManager;
class RobotService :
	public DcsMessageTwoWay
{
public:
	RobotService(void);
	virtual ~RobotService(void);

	//implement activeObject
	virtual void start( );
	virtual void stop( );
	virtual void reset( );

	//implement interface DcsMessageTwoWay
	virtual BOOL ConsumeDcsMessage( DcsMessage* pMsg );

private:
	static XOS_THREAD_ROUTINE Run( void* pParam )
	{
		RobotService* pObj = (RobotService*)pParam;
		pObj->ThreadMethod( );
        XOS_THREAD_ROUTINE_RETURN;
	}

	void ThreadMethod( );

	void SendoutDcsMessage( DcsMessage* pMsg );

	BOOL HandleKnownOperations( DcsMessage* pMsg );
        BOOL HandleKnownMotors(DcsMessage* pMsg);
        BOOL HandleKnownStrings(DcsMessage* pMsg);
        BOOL registerMotor(DcsMessage* pMsg);


	////////////////////////////method for each operation//////////////////////

	void ClearMountedState();
	//BOOL ConnectToServer();
	void MountCrystal();
	void DismountCrystal();
	void CenterGrabber();
	void DryGrabber();
	void MoveToNewEnergy();
	void GetCurrentEnergy();
	void CoolGrabber();
	void GetRobotState();
	void MonoStatus( );
	
	void WrapRobotMethod( PTR_ROBOT_FUNC pMethod );
	BOOL ConnectToRobot(PTR_ROBOT_FUNC pMethod);

	// Functions directly being used in this class 
	BOOL MoveToTargetEnergy(double);
	BOOL MonoStable();
	BOOL DcmOnLine();
	BOOL GetEnergy(double *, double);
public:
	BOOL ConnectDensoRobot();
	BOOL disConnectDensoRobot();

	//////////////DATA
private:
	//save reference to manager
	DcsMessageManager& m_MsgManager;
	//message queue: messages waiting to execute: this is time consuming message
	MQueue m_MsgQueue;

	//thread
	xos_thread_t m_Thread;
	xos_semaphore_t m_SemThreadWait;    //this is wait for message and stop
    	xos_semaphore_t m_SemStopOnly;      //this is for stop only, used as timer
	xos_event_t m_EvtStopOnly;      //this is for stop only, used as timer

	//Robot
	Robot* m_pRobot;

	//special data
	//This is also used as a flag, to check we are already running an operation
	DcsMessage* volatile m_pCurrentOperation;

	DcsMessage* volatile 	m_pInstantOperation;
        DcsMessage* volatile    m_pInstantMessage;      //operation that is taking place if it is an immediate operation
        DcsMessage* volatile    m_pCurrentMessage;      //operation that is currently taking place
	
	volatile bool m_SendingDetailedMessage;
	//watch dog
        volatile time_t m_timeStampRobotPolling;

	static struct OperationToMethod
	{
		const char*          m_OperationName;
		bool	             m_Immediately;
		void (RobotService::*m_pMethod)();
		unsigned int         m_TimeoutForNextOperation; //if not 0, it will go home (standby) if next operation does not
	} m_OperationMap[];

	//strnigs owned by robot
    	static const char* ms_StringStatus;             //set only by robot, read by all
    	static const char* ms_StringState;              //set only by robot, read by all
    	static const char* ms_StringCassetteStatus;     //set only by robot, read by all
    	static const char* ms_StringSampleStatus;       //set only by robot, read by all
    	static const char* ms_StringInputBits;                      //set only by robot, read by all
    	static const char* ms_StringOutputBits;                     //set only by robot, read by all

    	static const char* ms_StringAttribute;          //set by blu-ice, read by robot

    	//"normal" status for sending set_string_completed
    	static const char* ms_Normal;


        //strings in this array will get special treatment to keep DCSS in SYNC with robot.
        //If the m_Write is set:
        //              the latest message will be save in case DCSS is disconnected
        //              and will be sent out when DCSS is reconnected
        //
        //If the m_Read is set:
        //              robot will retrieve the contents from DCSS when it is connected to DCSS

        static struct StringList
        {
                const char*                             m_StringName;
                size_t                                  m_NameLength;
                bool                                    m_Write;
                bool                                    m_Read;
                DcsMessage* volatile    m_pMsgLatest;
        } m_StringMap[];


        enum MotorIndex {
                MOTOR_FIRST,
                NUM_MOTOR,                      //must at end
        };

        struct MotorNameStruct {
                const char*         m_localName;
                MotorIndex              m_index;
        };

        static MotorNameStruct m_MotorMap[];
                                                                                                                     
        char m_motorName[NUM_MOTOR][40];
	double CurrentPosition[NUM_MOTOR];
                                                                                                                     
        //used to clean up all messages in the queue when abort received:
        //This flag will be set when abort message is received.
        //and it will be cleared after all messages in the queue are popped out
        volatile bool m_inAborting;


	bool HandleIonChamberRequest( DcsMessage* pMsg );
                                                                                                                         
/*      bool ParseIonChamberRequest(const char* str,
                        std::string& command,
                        std::string& time_secs,
                        BOOL& is_repeated,
                        BOOL is_channel_wanted[]);
*/
};

#endif //#ifndef __ROBOT_SERVICE_H__
