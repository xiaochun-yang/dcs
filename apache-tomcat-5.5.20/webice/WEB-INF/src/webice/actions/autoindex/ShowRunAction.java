/**
 * Javabean for SMB resources
 */
package webice.actions.autoindex;

import java.io.IOException;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import org.apache.struts.action.Action;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;

import webice.beans.*;
import webice.beans.autoindex.*;
import webice.beans.dcs.*;


public class ShowRunAction extends Action
{

	public ActionForward execute(ActionMapping mapping,
							ActionForm f,
							HttpServletRequest request,
							HttpServletResponse response)
				throws Exception
	{

		HttpSession session = request.getSession();

		Client client = (Client)session.getAttribute("client");

		if (client == null)
			throw new NullClientException("Client is null");

		AutoindexViewer viewer = client.getAutoindexViewer();

		if (viewer == null)
			throw new ServletException("AutoindexViewer is null");

		String tab = viewer.getSelectedRunTab();
		if ((tab == null) || (tab.length() == 0))
			tab = "autoindex";

		AutoindexRun run = viewer.getSelectedRun();
		String appPath = request.getSession().getServletContext().getRealPath("");
		String impUrl = "http://" + ServerConfig.getImpServerHost()
							+ ":" + ServerConfig.getImpServerPort();
		if (!run.isTabViewable(tab))
			return mapping.findForward("notViewable");

		try {

		if (tab.equals("autoindex")) {


			request.setAttribute("xml", run.getAutoindexResultFile());
			// TODO: move xsl path to config file.
			request.setAttribute("xsl", appPath + "/pages/autoindex/autoindex.xsl");
			request.setAttribute("param1", run.getRunName());
			request.setAttribute("param2", client.getUser());
			request.setAttribute("param3", client.getSessionId());
			request.setAttribute("param4", run.getLabelitOutFile());
			request.setAttribute("param5", ServerConfig.getHelpUrl());

		} else if (tab.equals("solutions")) {

			String url = request.getRequestURL().toString();
			String servletName = request.getContextPath();
			int pos = url.indexOf(servletName);
			String baseUrl = url.substring(0, pos+servletName.length());

			request.setAttribute("xml", run.getAutoindexResultFile());
			// TODO: move xsl path to config file.
			request.setAttribute("xsl", appPath + "/pages/autoindex/solutions.xsl");
			request.setAttribute("param1", run.getRunName());
			request.setAttribute("param2", client.getUser());
			request.setAttribute("param3", client.getSessionId());
			request.setAttribute("param4", run.getWorkDir());
			request.setAttribute("param5", baseUrl);
			request.setAttribute("param6", impUrl);
			request.setAttribute("param7", String.valueOf(run.getSelectedSolution()));
			request.setAttribute("param18", ServerConfig.getHelpUrl());

		} else if (tab.equals("strategy")) {
		
			if (!run.getRunController().isGenerateStrategy()) {
			
				tab = "no_strategy";
			
			} else {
			
			boolean queueEnabled = false;
			DcsConnector dcs = client.getDcsConnector();
			if (dcs != null)
				queueEnabled = dcs.isQueueEnabled();
	
			request.setAttribute("xml", run.getAutoindexResultFile());
			// TODO: move xsl path to config file.
			request.setAttribute("xsl", appPath + "/pages/autoindex/strategy.xsl");
			request.setAttribute("param1", run.getRunName());
			request.setAttribute("param2", client.getUser());
			request.setAttribute("param3", client.getSessionId());
			request.setAttribute("param4", run.getWorkDir());
			request.setAttribute("param5", run.getSelectedSpaceGroup());
			request.setAttribute("param6", String.valueOf(run.getShowStrategyDetails()));
			request.setAttribute("param7", String.valueOf(run.getPhiStrategyType()));
			request.setAttribute("param8", impUrl);
			request.setAttribute("param9", run.getSelectedSolution());
			request.setAttribute("param10", run.getStrategyType());
			request.setAttribute("param11", run.getExpType());
			request.setAttribute("param12", ServerConfig.getHelpUrl());
			request.setAttribute("param13", String.valueOf(queueEnabled));
			
			} 
			
		} else if (tab.equals("predictions")) {
		
			AutoindexSetupData d = run.getRunController().getSetupData();
			double version = d.getVersion();
			// If the run was generated by an older version
			// then use old prediction page
			// which displays png files.
			// Newer runs do not have png files generated
			// instead they have image markup files.
			if (version < 2.0)
				tab = "predictions_old"; 
		}

		return mapping.findForward(tab);
		
		} catch (Exception e) {
			WebiceLogger.error("ShowRunAction", e);
			request.setAttribute("error", e.getMessage());
			return mapping.findForward("error");
		}

	}



}
