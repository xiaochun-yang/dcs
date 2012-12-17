/**
 * Javabean for SMB resources
 */
package webice.beans.strategy;

import webice.beans.*;
import java.util.*;
import java.io.*;

/**
 * @class IntegrateNode
 * Bean class that represents a process viewer. Holds parameters for setting
 * up a display for data processing.
 */
public class IntegrateNode extends NavNode
{

	private StrategyViewer top = null;
	private Client client = null;

	/**
	 */
	private Vector nodeViewerFiles = new Vector();

	static private String TAB_SPACEGROUP_SUMMARY = "Strategy Summary";
	static private String TAB_SUMMARY = "Integration Results";
	static private String TAB_DETAILS = "Details";


	private Vector groups = null;

	/**
	 * Vector of SolutionResult
	 */
	private Vector results = new Vector();

	private String log = "";

	private boolean summaryLoaded = false;
	private boolean strategySummaryLoaded = false;

	private String strategySummary = "";


	/**
	 * List of known files generated by labelit
	 * Hashtable of filename and FileInfo
	 * File names are relative to workDir of
	 * this node
	 */
	private TreeMap resultFiles = new TreeMap();

	/**
	 */
	public IntegrateNode(String n, NavNode p, StrategyViewer v)
		throws Exception
	{
		super(n, p);

		top = v;
		client = top.getClient();

		init();

	}

	private void init()
		throws Exception
	{
		clearTabs();


		addTab(TAB_SPACEGROUP_SUMMARY);
		addTab(TAB_SUMMARY);
		addTab(TAB_DETAILS);

		setSelectedTab(TAB_SPACEGROUP_SUMMARY);

		loadSetup();

		loadResult();

		loadStrategySummary();

		loadDetails();

		loadChildren();

	}



	public void loadSetup()
	{
		try {

			loadSpacegroups();

		} catch (Exception e) {
			log += "Failed to load spacegroups for this solution: " + e.getMessage();
		}
	}

	/**
	 * Parse integration result
	 */
	public void loadResult()
	{
		try {

		summaryLoaded = false;
		results.clear();

		String prefix = "solution";
		String suffix = getName().substring(prefix.length());

		String outFile = getWorkDir() + "/index" + suffix + ".out";

		String content = client.getImperson().readFile(outFile);

		int pos1 = 0;
		int pos2 = 0;
		boolean finished = false;

		while (!finished) {

			// Find image file name

			// There is one of these lines for each image file
			pos1 = content.indexOf(" image FILENAME:", pos2);

			// No more image
			if (pos1 < 0) {
				finished = true;
				break;
			}

			// Object representing result for each image
			SolutionResult sol = new SolutionResult();

			// Find end of line
			pos2 = content.indexOf('\n', pos1);

			if (pos2 < 0)
				throw new Exception("Could not find end of line after 'image FILENAME:' in file: " + outFile);

			// Get image file name
			sol.fileName = content.substring(pos1+16, pos2).trim();


			// Find average spot profile for this image


			pos1 = content.indexOf("AVERAGE SPOT PROFILE", pos2);

			if (pos1 < 0)
				throw new Exception("Could not find 'AVERAGE SPOT PROFILE' in file: " + outFile);


			// Find end of line before the 'AVERAGE SPOT PROFILE'
			while (pos1 > 0) {
				if (content.charAt(pos1) == '\n')
					break;

				--pos1;
			}

			if (pos1 == 0)
				throw new Exception("Could not find end of line before 'AVERAGE SPOT PROFILE' in file: " + outFile);

			++pos1;

			// Find an empty line
			pos2 = content.indexOf("\n\n", pos1);
			if (pos2 < 0)
				throw new Exception("Could not find end the first empty line after 'AVERAGE SPOT PROFILE' in file: " + outFile);

			// Find another empty line
			pos2 = content.indexOf("\n\n", pos2+2);
			if (pos2 < 0)
				throw new Exception("Could not find end the second empty line after 'AVERAGE SPOT PROFILE' in file: " + outFile);


			// Average spot profile for this image
			sol.averageProfile = encodeHtml(content.substring(pos1, pos2));


			// Find I/Sigma statistics


			pos1 = content.indexOf(" Analysis as", pos2);

			if (pos1 < 0) {
//				throw new Exception("Could not find 'Analysis as' in file: " + outFile);
				continue;
			}

			pos2 = content.indexOf(" Intensity as", pos1);

			if (pos2 < 0)
				throw new Exception("Could not find 'Intensity as' in file: " + outFile);

			// I/Sigma statistics
			sol.statistics = encodeHtml(content.substring(pos1, pos2));

			results.add(sol);


		}

		summaryLoaded = true;


		} catch (Exception e) {
			log += "Failed to load or parse result: " + e.getMessage() + "\n";
		}
	}

	/**
	 */
	public void loadStrategySummary()
	{
		try {

			strategySummaryLoaded = false;
			strategySummary = "";

			String file = getWorkDir() + "/strategy_summary.out";
			strategySummary = client.getImperson().readFile(file);
/*
			StringTokenizer tok = new StringTokenizer(content, "\n\r");
			while (tok.hasMoreTokens()) {
				String line = tok.nextToken();
				StringTokenizer tok1 = new StringTokenizer(tok.nextToken(), " \t");
				String headers = tok1.nextToken();

			}
*/
			strategySummaryLoaded = true;

		} catch (Exception e) {
			log += "Failed to load or parse strategy summary: " + e.getMessage() + "\n";
		}
	}

	/**
	 */
	public void loadDetails()
	{
		try {

		// Clear old results
		resultFiles.clear();

		TreeMap tmpFiles = new TreeMap();
		client.getImperson().listDirectory(getWorkDir(),
											null,
											null,
											tmpFiles);



		// Get result files
		Object values[] = tmpFiles.values().toArray();

		// Filter files of the known types
		if (values != null) {
			for (int i = 0; i < values.length; ++i) {
				FileInfo info = (FileInfo)values[i];
				info.type = FileHelper.getFileType(info.name);
				if (info.type != FileHelper.UNKNOWN) {
					resultFiles.put(info.name, info);
				}
			}
		}

		} catch (Exception e) {
			log += "Failed to list directory for " + getName() + "\n";
		}
	}


	/**
	 */
	public void loadChildren()
		throws Exception
	{

		removeChildren();

		TreeMap dirs = new TreeMap();
		client.getImperson().listDirectory(getWorkDir(),
											null,
											dirs,
											null);


		// Each sub directory whose name
		// begins with solution is a child of this node
		Object keys[] = dirs.keySet().toArray();
		if (keys != null) {

			for (int i = 0; i < keys.length; ++i) {
				String key = (String)keys[i];
				try {
				SpacegroupNode child = new SpacegroupNode(key, this, top);
				child.load();
				addChild(child);
				} catch (Exception e) {
					log += "Failed to load spacegroup " + key + ": " + e.getMessage() + "\n";
				}
			}
		}


	}

	/**
	 * Reload a child node. Delete old one, if exists, and
	 * replace it with a new one loaded from disk.
	 * @param s Child node name
	 * @exception Exception Thrown if reload fails.
	 */
	public NavNode reloadChild(String aName)
		throws Exception
	{

		// try to delete child node
		// If it does not exist then removeChild
		// does nothings
		removeChild(aName);


		// Create a new child node
		SpacegroupNode aNode = new SpacegroupNode(aName, this, top);
		addChild(aNode);

		return aNode;

	}

	public String getType()
	{
		return "strategy";
	}

	public String getDesc()
	{
		return "Solution Refinement and Integration";
	}


	public String getLog()
	{
		return log;
	}

	public void setLog(String s)
	{
		log = s;
	}

	public String getWorkDir()
	{
		return top.getWorkDir() + getPath();
	}

	private void loadSpacegroups()
		throws Exception
	{

		String prefix = "solution";
		String suffix = getName().substring(prefix.length());
		String scriptFile = "index" + suffix + ".mfm";

		Imperson imperson = client.getImperson();


		// Read mosflm script
		String content = imperson.readFile(getWorkDir() + "/" + scriptFile);

		int pos1 = content.indexOf("SYMMETRY");

		if (pos1 < 0)
			throw new Exception("Failed to find 'SYMMETRY' in file " + scriptFile);

		int pos2 = content.indexOf("\n", pos1);

		if (pos2 < 0)
			throw new Exception("Failed to find end of line after 'SYMMETRY' in file " + scriptFile);

		// Labelit uses the lowest symmetry to generate this
		// strategy template script
		String lowestSymmetry = content.substring(pos1+8, pos2).trim();

		// Find the rest of the space group for this
		// crystal system
		groups = (Vector)SpacegroupHelper.getSpacegroups(lowestSymmetry);

		if (groups == null) {
			groups = new Vector();
			groups.add(lowestSymmetry);
		}

	}


	public Object[] getSpacegroups()
	{
		return groups.toArray();
	}

	public Object[] getSummaryResults()
	{
		return results.toArray();
	}

	/**
	 * Replace '<' and '>' with 'lt;' and 'gt;'
	 * for html content.
	 */
	private String encodeHtml(String s)
	{
		String out = "";

		out = s.replaceAll("<", "&lt;");

		return out.replaceAll(">", "&gt;");
	}

	public Object[] getResultFiles()
	{
		return resultFiles.values().toArray();
	}

	/**
	 * Whether or not the tab is ready to display
	 * contents.
	 */
	public boolean isTabViewable(String tabName)
	{

		if (tabName.equals(TAB_SPACEGROUP_SUMMARY)) {
			return strategySummaryLoaded;
		} else if (tabName.equals(TAB_SUMMARY)) {
			return summaryLoaded;
		} else if (tabName.equals(TAB_DETAILS)) {
			return true;
		}

		return false;
	}

	/**
	 */
	public String getStrategySummary()
	{
		return strategySummary;
	}

}
