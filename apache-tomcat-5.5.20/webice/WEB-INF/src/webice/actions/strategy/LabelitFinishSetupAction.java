/**
 * Javabean for SMB resources
 */
package webice.actions.strategy;

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
import webice.beans.strategy.*;
import webice.actions.common.StringForm;


public class LabelitFinishSetupAction extends Action
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


		StrategyViewer top = client.getStrategyViewer();

		if (top == null)
			throw new ServletException("StrategyViewer is null");

		LabelitNode node = (LabelitNode)top.getSelectedNode();

		if (node == null)
			throw new ServletException("Selected node is null");

		LabelitForm form = (LabelitForm)f;

		String res = form.getDone();

		node.resetLog();

		if (res.equals("Reset Form")) {
			node.resetSetupData();
		} else if (res.equals("OK")) {
			LabelitSetupData setupData = node.getSetupData();
			setupData.setIntegrate(form.getIntegrate());
			setupData.setGenerateStrategy(form.isGenerateStrategy());
			// Commit the setup data
			node.finishSetup();
		}

		return mapping.findForward("success");


	}



}
