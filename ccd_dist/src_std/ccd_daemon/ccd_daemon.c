#ifndef VMS
#include	<stdio.h>
#include	<sys/types.h>
#include	<sys/time.h>
#include	<sys/socket.h>
#include	<signal.h>
#include	<sys/wait.h>
#include	<netinet/in.h>
#include	<errno.h>
#include	<netdb.h>
#include	<fcntl.h>
#else
#include	<stdio.h>
#include	<types.h>
#include	<time.h>
#include	<socket.h>
#include	<in.h>
#include	<errno.h>
#include	<netdb.h>
#include	"../incl/vms_select.h"
#endif /* VMS */

#include	"../incl/ccdsys.h"

/*
 *	Status definitions.
 */

#ifdef VMS
#define	BAD_STATUS	2
#define GOOD_STATUS	1
#else
#define	BAD_STATUS	1
#define	GOOD_STATUS	0
#endif /* VMS */

/*
 *----------------------------------------------------------------
 *
 *	ccd_daemon:
 *
 *	Latest revision.  Used for both the disk and networked
 *	versions.
 *
 *----------------------------------------------------------------
 */

char	*getenv();

extern struct serverlist	dcserver;
extern struct serverlist	dtserver;
extern struct serverlist	blserver;
extern struct serverlist	daserver;
extern struct serverlist	xfserver;
extern struct serverlist	stserver;
extern struct serverlist	conserver;
extern struct serverlist	viewserver;
extern int			ccd_communication;

int	fddaemon;	/* file descriptor to daemon */
int	use_tty_output;	/* 1 to use tty instead of log files for the processes */

int	shutdown_req;

/*
 *	These are the various argument options the program can take.
 */

char	*options[] = {
			"startup",
			"shutdown",
			"status",
			"exit",
			"initialize",
			NULL
		     };

enum {
	OPT_STARTUP = 0,
	OPT_SHUTDOWN,
	OPT_STATUS,
	OPT_EXIT,
	OPT_INIT
     };

#define	OPT_BAD		-1

int	optnums[] = {
		    OPT_STARTUP,
		    OPT_SHUTDOWN,
		    OPT_STATUS,
		    OPT_EXIT,
		    OPT_INIT,
		    OPT_INIT,
		    OPT_BAD
		    };

struct	pgms {
		pid_t	pgm_pid;
		char	*pgm_name;
		int	pgm_num;
	     };


#define	PROG_STATUS	0
#define	PROG_XFORM	1
#define	PROG_CONTROL	2
#define	PROG_BL		3
#define	PROG_DET	4
#define	PROG_CCD_DC	5

#define	MAXPROG		6

struct pgms progs[MAXPROG];	/* this is assigned when the proper program set is determined */
int	nprogs = 0;		/* this is set when the above is determined */

/*
 *	This routine figures out if the localhost name is among the list of
 *	official names or aliases for a given name.
 *
 *	Return 1 if it is the localhost, otherwise 0.
 */

int	is_local_host(lname,hname)
char	*lname,*hname;
  {
	if(0 == strcmp(lname,hname))
		return(1);
	  else
		return(0);
  }

/*
 *	This routine sets up the program names, etc., which will be
 *	started up.
 */

set_progs()
  {
	char	local_host_name[256];

	if(ccd_communication == CCD_COM_DISK)
	  {
	    progs[0].pgm_pid = 0;
	    progs[0].pgm_name = dcserver.sl_srname;
	    progs[0].pgm_num = PROG_CCD_DC;

	    progs[1].pgm_pid = 0;
	    progs[1].pgm_name = xfserver.sl_srname;
	    progs[1].pgm_num = PROG_XFORM;
	    
	    progs[2].pgm_pid = 0;
	    progs[2].pgm_name = conserver.sl_srname;
	    progs[2].pgm_num = PROG_CONTROL;

	    nprogs = 3;
	  }
	 else
	  {
	    gethostname(local_host_name,256);
	    nprogs = 0;
	    if(dcserver.sl_port != -1 && 1 == is_local_host(local_host_name,dcserver.sl_hrname))
	      {
		progs[nprogs].pgm_pid = 0;
		progs[nprogs].pgm_name = dcserver.sl_srname;
		progs[nprogs].pgm_num = PROG_CCD_DC;
		nprogs++;
	      }
	    if(dtserver.sl_port != -1 && 1 == is_local_host(local_host_name,dtserver.sl_hrname))
	      {
		progs[nprogs].pgm_pid = 0;
		progs[nprogs].pgm_name = dtserver.sl_srname;
		progs[nprogs].pgm_num = PROG_DET;
		nprogs++;
	      }
	    if(stserver.sl_port != -1 && 1 == is_local_host(local_host_name,stserver.sl_hrname))
	      {
		progs[nprogs].pgm_pid = 0;
		progs[nprogs].pgm_name = stserver.sl_srname;
		progs[nprogs].pgm_num = PROG_STATUS;
		nprogs++;
	      }
	    if(xfserver.sl_port != -1 && 1 == is_local_host(local_host_name,xfserver.sl_hrname))
	      {
		progs[nprogs].pgm_pid = 0;
		progs[nprogs].pgm_name = xfserver.sl_srname;
		progs[nprogs].pgm_num = PROG_XFORM;
		nprogs++;
	      }
	    if(blserver.sl_port != -1 && 1 == is_local_host(local_host_name,blserver.sl_hrname))
	      {
		progs[nprogs].pgm_pid = 0;
		progs[nprogs].pgm_name = blserver.sl_srname;
		progs[nprogs].pgm_num = PROG_BL;
		nprogs++;
	      }
	    if(conserver.sl_srname != NULL && 1 == is_local_host(local_host_name,conserver.sl_hrname))
	      {
		progs[nprogs].pgm_pid = 0;
		progs[nprogs].pgm_name = conserver.sl_srname;
		progs[nprogs].pgm_num = PROG_CONTROL;
		nprogs++;
	      }
	  }
  }

status_all(obuf)
char	*obuf;
  {
	int	i,j;
	char	buf[256];

	sprintf(buf,"ccd_daemon: status:\n");
	strcat(obuf,buf);
	for(i = 0; i < nprogs; i++)
	  {
	    if(progs[i].pgm_pid == 0)
		sprintf(buf,"\t\t%s: not running.\n",progs[i].pgm_name);
	     else
		sprintf(buf,"\t\t%s: running.\n",progs[i].pgm_name);
	    strcat(obuf,buf);
	  }
  }

/*
 *	Startup various processes (which are not running already).
 *
 *	Case:	Disk based system.
 *
 *		The dc, xf, and control processes are started up.
 *
 *	Case:	Network based system.
 *
 *		The dc,xf,st, and control processes are started
 *		up PROVIDED they run on this host.
 */

int	startup_all(obuf)
char	*obuf;
  {
	int	i,j;
	int	fd;
	pid_t	pid;
	char	buf[256];
	char	*cp;
	char	*ptr;
	uid_t	real_uid;
	gid_t	real_gid;

	for(i = 0; i < 9; i++)
	{
		sprintf(buf,"CCD_REMOTE_PC_HOST%d",i);
		if(NULL != (cp = getenv(buf)))
		{
			sprintf(buf,"signal_pc_remote %s 8038 restart", cp);
			system(buf);
		}
		else
		{
			break;
		}

	}
	for(i = 0; i < nprogs; i++)
	  if(progs[i].pgm_pid == 0)
	    {
		pid = fork();
		if(pid == 0)	/* child */
		  {
		    ptr = getenv("HOME");
		    switch(progs[i].pgm_num)
		      {
			case PROG_STATUS:
			  sprintf(buf,"%s/%s",ptr,LOG_ST_FILE);
			  unlink(buf);
			  break;
			case PROG_XFORM:
			  sprintf(buf,"%s/%s",ptr,LOG_XF_FILE);
			  unlink(buf);
			  break;
			case PROG_CCD_DC:
			  sprintf(buf,"%s/%s",ptr,LOG_DC_FILE);
			  unlink(buf);
			  break;
			case PROG_CONTROL:
			  sprintf(buf,"%s/%s",ptr,LOG_CON_FILE);
			  unlink(buf);
			  break;
			case PROG_BL:
			  sprintf(buf,"%s/%s",ptr,LOG_BL_FILE);
			  unlink(buf);
			  break;
			case PROG_DET:
			  sprintf(buf,"%s/%s",ptr,LOG_DET_FILE);
			  unlink(buf);
			  break;
		      }
		    if(use_tty_output == 0)
		    {
		    if(-1 == (fd = creat(buf,0666)))
		      {
			    fprintf(stderr,"ccd_daemon: (child) cannot create %s as log file\n",buf);
		      }
		    if(fd != -1)
		      {
			if(-1 == dup2(fd,1))
			    perror("ccd_daemon: (child) dup2 on stdout");
			if(-1 == dup2(fd,2))
			    perror("ccd_daemon: (child) dup2 on stderr");
		      }
		    }
		    sprintf(buf,"%s",progs[i].pgm_name);
		    if(-1 == execlp(buf,buf,NULL))
		      {
			    fprintf(stderr,"ccd_daemon: (child) cannot exec %s\n",buf);
			    cleanexit(0);
		      }
		  }
		 else
		  {
		    progs[i].pgm_pid = pid;
		    sprintf(buf,"ccd_daemon: %s started (pid %d)\n",progs[i].pgm_name,progs[i].pgm_pid);
		    strcat(obuf,buf);
		    sleep(3);	/* wait just a bit */
		  }
	  }
  }
		    
#define	ANYKID	-1

void	reap_child(sig)
int	sig;
  {
	pid_t	pid;
	int	status;
	int	i,j;

	pid = waitpid(ANYKID,&status,WNOHANG);
	while(pid > 0)
	  {
		for(i = 0; i < nprogs; i++)
		  if(progs[i].pgm_pid == pid)
		    {
			progs[i].pgm_pid = 0;
			break;
		    }
		pid = waitpid(ANYKID,&status,WNOHANG);
	  }
	if(shutdown_req)
	  {
		for(i = j = 0; i < nprogs; i++)
		  if(progs[i].pgm_pid != 0)
			j = 1;
		if(j == 0)
		  {
			cleanexit(GOOD_STATUS);
		  }
	  }
  }

shutdown_all(obuf)
char	*obuf;
  {
	int	i,any;
	char	buf[256];
	char	*cp;

	for(i = 0; i < 9; i++)
	{
		sprintf(buf,"CCD_REMOTE_PC_HOST%d",i);
		if(NULL != (cp = getenv(buf)))
		{
			sprintf(buf,"signal_pc_remote %s 8039 shutdown", cp);
			system(buf);
		}
		else
			break;
	}
	for(i = any = 0; i < nprogs; i++)
	  if(progs[i].pgm_pid != 0)
	    {
	      if(-1 == kill(progs[i].pgm_pid,SIGHUP))
	        {
		  sprintf(buf,"ccd_daemon: error (errno=%d) killing %s.\n",progs[i].pgm_name);
		  strcat(obuf,buf);
	        }
	       else
		{
		  any = 1;
		  sprintf(buf,"ccd_daemon: %s terminated.\n",progs[i].pgm_name);
		  strcat(obuf,buf);
		}
	    }
	if(shutdown_req && any == 0)
		cleanexit(GOOD_STATUS);	/* this is the case that no children exist */
  }

#define	EOMSG	"<eom>\n"

service_request(mode,fdnet,buf)
char	*buf;
  {
	char	obuf[2048];
	int	nb,ns,nbc;
	int	opt,i,j;
	fd_set	readmask, writemask, exceptmask;
	struct	timeval	timeout;

	timeout.tv_sec = 1;
	timeout.tv_usec = 0;

	if(mode == CCD_COM_TCPIP)
	  {
	    nbc = 0;
	    while(1)
	      {
		FD_ZERO(&readmask);
		FD_SET(fdnet,&readmask);
		ns = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
		if(ns == -1)
		  {
		    if(errno == EINTR)	/* if we get interrupted, is OK */
			continue;
		    perror("ccd_daemon: select error");
		    cleanexit(BAD_STATUS);
		  }
		if(ns == 0)
			break;	/* timed out */
	    	nb = read(fdnet,&buf[nbc],sizeof buf);
	        if(nb <= 0)
	          {
		    fprintf(stderr,"ccd_daemon: Error reading socket connection fd: with status: %d\n",fdnet,nb);
		    return;
	          }
		nbc += nb;
	        buf[nbc] = '\0';
	      }
	  }
	for(i = 0; options[i] != NULL; i++)
	  if(strcmp(buf,options[i]) == 0)
		break;
	opt = optnums[i];
	obuf[0] = '\0';
	switch(opt)
	  {
	    case OPT_STARTUP:
		startup_all(obuf);
		break;
	    case OPT_STATUS:
		status_all(obuf);
		break;
	    case OPT_SHUTDOWN:
		sprintf(obuf,"ccd_daemon: shutting down all progs by request.  daemon will still run.\n");
		shutdown_all(obuf);
		break;
	    case OPT_EXIT:
		sprintf(obuf,"ccd_daemon: shutting down all (including daemon) by request.\n");
		shutdown_req = 1;
		shutdown_all(obuf);
		break;
	    case OPT_INIT:
		sprintf(obuf,"ccd_daemon: started and waiting for subesequent startup command.\n");
		break;
	    case OPT_BAD:
		sprintf(obuf,"ccd_daemon: bad command %s given to daemon.\n",buf);
		break;
	  }
	if(mode == CCD_COM_TCPIP)
		strcat(obuf,EOMSG);
	nb = strlen(obuf);
	while(nb > 0)
	  {
	    ns = write(fdnet,obuf,nb);
	    if(ns < 0)
	      {
	        fprintf(stderr,"ccd_daemon: error writing done string to socket fd, status: %d\n",fdnet,nb);
	        return;
	      }
	    nb -= ns;
	  }
  }

#define	MAX_FDS		10

int	server_s;

main(argc,argv)
int	argc;
char	*argv[];
  {
	int	s;
	int     optname,optval,optlen;
	struct	sockaddr_in	from;
	int 	g;
	int	len;
	char	buf[512];
	int	nb;
	int	i,j,k,n;
	int	connected_fds[MAX_FDS];
	fd_set	readmask, writemask, exceptmask;
	struct	timeval	timeout;
	struct	sigaction	act;
	sigset_t		set,emptyset;

	shutdown_req = 0;
	use_tty_output = 0;

	while(argc > 1 && argv[1][0] == '-')
	  {
	    if(0 == strcmp(argv[1],"-tty"))
		use_tty_output = 1;
	     else
	      {
		fprintf(stderr,"ccd_daemon: %s is an UNKNOWN flag.\n",argv[1]);
		fprintf(stderr,"  THIS SHOULD NEVER HAPPEN; you need system help.\n");
		cleanexit(BAD_STATUS);
	      }
	    argc--;
	    argv++;
	  }

/*
 *	Install POSIX signal handling for children thusly forked off.
 */

	act.sa_handler = reap_child;
	act.sa_flags = 0;

	sigaction(SIGCHLD, &act, NULL);
	sigemptyset(&set);
	sigemptyset(&emptyset);
	sigaddset(&set, SIGCHLD);

	if(check_environ())
		cleanexit(BAD_STATUS);
	if(apply_reasonable_defaults())
		cleanexit(BAD_STATUS);
	set_progs();

	/*
	 *	If this is a disk communication based system,
	 *	copy the argument into the buffer and service
	 *	the request.  Then exit.
	 */
	if(ccd_communication == CCD_COM_DISK)
	  {
	    strcpy(buf,argv[1]);
	    service_request(CCD_COM_DISK,1,buf);
	    cleanexit(0);
	  }

	 /*
	  *	For tcpip based systems, set up the socket connection
	  *	and wait for connections and requests.  Perform each
	  *	as they come in.
	  */

	for(i = 0; i < MAX_FDS; i++)
		connected_fds[i] = -1;

	if(-1 == (s = socket(AF_INET, SOCK_STREAM, 0)))
	  {
		perror("ccd_daemon: socket creation");
		cleanexit(BAD_STATUS);
	  }
	server_s = s;

        /*
         *      Set the KEEPALIVE and RESUSEADDR socket options.
         */

        optname = SO_KEEPALIVE;
        optval = 1;
        optlen = sizeof (int);

        if(-1 == setsockopt(server_s,SOL_SOCKET,optname,&optval,optlen))
          {
            fprintf(stderr,"ccd_dc: cannot set SO_KEEPALIVE socket option.\n");
            perror("ccd_dc: setting SO_KEEPALIVE");
            cleanexit(0);
          }

        optname = SO_REUSEADDR;
        optval = 1;
        optlen = sizeof (int);

        if(-1 == setsockopt(server_s,SOL_SOCKET,optname,&optval,optlen))
          {
            fprintf(stderr,"ccd_dc: cannot set SO_REUSEADDR socket option.\n");
            perror("ccd_dc: setting SO_REUSEADDR");
            cleanexit(0);
          }

	from.sin_family = AF_INET;
	from.sin_addr.s_addr = htonl(INADDR_ANY);
	from.sin_port = htons(daserver.sl_port);

	if(bind(s, (struct sockaddr *) &from,sizeof from))
	  {
	    perror("ccd_daemon: error binding socket");
	    cleanexit(0);
	  }
	
	/*
	 *	Make sure any children of this process do NOT inherit
	 *	this socket.  This will avoid a multitude of problems
	 *	associated with having a child which has not exited
	 *	preventing ccd_daemon from starting fresh.
	 */
	
	if(-1 == fcntl(s,F_SETFD,FD_CLOEXEC))
	  {
	    perror("ccd_daemon: setting FD_CLOEXEC on primary socket");
	    cleanexit(0);
	  }
	listen(s,5);

	timeout.tv_sec = 0;
	timeout.tv_usec = 0;

	for(;;)
	  {
	    /*
	     *	Perform a select on the listener socket + any possible connections.
	     */
	    FD_ZERO(&readmask);
	    FD_SET(s,&readmask);
	    for(i = 0; i < MAX_FDS; i++)
	      if(connected_fds[i] != -1)
		FD_SET(connected_fds[i],&readmask);
	    nb = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
	    if(nb == -1)
	      {
		if(errno == EINTR)	/* if we get interrupted, is OK */
		  {
			sleep(1);
			continue;
		  }
		perror("ccd_daemon: select error");
		cleanexit(BAD_STATUS);
	      }
	    if(nb == 0)
	      {
		sleep(1);
		continue;	/* timed out */
	      }
	    
	    /*
	     *	There is something to do.  If the listener socket is ready for read,
	     *	perform an accept on it.  If one of the others is ready to read, get
	     *	the data and output it to the screen.
	     */
	    if(FD_ISSET(s,&readmask))
	      {
		len = sizeof from;
		g = accept(s, (struct sockaddr *) &from, &len);

		/*
		 *	The conditions of an error here are not well understood.
		 *	We seem to have gotten an error once which was not one of
		 *	the errors that the accept man page says it can return.
		 *	Print out the error number and just continue for the time being.
		 */
		if(g < 0)
		  {
		    if(errno != EINTR)
		      {
			perror("ccd_daemon: accept");
			fprintf(stderr,"ccd_daemon: The errno value for this error is: %d\n",errno);
			fprintf(stderr,"ccd_daemon: Ignoring this error until it is better understood.\n");
			continue;
		      }
		    continue;
		  }
		for(i = 0, j = -1; i < MAX_FDS; i++)
		  if(connected_fds[i] == -1)
		    {
			connected_fds[i] = g;
			j = 0;
			break;
		    }
		if(j == -1)
		  {
		    fprintf(stderr,"ccd_daemon: all %d connection slots used up.\n",MAX_FDS);
		    cleanexit(0);
		  }
	      }
	    for(i = 0; i < MAX_FDS; i++)
	      if(connected_fds[i] != -1)
		{
		  if(FD_ISSET(connected_fds[i],&readmask))
		    {
		      service_request(CCD_COM_TCPIP,connected_fds[i],buf);
		      if(shutdown_req)
			{
			  while(1)
				pause();
			}
		      close(connected_fds[i]);
		      connected_fds[i] = -1;
		    }
		}
	  }
	cleanexit(GOOD_STATUS);
  }

cleanexit(status)
int	status;
  {
	shutdown(server_s,2);
	exit(status);
  }