#if !defined(AFX_SPELCOM3_H__D18EA672_D8C8_4F4C_80CF_6A334B267794__INCLUDED_)
#define AFX_SPELCOM3_H__D18EA672_D8C8_4F4C_80CF_6A334B267794__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000
// Machine generated IDispatch wrapper class(es) created by Microsoft Visual C++

// NOTE: Do not modify the contents of this file.  If this class is regenerated by
//  Microsoft Visual C++, your modifications will be overwritten.

/////////////////////////////////////////////////////////////////////////////
// CSPELCom3 wrapper class

class CSPELCom3 : public CWnd
{
protected:
	DECLARE_DYNCREATE(CSPELCom3)
public:
	CLSID const& GetClsid()
	{
		static CLSID const clsid
			= { 0x185ad211, 0xc3aa, 0x11d2, { 0x94, 0x1e, 0x0, 0x60, 0x97, 0x1d, 0x5d, 0xe } };
		return clsid;
	}
	virtual BOOL Create(LPCTSTR lpszClassName,
		LPCTSTR lpszWindowName, DWORD dwStyle,
		const RECT& rect,
		CWnd* pParentWnd, UINT nID,
		CCreateContext* pContext = NULL)
	{ return CreateControl(GetClsid(), lpszWindowName, dwStyle, rect, pParentWnd, nID); }

    BOOL Create(LPCTSTR lpszWindowName, DWORD dwStyle,
		const RECT& rect, CWnd* pParentWnd, UINT nID,
		CFile* pPersist = NULL, BOOL bStorage = FALSE,
		BSTR bstrLicKey = NULL)
	{ return CreateControl(GetClsid(), lpszWindowName, dwStyle, rect, pParentWnd, nID,
		pPersist, bStorage, bstrLicKey); }

// Attributes
public:
	CString GetPassword();
	void SetPassword(LPCTSTR);
	short GetTimeOut();
	void SetTimeOut(short);
	BOOL GetMotorsOn();
	void SetMotorsOn(BOOL);
	CString GetErrorMessage();
	long GetErrorNumber();
	BOOL GetDesignMode();
	void SetDesignMode(BOOL);
	BOOL GetPowerHigh();
	void SetPowerHigh(BOOL);
	CString GetProject();
	void SetProject(LPCTSTR);
	BOOL GetPortOpen();
	void SetPortOpen(BOOL);
	BOOL GetQPOn();
	void SetQPOn(BOOL);
	LPDISPATCH GetVideoControl();
	void SetVideoControl(LPDISPATCH);
	short GetRobot();
	void SetRobot(short);
	short GetForce_Sensor();
	void SetForce_Sensor(short);
	BOOL GetForce_TCOn();
	void SetForce_TCOn(BOOL);

// Operations
public:
	void Abort();
	void Accel(short PointToPointAccel, short PointToPointDecel);
	void AccelS(short CPAccel);
	void Arch(short ArchNumber, float VerticalRise, float VerticalLower);
	void ArmSet(short ArmNumber, float Param1, float Param2, float Param3, float Param4, float Param5);
	double Atan(double Number);
	double Atan2(double Dx, double Dy);
	void BuildProject();
	void Clear();
	void Cont();
	float CX(const VARIANT& Point);
	float CY(const VARIANT& Point);
	float CZ(const VARIANT& Point);
	short Ctr(short BitNumber);
	void CtReset(short BitNumber);
	float CU(const VARIANT& Point);
	void Delay(long ms);
	double DegToRad(double Degrees);
	void ExecSPELCmd(LPCTSTR Command);
	void Fine(long Axis1Pulses, long Axis2Pulses, long Axis3Pulses, long Axis4Pulses);
	BOOL GetBitValue(long InputData, short BitNumber);
	void Halt(short TaskNumber);
	void HomeSet(long Axis1Pulses, long Axis2Pulses, long Axis3Pulses, long Axis4Pulses);
	void Home();
	void Hordr(short Home1, short Home2, short Home3, short Home4);
	void Out(short PortNumber, short PortValue);
	void OpBCD(short PortNumber, short PortValue);
	void JRange(short AxisNumber, long AxisMinPulses, long AxisMaxPulses);
	void MCal();
	short In(short PortNumber);
	long Hour();
	short InBCD(short PortNumber);
	BOOL Sw(short BitNumber);
	BOOL Oport(short BitNumber);
	BOOL AtHome();
	BOOL AxisLocked(short AxisNumber);
	BOOL CommandInCycle();
	void GetPoint(const VARIANT& Point, float* XCoord, float* YCoord, float* ZCoord, float* UCoord, short* LocalNumber, short* Orientation);
	BOOL JS();
	long Stat(short Address);
	BOOL EnableOn();
	BOOL ErrorOn();
	BOOL EstopOn();
	BOOL MCalComplete();
	double RadToDeg(double Radians);
	void Pause();
	BOOL PauseOn();
	void PDel(short FirstPointNumber, short LastPointNumber);
	long Pls(short AxisNumber);
	void PrgRst();
	BOOL ProjectBuildComplete();
	void Pulse(long Axis1Pulses, long Axis2Pulses, long Axis3Pulses, long Axis4Pulses);
	void Quit(short TaskNumber);
	void Range(long Axis1MinPulses, long Axis1MaxPulses, long Axis2MinPulses, long Axis2MaxPulses, long Axis3MinPulses, long Axis3MaxPulses, long Axis4MinPulses, long Axis4MaxPulses);
	CString Reply();
	void Reset();
	void Resume(short TaskNumber);
	CString RobotModel();
	void RunDialog(long DialogID);
	BOOL SafetyOn();
	void SavePoints(LPCTSTR PointFileName);
	void SetPoint(const VARIANT& Point, float XCoord, float YCoord, float ZCoord, float UCoord, short LocalNumber, short Orientation);
	void Arm(short ArmNumber);
	short GetArm();
	void LimZ(float ZLimit);
	float GetLimZ();
	void Tool(short ToolNumber);
	short GetTool();
	void TGo(const VARIANT& Destination);
	void TLSet(short ToolNumber, float XCoord, float YCoord, float ZCoord, float UCoord);
	void TMove(const VARIANT& Destination);
	BOOL TrapStop();
	BOOL TW();
	BOOL VCal(LPCTSTR CalibName);
	BOOL VCalPoints(LPCTSTR CalibName);
	void On(short BitNumber, const VARIANT& Seconds, const VARIANT& Parallel);
	void Off(short BitNumber, const VARIANT& Seconds, const VARIANT& Parallel);
	void Speed(short PointToPointSpeed);
	void SpeedS(short CPSpeed);
	BOOL TaskStatus(short TaskNumber);
	BOOL TasksExecuting();
	void SFree(const VARIANT& AxisNumber1, const VARIANT& AxisNumber2, const VARIANT& AxisNumber3, const VARIANT& AxisNumber4);
	void SLock(const VARIANT& AxisNumber1, const VARIANT& AxisNumber2, const VARIANT& AxisNumber3, const VARIANT& AxisNumber4);
	short MemIn(short PortNumber);
	void MemOut(short PortNumber, short PortValue);
	void MemOn(short BitNumber);
	void MemOff(short BitNumber);
	void WaitSw(short BitNumber, BOOL Condition, float TimeInterval);
	void WaitMem(short BitNumber, BOOL Condition, float TimeInterval);
	void SpeedEx(short PointToPointSpeed, short JumpUpSpeed, short JumpDownSpeed);
	void AccelEx(short PointToPointAccel, short PointToPointDecel, short JumpUpAccel, short JumpUpDecel, short JumpDownAccel, short JumpDownDecel);
	void Local(short LocalNumber, short LocalPoint1, short GlobalPoint1, short LocalPoint2, short GlobalPoint2);
	void LLocal(short LocalNumber, short LocalPoint1, short GlobalPoint1, short LocalPoint2, short GlobalPoint2);
	void RLocal(short LocalNumber, short LocalPoint1, short GlobalPoint1, short LocalPoint2, short GlobalPoint2);
	void MCordr(short MCal1, short MCal2, short MCal3, short MCal4);
	void Weight(float PayloadWeight, float ArmLength);
	void XYLim(float XLowerLimit, float XUpperLimit, float YLowerLimit, float YUpperLimit);
	float Agl(short JointNumber);
	long Call(LPCTSTR FunctionName);
	short ParseString(LPCTSTR InputString, const VARIANT& Tokens, LPCTSTR Delimiter);
	BOOL MemSw(short BitNumber);
	void VerInit();
	CString GetVersion();
	void ResetAbort();
	void VRun(LPCTSTR Sequence);
	void VLoadModel(LPCTSTR Sequence, LPCTSTR Object, LPCTSTR FileName);
	void VSaveModel(LPCTSTR Sequence, LPCTSTR Object, LPCTSTR FileName);
	void VStatsShow(LPCTSTR Sequence);
	void VStatsSave();
	void VStatsResetAll();
	void VStatsReset(LPCTSTR Sequence);
	void SetSPELVar(LPCTSTR VarName, const VARIANT& Value);
	VARIANT GetSPELVar(LPCTSTR VarName);
	void SetSPELArray(LPCTSTR ArrayName, short Index, const VARIANT& Value);
	VARIANT GetSPELArray(LPCTSTR ArrayName, short Index);
	void VGetCameraXYU(LPCTSTR Sequence, LPCTSTR Object, short ResultNumber, BOOL* Found, float* X, float* Y, float* U);
	void VGetExtrema(LPCTSTR Sequence, LPCTSTR Object, short ResultNumber, BOOL* Found, float* MinX, float* MaxX, float* MinY, float* MaxY);
	void VGetModelWin(LPCTSTR Sequence, LPCTSTR Object, short* Left, short* Top, short* Width, short* Height);
	void VGetRobotXYU(LPCTSTR Sequence, LPCTSTR Object, short ResultNumber, BOOL* Found, float* X, float* Y, float* U);
	void VGetSearchWin(LPCTSTR Sequence, LPCTSTR Object, short* Left, short* Top, short* Width, short* Height);
	void VSetModelWin(LPCTSTR Sequence, LPCTSTR Object, short Left, short Top, short Width, short Height);
	void VSetSearchWin(LPCTSTR Sequence, LPCTSTR Object, short Left, short Top, short Width, short Height);
	void VGetPixelXYU(LPCTSTR Sequence, LPCTSTR Object, short ResultNumber, BOOL* Found, float* X, float* Y, float* U);
	void LoadSPELGroup(LPCTSTR GroupName);
	void VGet(LPCTSTR Sequence, LPCTSTR Object, LPCTSTR Property_, VARIANT* Value);
	void VCls();
	void VGetPixelLine(LPCTSTR Sequence, LPCTSTR Object, float* X1, float* Y1, float* X2, float* Y2);
	void VTeach(LPCTSTR Sequence, LPCTSTR Object);
	void VSet(LPCTSTR Sequence, LPCTSTR Object, LPCTSTR Property_, const VARIANT& Value);
	void VSaveImage(LPCTSTR Sequence, LPCTSTR FileName);
	void Here(const VARIANT& Point);
	void JTran(short JointNumber, float Distance);
	void PTran(short JointNumber, long Pulses);
	float PAgl(const VARIANT& Point, short JointNumber);
	void VSaveProps();
	void EnableEvent(long EventNumber, BOOL Enabled);
	void AssignPoint(short Destination, const VARIANT& Source);
	void Go(const VARIANT& Destination);
	void Jump(const VARIANT& Destination);
	void Move(const VARIANT& Destination);
	void Pallet(short PalletNumber, const VARIANT& Point1, const VARIANT& Point2, const VARIANT& Point3, const VARIANT& Point4, short Columns, short Rows);
	void Xqt(short TaskNumber, LPCTSTR Function, const VARIANT& NoPause);
	short RobotType();
	void GetIODef(long IOType, short BitNumber, BSTR* IOName, BSTR* Description);
	void SetIODef(long IOType, short BitNumber, LPCTSTR IOName, LPCTSTR Description);
	void LoadPoints(LPCTSTR PointFileName, const VARIANT& Merge);
	void Arc(const VARIANT& MidPoint, const VARIANT& EndPoint);
	void VCreateSequence(LPCTSTR SequenceName);
	void VCreateObject(LPCTSTR Sequence, LPCTSTR ObjectName, long ObjectType);
	void VDeleteSequence(LPCTSTR Sequence);
	void VDeleteObject(LPCTSTR Sequence, LPCTSTR Object);
	void Base(float XOrigin, float YOrigin, float ZOrigin, float Angle);
	float ENetIO_AnaIn(long Channel);
	void ENetIO_AnaOut(long Channel, float Value);
	BOOL ENetIO_Sw(long BitNumber);
	short ENetIO_In(long PortNumber);
	void ENetIO_Out(long PortNumber, long Value);
	void ENetIO_AnaGetConfig(long Channel, float* Gain, float* Offset, float* LoScale, float* HiScale);
	void ENetIO_AnaSetConfig(long Channel, float Gain, float Offset, float LoScale, float HiScale);
	void ENetIO_ClearLatches(long BitNumber);
	BOOL ENetIO_SwLatch(long BitNumber, long LatchType);
	void Force_Calibrate();
	void Force_ClearTrigger();
	float Force_GetForce(long Axis);
	void ENetIO_On(long BitNumber, const VARIANT& Seconds);
	void ENetIO_Off(long BitNumber, const VARIANT& Seconds);
	void Force_GetForces(const VARIANT& Axes);
	void Force_SetTrigger(long Axis, float Threshold, long CompareType);
	void Force_TCLim(short J1TorqueLimit, short J2TorqueLimit, short J3TorqueLimit, short J4TorqueLimit);
	void Force_TCSpeed(short Speed);
	BOOL ENetIO_Oport(long BitNumber);
	void LogIn(LPCTSTR LogID, LPCTSTR Password);
	CString GetCurrentUser();
	void VShowSequence(LPCTSTR Sequence);
	void VShowModel(LPCTSTR Sequence, LPCTSTR Object);
	BOOL VTrain(LPCTSTR Sequence, LPCTSTR Object, const VARIANT& Flags);
	void RestartSPEL();
	void Shutdown(long Mode);
	void RebuildProject();
	void Curve(LPCTSTR FileName, BOOL Closure, long Mode, long NumOfAxes, LPCTSTR PointList);
	void CVMove(LPCTSTR FileName, const VARIANT& OptionList);
	BOOL TillOn();
};

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_SPELCOM3_H__D18EA672_D8C8_4F4C_80CF_6A334B267794__INCLUDED_)