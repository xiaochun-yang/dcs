package sil.test;

import java.util.*;
import java.net.*;
import java.io.*;

public class SimBeamline1
{
	private Vector clients = new Vector();
	private SimImpersonDhs dhs = null;

	private int maxBluice = 5;

	private String silFile = "";

	volatile int id = -1;
	volatile int eventId = -1;

	/**
	 */
	public SimBeamline1()
	{
	}

	/**
	 */
	public void run()
	{
		try {

		// look for new event for the sil
		boolean done = false;
		while (!done) {
			// Update cassette info on all position at this beamline
			getCassetteData();
			// Get latest event id of the cassette at the active position
			id = getLatestEventId();
			if (id > eventId) {
				System.out.println("SimBeamline: New eventId = " + id);
				for (int i = 0; i < maxBluice; ++i) {
					SimBluice bluice = (SimBluice)clients.elementAt(i);
					bluice.setLatestEventId(eventId);
				}
				eventId = id;
			}
			Thread.sleep(1000);
		}

		} catch (Exception e) {
			System.out.println("Error in SimBeamline::runBluice: " + e.toString());
			e.printStackTrace();
		}
	}


	/**
	 */
	public int getLatestEventId()
		throws Exception
	{
		HttpURLConnection con = null;
		InputStreamReader reader = null;

		try {

			String urlStr = "http://" + SimConfig.host + ":" + SimConfig.port
							+ "/crystals-dev/getLatestEventId.do?silId=" + SimConfig.silId;

			URL url = new URL(urlStr);
			con = (HttpURLConnection)url.openConnection();
			con.setRequestMethod("GET");

			int responseCode = con.getResponseCode();
			if (responseCode != 200) {
				System.out.println("Failed in getLatestEventId: (" + responseCode + ")"
									+ " " + con.getResponseMessage());
				con.disconnect();
				return -1;
			}

			reader = new InputStreamReader(con.getInputStream());
			char buf[] = new char[200];
			int num = 0;
			StringBuffer body = new StringBuffer();
			while ((num=reader.read(buf, 0, 200)) >= 0) {
				if (num > 0) {
					body.append(buf, 0, num);
				}
			}
			buf = null;

			return Integer.parseInt(body.toString());

		} catch (NumberFormatException e) {
			System.out.println("Simbeamline Failed in getLatestEventId: " + e.toString());
			e.printStackTrace();
		} finally {

			if (reader != null)
				reader.close();
			reader = null;

			if (con != null)
				con.disconnect();
			con = null;
		}

		return -1;

	}


	/**
	 */
	public void getCassetteData()
		throws Exception
	{
		HttpURLConnection con = null;
		InputStreamReader reader = null;

		try {

			String urlStr = "http://" + SimConfig.host + ":" + SimConfig.port
							+ "/crystals-dev/getCassetteData.do?forBeamLine=" + SimConfig.beamline;

			URL url = new URL(urlStr);
			con = (HttpURLConnection)url.openConnection();
			con.setRequestMethod("GET");

			int responseCode = con.getResponseCode();
			if (responseCode != 200) {
				System.out.println("Failed in getCassetteData: (" + responseCode + ")"
									+ " " + con.getResponseMessage());
				con.disconnect();
				return;
			}

			reader = new InputStreamReader(con.getInputStream());
			char buf[] = new char[200];
			int num = 0;
			StringBuffer body = new StringBuffer();
			while ((num=reader.read(buf, 0, 200)) >= 0) {
				if (num > 0) {
					body.append(buf, 0, num);
				}
			}
			buf = null;

			String bodyStr = body.toString();

			if (bodyStr.startsWith("<Error")) {
				System.out.println("getCassetteData returns error: " + bodyStr);
			}

			body = null;
			bodyStr = null;


		} catch (NumberFormatException e) {
			System.out.println("Simbeamline Failed in getLatestEventId: " + e.toString());
			e.printStackTrace();
		} finally {

			if (reader != null)
				reader.close();
			reader = null;

			if (con != null)
				con.disconnect();
			con = null;
		}

		return;

	}


	/**
	 */
	static public void main(String args[])
	{
		try {

		if (args.length != 4) {
			System.out.println("Usage: SimClients <beamline> <cassetteIndex> <silId> <sessionId>");
			System.exit(0);
		}

		SimConfig.beamline = args[0];
		SimConfig.cassetteIndex = args[1];
		SimConfig.silId = args[2];
		SimConfig.sessionId = args[3];

		SimBeamline1 beamline = new SimBeamline1();

		beamline.run();

		} catch (Exception e) {
			System.out.println("Error in main: " + e.toString());
			e.printStackTrace();
		}
	}

}
